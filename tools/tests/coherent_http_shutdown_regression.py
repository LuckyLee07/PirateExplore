#!/usr/bin/env python3
"""Build and run native HTTP lifecycle cases using a loopback-only HTTP server.

An assertion marker is not a clean exit: every subprocess must also return zero
within the deadline. Runtime dependencies and build flags come from linux.sh.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import resource
import re
import shlex
import subprocess
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CASES = [
    'application-launch-stop', 'no-request', 'idle-malformed', 'success', 'immediate-cancel', 'cancel-inflight-queued',
    'cancel-unlimited', 'cancel-connect', 'recreate-stale', 'destroy-in-callback', 'pause-idle', 'pause-stalled',
]


def check_application_return_contract() -> None:
    source = (ROOT / 'src/engine/cocos2d-x/cocos/2d/platform/linux/CCApplication.cpp').read_text()
    run = source.split('int Application::run()', 1)[1].split('void Application::setAnimationInterval', 1)[0]
    assert re.search(r'if\s*\(\s*!\s*applicationDidFinishLaunching\(\)\s*\)\s*\{\s*return 0;', run), \
        'Preserve the existing early-launch return value.'
    assert re.search(r'glview->release\(\);\s*return 0;\s*\}', run), \
        'Normal Linux application-loop completion must return success.'
    print('PASS source contract: Linux Application::run normal return 0, early-launch return unchanged', flush=True)


def build_harness(build: Path, env: dict[str, str]) -> Path:
    meta = build / 'CMakeFiles/PirateExplore.dir'
    if not (meta / 'link.txt').is_file():
        raise RuntimeError('Build linux.sh with Unix Makefiles first: ' + str(build))
    flags = {}
    for line in (meta / 'flags.make').read_text().splitlines():
        if ' = ' in line:
            key, value = line.split(' = ', 1)
            flags[key] = shlex.split(value)
    link = shlex.split((meta / 'link.txt').read_text())
    output = build / 'tests/coherent-http-shutdown-native'
    output.parent.mkdir(parents=True, exist_ok=True)
    obj = output.with_suffix('.o')
    extra = ['-I' + env['PIRATE_RUNTIME'] + '/usr/include'] if env.get('PIRATE_RUNTIME') else []
    subprocess.run([link[0], *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'], *extra,
                    '-std=c++11', '-g', '-UNDEBUG', '-c',
                    str(ROOT / 'tools/tests/coherent_http_shutdown_native.cpp'), '-o', str(obj)],
                   env=env, check=True)
    args = []
    skip = False
    for token in link[1:]:
        if skip:
            skip = False
            continue
        if token == '-o':
            skip = True
        elif not (token.endswith('.o') or token.startswith('-Wl,--dependency-file=')):
            args.append(token)
    subprocess.run([link[0], str(obj), *args, '-lEGL', '-o', str(output)],
                   cwd=build, env=env, check=True)
    return output


@contextmanager
def local_fixture(directory: Path):
    stop = threading.Event()
    requests = []
    lock = threading.Lock()

    class Handler(BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def log_message(self, *_args):
            pass

        def serve(self):
            length = int(self.headers.get('Content-Length', '0'))
            body = self.rfile.read(length)
            with lock:
                requests.append({'method': self.command, 'path': self.path,
                                 'body': body.decode(),
                                 'header': self.headers.get('X-Coherent-Request')})
            if self.path.startswith('/stall/'):
                # Signal only after receiving a real HTTP request. Send no
                # headers/body: curl must cancel without its 60-second timeout.
                identifier = self.path.rsplit('/', 1)[1]
                (directory / identifier).write_text('accepted\n')
                stop.wait(30)
                self.close_connection = True
                return
            response = self.command.encode() + b':' + body
            self.send_response(200)
            self.send_header('Content-Length', str(len(response)))
            self.send_header('X-Coherent-Fixture', 'local')
            self.send_header('Connection', 'close')
            self.end_headers()
            self.wfile.write(response)
            self.close_connection = True

        do_GET = do_POST = do_PUT = do_DELETE = serve

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    server.daemon_threads = True
    server.block_on_close = False
    thread = threading.Thread(target=server.serve_forever, kwargs={'poll_interval': 0.05}, daemon=True)
    thread.start()
    try:
        yield 'http://127.0.0.1:' + str(server.server_port), requests
    finally:
        stop.set()
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path,
                        default=Path(os.environ.get('PIRATE_BUILD_DIR', ROOT / 'build/linux')))
    parser.add_argument('--case', action='append', choices=DEFAULT_CASES,
                        help='Run selected scenario(s), otherwise the complete default suite.')
    parser.add_argument('--no-build', action='store_true', help='Use an already built harness.')
    parser.add_argument('--repeat', type=int, default=1)
    parser.add_argument('--report', type=Path, help='Save observed results as JSON.')
    options = parser.parse_args()
    if options.repeat < 1:
        parser.error('--repeat must be positive')
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    check_application_return_contract()
    build = options.build_dir.resolve()
    env = os.environ.copy()
    # Even accidental GLFW initialization must not connect to the shared desktop.
    env.pop('DISPLAY', None)
    env.pop('WAYLAND_DISPLAY', None)
    env['MESA_SHADER_CACHE_DISABLE'] = 'true'
    env['LIBGL_ALWAYS_SOFTWARE'] = '1'
    # Loopback requests must never traverse a configured external proxy.
    env['NO_PROXY'] = env['no_proxy'] = '127.0.0.1,localhost'
    for key in ('http_proxy', 'https_proxy', 'all_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'):
        env.pop(key, None)
    for key in ('COHERENT_PAUSE_SOURCE', 'COHERENT_PAUSE_DIALOG_SOURCE', 'COHERENT_PAUSE_SETTINGS_SOURCE'):
        env.pop(key, None)
    if env.get('PIRATE_RUNTIME'):
        for key in ('LD_LIBRARY_PATH', 'LIBRARY_PATH'):
            env[key] = env['PIRATE_RUNTIME'] + '/usr/lib/x86_64-linux-gnu:' + env.get(key, '')
    binary = build / 'tests/coherent-http-shutdown-native'
    if not options.no_build:
        binary = build_harness(build, env)
    report = []
    failed = False
    for iteration in range(1, options.repeat + 1):
        for case in options.case or DEFAULT_CASES:
            with tempfile.TemporaryDirectory(prefix='coherent-http-shutdown-') as temporary:
                directory = Path(temporary)
                isolated_env = dict(env, XDG_CONFIG_HOME=str(directory / 'config'), HOME=str(directory))
                with local_fixture(directory) as (base, requests):
                    command = [str(binary), case, base, str(directory),
                               str(ROOT / 'tools/tests/coherent_pause_close_native.lua')]
                    start = time.monotonic()
                    try:
                        result = subprocess.run(command, cwd=ROOT, env=isolated_env, text=True,
                                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                                timeout=20)
                        output, code = result.stdout, result.returncode
                        marker = 'PASS native HTTP shutdown assertions: ' + case
                        passed = code == 0 and marker in output and 'LUA ERROR' not in output and 'ASSERT FAILED' not in output
                        reason = '' if passed else 'missing assertion marker, native assertion/error, or nonzero exit'
                    except subprocess.TimeoutExpired as error:
                        output = error.stdout or ''
                        if isinstance(output, bytes):
                            output = output.decode(errors='replace')
                        code, passed, reason = None, False, 'process did not exit within 20 seconds'
                    duration = time.monotonic() - start
                    if any(item['path'].startswith('/must-not-start/') for item in requests):
                        passed, reason = False, 'queued request was transmitted during shutdown'
                    if any(item['header'] != 'local' for item in requests):
                        passed, reason = False, 'request header was not preserved'
                    if case == 'success':
                        expected = [('GET', ''), ('POST', 'payload-1'), ('PUT', 'payload-2'), ('DELETE', '')]
                        if [(item['method'], item['body']) for item in requests] != expected:
                            passed, reason = False, 'HTTP verbs/body order changed'
                    print(output, end='')
                    status = 'PASS' if passed else 'FAIL'
                    print(f'{status} process exit: {case} (iteration {iteration}, exit={code}, {duration:.3f}s)' +
                          (': ' + reason if reason else ''), flush=True)
                    report.append({'case': case, 'iteration': iteration, 'passed': passed,
                                   'exit_code': code, 'seconds': round(duration, 3),
                                   'reason': reason, 'requests': requests, 'output': output})
                    failed |= not passed
    if options.report:
        options.report.parent.mkdir(parents=True, exist_ok=True)
        options.report.write_text(json.dumps(report, indent=2) + '\n')
    print(f'{sum(item["passed"] for item in report)}/{len(report)} native HTTP subprocess cases passed')
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
