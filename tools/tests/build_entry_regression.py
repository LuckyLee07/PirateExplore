#!/usr/bin/env python3
"""Exercise the real wrapper using disposable project/toolchain stubs.

This verifies preflight and argument dispatch, not an Apple application build.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="pirate build entry ") as temp:
    work = Path(temp)
    script = work / "xcode.sh"
    shutil.copy2(root / "xcode.sh", script)

    def run(action, env=None):
        return subprocess.run(["/bin/bash", str(script), action], env=env,
                              capture_output=True, text=True)

    assert run("--help").returncode == 0
    assert run("invalid-action").returncode == 1
    missing = run("mac")
    assert missing.returncode == 2 and "project is missing" in missing.stderr
    project = work / "projects/ios_mac/NewPirate.xcodeproj"
    project.mkdir(parents=True)
    (project / "project.pbxproj").write_text("// test fixture only\n")
    bin_dir = work / "stub tools"
    bin_dir.mkdir()

    def tool(name, body):
        path = bin_dir / name
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    env = dict(os.environ, PATH=str(bin_dir) + ":/usr/bin:/bin")
    tool("uname", "printf 'Linux\\n'\n")
    unsupported = run("ios-sim", env)
    assert unsupported.returncode == 2 and "require macOS" in unsupported.stderr
    tool("uname", "printf 'Darwin\\n'\n")
    trace = work / "tool arguments.txt"
    env["BUILD_ENTRY_TRACE"] = str(trace)
    body = 'printf "%s\\n" "$@" > "$BUILD_ENTRY_TRACE"\n'
    tool("xcodebuild", body)
    tool("open", body)
    for action, scheme in (("mac", "NewPirate Mac"),
                           ("ios-sim", "NewPirate iOS"),
                           ("ios-device", "NewPirate iOS")):
        result = run(action, env)
        assert result.returncode == 0, result.stderr
        args = trace.read_text().splitlines()
        assert args[args.index("-project") + 1] == str(project)
        assert args[args.index("-scheme") + 1] == scheme
        if action != "mac":
            assert "CODE_SIGNING_ALLOWED=NO" in args
    assert run("open", env).returncode == 0
    assert trace.read_text().splitlines() == [str(project)]

header = (root / "bin/res/scripts/LuaClass/Header.lua").read_text()
assert "zqDebugMenuEnabled = false" in header
print("PASS real Apple wrapper preflight/dispatch with stub toolchain; destructive menu default is disabled (no Apple build claimed)")
