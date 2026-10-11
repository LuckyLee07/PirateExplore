# Native HTTP shutdown regression coverage

The pause-sheet node teardown repair and the HTTP process-exit repair address
separate failures. A sheet can finish native `onExit` correctly while a detached
HTTP worker still prevents the process from exiting.

The pre-fix HTTP worker slept on a static condition variable. Desktop shutdown
forensics found the main thread waiting at the condition variable's destruction
address while the remaining HTTP thread waited on the same condition variable.
The independent empty-URL probe reproduced a hang after `main` returned without
opening a window or using audio. This isolates the HTTP lifetime problem from
pause appearance, checkpoint storage, and FMOD.

The repaired Linux lifecycle stops `HttpClient` at the start of
`Director::purgeDirector`, before scheduler and scene teardown. HTTP destruction
invalidates queued dispatches, signals a mutex-protected quit predicate, cancels
a transfer in progress, joins the worker, and releases pending/completed request
ownership on the Cocos thread. A general process-exit finalizer is deliberately
not the supported teardown path: shutdown must occur while the scheduler and
callback targets are still valid.

## Running the test

Use a fully rebuilt Linux Makefiles build of this checkout and the runtime
environment used by `linux.sh`:

```sh
source ../linux-runtime/env.sh
./linux.sh build
python3 tools/tests/coherent_http_shutdown_regression.py \
  --repeat 3 --report build/linux/tests/coherent-http-shutdown-results.json
```

The runtime location above is the isolated validation workspace's layout; use
your actual dependency environment elsewhere. `PIRATE_BUILD_DIR` or
`--build-dir` selects another existing build. `--case NAME` is repeatable;
`--no-build` reuses the previously linked test executable. Rebuild the harness
without `--no-build` after changing engine libraries.

The Python runner compiles `coherent_http_shutdown_native.cpp` with the native
build's include/define/link metadata, preserving assertions even when the game
build uses `NDEBUG`. It starts a loopback HTTP fixture on an ephemeral port. It
clears proxy variables, isolates `HOME`/`XDG_CONFIG_HOME` in a temporary directory,
uses software surfaceless EGL for pause cases, and disables core dumps. No
remote website, shared desktop, audio playback, or player save is used.

Every scenario runs in a separate subprocess. A printed assertion marker is
insufficient: the runner also requires exit code 0 within 20 seconds. The
cancellation/Director call itself must return in less than 4 seconds. The
fixture's stalled endpoint sends no response headers or body; the client waits
until the server confirms it actually received the request before destroying
the client. Queued requests must never reach the server.

## Cases

- `application-launch-stop`: the native `Application::run` early-launch-stop
  path retains its historical return value 0. A separate source contract check
  verifies the normal-loop final return is 0; it does not substitute for a
  desktop close test.
- `no-request`: destruction before initialization, initialization without any
  request, ordinary destruction, and repeated destruction.
- `idle-malformed`: a completed empty-URL request receives exactly one failure
  callback on the main thread, releases its request, and leaves the worker idle
  before destruction.
- `success`: real local GET, POST, PUT, and DELETE requests preserve method,
  request body/header, response body/header/status, request tag/user data,
  correct client pointer, and once-only main-thread callback delivery.
- `immediate-cancel`: 64 immediate send/destroy cycles exercise startup/quit
  ordering without waiting for worker startup. All requests are released and no
  canceled callback is delivered.
- `cancel-inflight-queued`: a real stalled local request with a 60-second read
  timeout plus four queued requests is canceled within the shutdown bound.
- `cancel-unlimited`: the same stalled/queued setup with read timeout 0 confirms
  shutdown does not depend on a finite request timeout.
- `cancel-connect`: saturate a loopback TCP listen backlog without accepting
  connections, verify the HTTP socket is actually `SYN_SENT` via `/proc/net/tcp`,
  then cancel it with a 60-second connect timeout and unlimited read timeout.
  Four queued requests remain unsent. No external host or DNS request is used.
- `recreate-stale`: 12 cycles take an actual published dispatch from the native
  scheduler under its own mutex, destroy its client, create a new client and
  response, then replay the stale dispatch. It must neither invoke old user
  code nor steal/deliver the new client's response. The new response is still
  delivered exactly once by its own dispatch.
- `destroy-in-callback`: destruction from within a response callback must
  return safely; a newly created client must subsequently work normally.
- `pause-idle`: reuse the existing production-style pause/dialog/settings Lua
  fixture, leave all five unretained sheets open, complete an HTTP request, and
  close via actual `Director::end`/`mainLoop`/`purgeDirector`.
- `pause-stalled`: the same open-sheet Director path with one confirmed stalled
  HTTP request and four queued requests. No direct test-side HTTP destruction
  substitutes for the production shutdown hook.

All tracked request destructors must run on the main thread. Pending and
completed request release counts are checked before destruction returns.
The pause fixture additionally verifies five native descendant exit events,
checkpoint doubles, cargo/pending-outcome preservation, and harmless stale UI
controls. Its source is reused without changing it.

## Scope and evidence limits

These are real native HTTP/Cocos lifecycle tests, not mocked network-client or
UI tests. They establish the subprocess exit status and the tested cancellation,
callback, and reference-ownership behavior. They do not establish full-game
window-manager X/reopen behavior, all platforms, all DNS resolver backends,
remote TLS/cookie behavior, or preservation of a real player's save. Those
require separate targeted validation. Normal return without an explicit
`HttpClient` shutdown or the production Director shutdown path is intentionally
outside this suite's contract.

The machine-readable report records each command's scenario, iteration, exit
code, duration, local requests, and captured output. Build warnings and full
logs should be retained separately when recording a validation run.

## Recorded validation: 2026-10-11

With the rebuilt Linux libraries and libcurl 8.14.1 (`ASYNCHDNS=true`), this
command passed all 36 subprocesses (12 scenarios × 3), every one with exit 0:

```sh
source ../linux-runtime/env.sh
python3 tools/tests/coherent_http_shutdown_regression.py \
  --repeat 3 --report build/linux/tests/coherent-http-shutdown-results.json
```

The final measured shutdown calls took 0.104–0.108 seconds for a stalled
response, 0.108–0.114 seconds with an unlimited read timeout, 0.109–0.112 seconds
for an actual pending TCP connect, and 0.110–0.111 seconds for the stalled HTTP
request with all five modal sheets open during Director shutdown.

The 192 immediate send/destroy cycles, 36 stale-dispatch destroy/recreate cycles,
and three destroy-inside-callback runs passed. The source return-contract check
and three native early-launch-stop runs also passed. No queue cancellation sent
a queued request, and all tracked request destructors ran on the main thread.
Measured shutdown calls returned in 0.104–0.112 seconds for the 60-second
stalled request, 0.108–0.112 seconds with unlimited read timeout, and
0.111–0.114 seconds through Director teardown with the pause sheet open. The
fixture uses loopback; this does not measure remote DNS/TLS cancellation or
other operating systems. The shipped executable resolves `libcurl.so.4` to
`/lib/x86_64-linux-gnu/libcurl.so.4`; `curl_version_info` explicitly confirmed
`CURL_VERSION_ASYNCHDNS`. A different build using synchronous DNS could block
inside libcurl despite the poll interval; no hard shutdown-bound claim is made
for that backend without additional validation.

The complete `run-coherent-game-tests.sh` aggregate also passed in the rebuilt
worktree, including Warm/native presentation, gameplay invariants, legacy
opt-out, clean-map and font checks. Resource files remain unchanged from the
frozen `685b6a3` baseline. Linux `Application::run` changes only its successful
normal-close final return from -1 to 0; all earlier startup/error returns remain
unchanged.

Separate desktop review of executable SHA-256
`94e23933d1ccea5cb754eefb756360dfa32104fe36a7af4db38208c4536303d1`
reported a native X close with the resume/pause sheet open returning exit 0
without Ctrl+C, a native assertion, or a Lua error. The test author checked the
captured exit-code artifact (`0`) and native log, while the reviewer performed
the actual desktop interaction. This is separate evidence from the headless
suite. The reviewer had reopened voyage 3 at map 1, position (7,10), with 29 food
and 29 cargo before that close. A further reopen restored the exact checkpoint. Independent Home-owned settings
and preparation-owned common dialog X-close paths also returned exit 0; the
old-save chapter-6 disposable copy loaded, moved, saved and exited successfully.

The desktop log contains pre-existing audio-device/FMOD initialization warnings;
it is not a claim of a warning-free audio environment. FMOD has a static
`FmodAudioPlayer` destructor. The measured HTTP futex addresses and independent
no-audio reproducer isolate the observed hang without assuming FMOD lacks
shutdown code.

## Bundled curl API compatibility follow-up

Independent source review rejected the first stability commit because Android,
iOS and Win32 bundle curl 7.26 headers, which do not declare the new transfer
progress callback or `curl_multi_wait`. The guarded follow-up uses
`CURLOPT_PROGRESSFUNCTION` with its original double-valued callback below
7.32, and a cancel-aware 100 ms sleep/poll between `curl_multi_perform` calls
below 7.28. The modern Linux code path is unchanged. WP8's bundled 7.34 headers
continue to use both modern APIs.

`coherent_curl_headers_regression.py` syntax-checks the complete HttpClient.cpp
translation unit against each of the four bundled curl header trees using the
host compiler. For Android's 32-bit curlbuild configuration only sizeof(long)
is aligned to the host ABI in a temporary preinclude; API declarations are not
modified. Counterfactual probes verify both unsupported calls fail under each
7.26 header tree and succeed under WP8's 7.34 headers. This is an API/header
compatibility regression, not a mobile/Windows build or runtime acceptance.
The full aggregate now includes this check and the HTTP lifecycle suite.
