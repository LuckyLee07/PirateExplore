# Bounded local production

## Behavior and migration

The previous offline grant depended on an empty HTTP time endpoint. The local
production ledger now drives both ordinary cycles and elapsed time while the
application is stopped. It is separate from server daily rewards and the game
clock used by voyages.

- `localProductionV1` is stored inside the existing `gameRole` snapshot. It records
  a local wall timestamp and the remaining seconds to the next production cycle.
- First use of a legacy save establishes an anchor and grants no unverifiable
  historical production. A plausible in-progress cycle is retained.
- Elapsed time is bounded by the saved `roleOfflineBonusTime`: the default hour
  and all shipped purchased 2/4/6/8/10/12-hour tiers remain effective. A corrupt
  duration is capped at the highest shipped entitlement, 43,200 seconds.
- The existing production period, assigned workers, worker queue order, input
  costs, and output recipes are reused. Whole cycles run chronologically, so
  resource chains behave like ordinary play. Materials and coins cannot be spent
  below zero. Partial cycles carry forward without being granted twice.
- Backwards/future/corrupt local anchors are safely re-established without reward.
  Huge forward clock jumps receive at most the player's allowed duration.
- Cold start and foreground resume checkpoint the phase. Normal updates save at
  production boundaries. Repeated cold starts at the same timestamp do not grant
  again, and no offline elapsed time is added to the voyage clock.
- Real server-time requests and their separate SevenDay callback remain intact.
  The old callback no longer produces resources, preventing a second grant.

This is local single-player elapsed time, not server-verified anti-cheat. A player
who deliberately changes clocks or edits saves can circumvent local assumptions.
There are no new multipliers, sign-in rewards, purchases, or network endpoints.

## Persistence

The candidate inventory, money, next-cycle timestamp, and ledger are serialized
as one snapshot before the live UserData proxy changes. Failed persistence
publishes no candidate state, events, unlocks, or production text. The next update
can retry. Successful commits retain normal resource-triggered talent checks.

`Record::saveDataAtomic` retains the original LZSS/XOR serialization and filename.
It writes a same-directory temporary file, verifies write/flush/close, flushes the
file, and atomically replaces the target. Failure preserves the original target
and removes the temporary file when possible. Legacy void `saveData` callers
keep their ABI and delegate to the same safe writer. The in-memory Record cache
is invalidated only after success. POSIX uses `rename`; Windows uses
`MoveFileExA(REPLACE_EXISTING | WRITE_THROUGH)` instead of deleting the target.
The Windows path representation matches the old ANSI `fopen` path; no new
Unicode or long-path support is claimed.

ASAN exposed two pre-existing memory defects while testing this boundary: an
LZSS output buffer allocated at input length (one byte can encode to two), and
four arrays freed using scalar delete. The buffer now accommodates the worst
case of one flag byte per eight literal bytes, with arithmetic overflow guarded;
the four releases use `delete[]`. Compression and encryption algorithms are
unchanged. Baseline and current encoders generate identical bytes for the
synthetic gameRole fixture and read each other's files.

The guarantee is a complete old or complete new snapshot across process
interruption. POSIX directory metadata is not fsynced, so sudden power-loss
persistence is not claimed. Windows/Apple behavior has not been device-tested.

## Reproducible tests

All tests use explicit synthetic recipes/time fixtures or fresh temporary
profiles. They never open the natural gameplay profile or modify an original
save. The fixed-clock 60-second test is not the separate GUI real-time test.

```sh
LUA_BIN=/path/to/lua5.1
$LUA_BIN tools/tests/local_production_regression.lua
$LUA_BIN tools/tests/local_production_integration.lua
python3 tools/tests/run_atomic_save_regression.py
PIRATE_RUNTIME=/path/to/linux-sdk \
  PIRATE_NATIVE_ASAN=1 ASAN_OPTIONS=detect_leaks=0 \
  python3 tools/tests/run_record_atomic_native.py
```

The native Record test requires existing Linux CMake engine libraries and the
repository's `2cad23c` baseline history. It recompiles only its isolated temporary
test binary, current Record/LZSS/binding, and a renamed baseline Record. No game
scene, display, or running application executable is used. Leak detection is
excluded because the legacy engine has process-lifetime globals; ASAN memory
access and allocation/deallocation checks remain enabled.

Verified at source handoff:

- Pure fixtures: first migration, 60 seconds, fractional phase, cold-start
  idempotence, every purchased cap, corrupt duration, huge jump, rollback, scarce
  multi-input recipes, and coin-dependent chains.
- Actual NotificationNode/UserData proxy/JSON/SaveDataManager with mocked Record:
  failed migration and reward, successful retry once, four cold JSON reloads,
  online boundary overlap, talent checks, partial resume, duplicate server
  callbacks, and repeated foreground notifications.
- Native atomic writer: success, existing-target replacement, failed temp open,
  full-device write/flush failure, failed rename, stale temporary file and retry.
- Actual native Record + Lua binding under ASAN: encode/decode, preserved bytes
  on failure, cold reads, one-byte input, legacy void API, baseline byte identity,
  and old/new bidirectional compatibility. Independently rerun by the reviewer.
- Existing aggregate source suite passed at this stage (240 PASS lines before
  the separate integration test was added to the parent-owned aggregate runner).

Four existing archived gameRole fixtures were hashed before/after the tests and
remained unchanged. The active natural play profile was not opened by this work.
Full application rebuild and natural real-time 60-second close/reopen acceptance
belong to the separately owned GUI validation; they are not claimed here.
