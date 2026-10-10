-- Pure, read-only four-neighbour navigation. Unknown and event cells are never
-- transit shortcuts. Coordinates use TMX convention: y increases southward.
local K = {}
function K.key(p, width) return tostring(p.x + p.y * width) end
function K.inBounds(p, width, height)
    return type(p)=='table' and type(p.x)=='number' and type(p.y)=='number'
        and p.x==math.floor(p.x) and p.y==math.floor(p.y)
        and p.x>=0 and p.y>=0 and p.x<width and p.y<height
end
function K.direction(a,b)
    if not a or not b then return nil end
    local dx,dy=b.x-a.x,b.y-a.y
    if dx==0 and dy==0 then return '此处' end
    return (dx<0 and '西' or dx>0 and '东' or '') .. (dy<0 and '北' or dy>0 and '南' or '')
end
-- Mirrors costbread's one-debit-per-call arithmetic with food available.
-- This is a navigation-only lower bound, never a promise of safe arrival.
function K.foodCost(calls, coefficient, decimal)
    coefficient=tonumber(coefficient) or 0
    decimal=tonumber(decimal) or 0
    local spent=0
    local delta=1-coefficient
    for _=1,calls do
        decimal=decimal+delta
        if decimal>=1 then spent=spent+1;decimal=decimal-1 end
    end
    return spent,decimal
end
function K.find(graph, start, goal, options)
    options=options or {}
    local w,h=graph.width,graph.height
    if not K.inBounds(start,w,h) or not K.inBounds(goal,w,h) then return {status='out_of_bounds'} end
    local sk,gk=K.key(start,w),K.key(goal,w)
    local function allowed(p, endpoint)
        local c=graph.cells[K.key(p,w)]
        return c and c.known==true and not c.blocked and (not c.event or endpoint)
    end
    if not allowed(start,true) or not allowed(goal,true) then return {status='no_known_route'} end
    if sk==gk then return {status='at_port',path={{x=start.x,y=start.y}},steps=0,minimumFood=0,costCalls=0} end
    local queue,head={{x=start.x,y=start.y}},1
    local seen={[sk]=true};local parent={};local nodes={[sk]=queue[1]}
    local dirs={{0,-1},{-1,0},{1,0},{0,1}}
    while head<=#queue and not seen[gk] do
        local p=queue[head];head=head+1
        for _,d in ipairs(dirs) do
            local n={x=p.x+d[1],y=p.y+d[2]}
            if K.inBounds(n,w,h) then
                local nk=K.key(n,w)
                if not seen[nk] and allowed(n,nk==gk) then
                    seen[nk]=true;parent[nk]=K.key(p,w);nodes[nk]=n;queue[#queue+1]=n
                end
            end
        end
    end
    if not seen[gk] then return {status='no_known_route'} end
    local reverse={};local key=gk
    while key do reverse[#reverse+1]=nodes[key];key=parent[key] end
    local path={};local calls=0
    for i=#reverse,1,-1 do
        local p=reverse[i];path[#path+1]={x=p.x,y=p.y}
        if i<#reverse and graph.cells[K.key(p,w)].costed~=false then calls=calls+1 end
    end
    local food=K.foodCost(calls,options.breadCoefficient,options.breadCostDecimal)
    return {status='ok',path=path,nextStep=path[2],direction=K.direction(start,path[2]),
        steps=#path-1,costCalls=calls,minimumFood=food,
        foodShortfall=math.max(0,food-(tonumber(options.food) or food))}
end
return K
