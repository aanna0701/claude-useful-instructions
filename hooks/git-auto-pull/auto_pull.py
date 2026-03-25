#!/usr/bin/env python3
"""Claude Code PreToolUse hook — auto git pull on first Edit/Write.

Runs `git pull --ff-only` once per session when the first file-modifying
tool is invoked. Skips if already pulled, not a git repo, or pull fails.

State file: /tmp/.claude-auto-pull-{session_pid}
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def _session_marker() -> Path:
    """One pull per terminal session (keyed on parent PID)."""
    ppid = os.getppid()
    return Path(f"/tmp/.claude-auto-pull-{ppid}")


def _is_git_repo() -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--is-inside-work-tree"],
        capture_output=True, text=True,
    )
    return result.returncode == 0


def _current_branch() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True,
    )
    return result.stdout.strip()


def _has_remote_tracking() -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "@{u}"],
        capture_output=True, text=True,
    )
    return result.returncode == 0


def _pull() -> tuple[bool, str]:
    """Run git pull --ff-only. Returns (success, message)."""
    result = subprocess.run(
        ["git", "pull", "--ff-only"],
        capture_output=True, text=True,
        timeout=30,
    )
    if result.returncode == 0:
        output = result.stdout.strip()
        if "Already up to date" in output:
            return True, "already up to date"
        return True, output.split("\n")[-1]
    return False, result.stderr.strip().split("\n")[0]


def main() -> None:
    marker = _session_marker()

    # Already pulled this session
    if marker.exists():
        return

    if not _is_git_repo():
        return

    if not _has_remote_tracking():
        marker.touch()
        return

    branch = _current_branch()
    ok, msg = _pull()

    marker.touch()

    if ok:
        if "already up to date" not in msg.lower():
            # Inform Claude about the pull
            result = {"message": f"Auto-pulled {branch}: {msg}"}
            print(json.dumps(result), file=sys.stderr)
    else:
        result = {"message": f"Auto-pull failed on {branch}: {msg}. Run `git pull` manually."}
        print(json.dumps(result), file=sys.stderr)


if __name__ == "__main__":
    main()
