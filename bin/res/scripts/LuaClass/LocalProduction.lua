-- Local-only production ledger. Does not change voyage time or daily rewards.
local Production = { KEY = "localProductionV1" }
local function finite(value)
    local n = tonumber(value)
    return n and n == n and n > -math.huge and n < math.huge and n or nil
end
local function positive(value, fallback)
    local n = finite(value)
    return n and n > 0 and n or fallback
end
local function copy(t)
    local result = {}
    for k, v in pairs(t or {}) do result[k] = v end
    return result
end

-- Pure calculation: callers publish all returned fields in one durable save.
function Production.calculate(input)
    local now = finite(input.now)
    if not now or now < 0 then return nil end
    local cd = math.max(1, positive(input.cd, 20))
    -- The highest shipped shop entitlement is 12 hours. Retain every purchased
    -- tier, but never loop unboundedly on a corrupt finite saved duration.
    local cap = math.min(43200, positive(input.cap, 3600))
    local ledger = input.ledger
    local wall = type(ledger) == "table" and finite(ledger.wall)
    local remaining = type(ledger) == "table" and finite(ledger.remaining)
    local result = {pack = copy(input.pack), money = positive(input.money, 0), delta = {}, cycles = 0}
    -- Old roleLastTime was a synthetic server counter, so migration never claims
    -- historical rewards. Preserve a plausible current online cycle only.
    if not wall or wall < 0 or not remaining or remaining <= 0 or remaining > cd or now < wall then
        local nextTime = finite(input.nextTime)
        remaining = nextTime and nextTime > input.gameTime and nextTime <= input.gameTime + cd
            and nextTime - input.gameTime or cd
        result.ledger = {wall = now, remaining = remaining}
        result.nextTime = input.gameTime + remaining
        result.checkpoint = true
        return result
    end
    local elapsed = math.min(now - wall, cap)
    local cycles = elapsed >= remaining and math.floor((elapsed - remaining) / cd) + 1 or 0
    local rest = cycles > 0 and remaining + cycles * cd - elapsed or remaining - elapsed
    result.ledger = {wall = now, remaining = rest}
    result.nextTime = input.gameTime + rest
    result.cycles = cycles
    result.checkpoint = cycles > 0 or now - wall > cap
    local function amount(id)
        if id == "1001" then return result.money end
        return tonumber(result.pack[id]) or 0
    end
    local function add(id, n)
        if id == "1001" then result.money = result.money + n
        else result.pack[id] = amount(id) + n end
        result.delta[id] = (result.delta[id] or 0) + n
    end
    -- A full chronological cycle at a time, in the same worker queue order as
    -- live play: later jobs may consume output from earlier jobs in this cycle.
    for cycle = 1, cycles do
        for _, worker in ipairs(input.workers or {}) do
            local recipe = (input.recipes or {})[worker[input.idKey]]
            local count = math.max(0, math.floor(finite(worker[input.numKey]) or 0))
            if recipe and recipe.resume and recipe.produce then
                local costs, outputs = {}, {}
                for _, part in ipairs(recipe.resume) do
                    local n = finite(part[2])
                    if n and n > 0 then costs[part[1]] = (costs[part[1]] or 0) + n end
                end
                for _, part in ipairs(recipe.produce) do
                    local n = finite(part[2])
                    if n and n > 0 then outputs[part[1]] = (outputs[part[1]] or 0) + n end
                end
                -- Real recipes never consume their own output. Batch those
                -- equivalent units; retain per-unit semantics for future loops.
                local selfConsuming = false
                for id in pairs(costs) do if outputs[id] then selfConsuming = true end end
                if not selfConsuming then
                    for id, n in pairs(costs) do count = math.min(count, math.max(0, math.floor(amount(id) / n))) end
                    for id, n in pairs(costs) do add(id, -n * count) end
                    for id, n in pairs(outputs) do add(id, n * count) end
                else
                    for unit = 1, count do
                        local possible = true
                        for id, n in pairs(costs) do if amount(id) < n then possible = false end end
                        if not possible then break end
                        for id, n in pairs(costs) do add(id, -n) end
                        for id, n in pairs(outputs) do add(id, n) end
                    end
                end
            end
        end
    end
    return result
end
return Production
