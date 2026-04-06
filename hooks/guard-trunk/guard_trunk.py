#!/usr/bin/env python3
"""Claude Code PreToolUse hook — redirect code edits on trunk to a tmp worktree.

Reads .claude/branch-map.yaml to determine trunk_chain branches.
On those branches, orchestration files (work/, docs/, .claude/, etc.) are
allowed directly. Source code edits are blocked with a message instructing
Claude to use an auto-created temporary worktree instead.

One worktree per session (keyed on parent PID). Worktree is created on
first code-edit attempt and reused for the rest of the session.

Exit codes:
  0 — allow
  2 — block with redirect message (stderr)
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Orchestration paths allowed directly on trunk branches
ALLOWED_PREFIXES = (
    "work/",
    "docs/",
    ".claude/",
    ".github/",
    "CLAUDE.md",
    "AGENTS.md",
    "README.md",
    "pyproject.toml",
    "uv.lock",
)


def _git_info_for(directory: Path) -> tuple[Path | None, str]:
    """Return (git_root, branch) for the given directory."""
    if not directory.exists():
        directory = directory.parent
    while not directory.exists() and directory != directory.parent:
        directory = directory.parent

    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True, cwd=str(directory),
    )
    if result.returncode != 0:
        return None, ""
    lines = result.stdout.strip().splitlines()
    return Path(lines[0]), lines[1] if len(lines) > 1 else ""


def _parse_trunk_chain(root: Path) -> list[str]:
    """Parse trunk_chain from branch-map.yaml without PyYAML."""
    bmap = root / ".claude" / "branch-map.yaml"
    if not bmap.exists():
        return []
    chains: list[str] = []
    in_trunk = False
    for line in bmap.read_text().splitlines():
        if line.strip().startswith("trunk_chain:"):
            in_trunk = True
            continue
        if in_trunk:
            m = re.match(r"^\s+-\s+(.+)$", line)
            if m:
                chains.append(m.group(1).strip())
            else:
                break
    return chains


def _is_orchestration_file(rel_path: str) -> bool:
    for prefix in ALLOWED_PREFIXES:
        if rel_path.startswith(prefix) or rel_path == prefix.rstrip("/"):
            return True
    return False


def _session_marker() -> Path:
    return Path(f"/tmp/.claude-guard-trunk-{os.getppid()}")


def _ensure_worktree(main_root: Path, branch: str) -> Path:
    """Create or reuse a session-scoped tmp worktree. Returns worktree path."""
    marker = _session_marker()
    if marker.exists():
        lines = marker.read_text().strip().splitlines()
        wt_path = Path(lines[0])
        if wt_path.exists():
            return wt_path

    project = main_root.name
    ppid = os.getppid()
    stamp = datetime.now().strftime("%m%d-%H%M")
    wt_branch = f"tmp/guard-{ppid}-{stamp}"
    wt_dir = main_root.parent / f"{project}-tmp-guard-{ppid}"

    # If directory exists but isn't a worktree, remove it
    if wt_dir.exists():
        check = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            capture_output=True, text=True, cwd=str(main_root),
        )
        wt_str = str(wt_dir.resolve())
        if wt_str not in check.stdout:
            subprocess.run(["rm", "-rf", str(wt_dir)], capture_output=True)
        else:
            # Get branch name from existing worktree
            existing_branch = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True, text=True, cwd=str(wt_dir),
            )
            eb = existing_branch.stdout.strip() if existing_branch.returncode == 0 else wt_branch
            marker.write_text(f"{wt_dir}\n{eb}")
            return wt_dir

    subprocess.run(
        ["git", "worktree", "add", "-b", wt_branch, str(wt_dir), branch],
        capture_output=True, text=True, cwd=str(main_root),
        timeout=30,
    )

    marker.write_text(f"{wt_dir}\n{wt_branch}")
    return wt_dir


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return

    tool_input = payload.get("tool_input", {})
    file_path = tool_input.get("file_path")
    if not file_path:
        return

    abs_path = Path(file_path).resolve()

    # Determine git root and branch for the file's location
    file_dir = abs_path.parent if not abs_path.is_dir() else abs_path
    root, branch = _git_info_for(file_dir)
    if not root:
        return

    trunk_chain = _parse_trunk_chain(root)
    if not trunk_chain:
        return

    # Not on a trunk branch — allow
    if branch not in trunk_chain:
        return

    # Resolve relative path
    try:
        rel_path = str(abs_path.relative_to(root))
    except ValueError:
        return

    # Orchestration files are fine on trunk
    if _is_orchestration_file(rel_path):
        return

    # --- Trunk + code file → redirect to worktree ---
    wt_path = _ensure_worktree(root, branch)
    redirect_path = wt_path / rel_path

    msg = (
        f"REDIRECT: You are on trunk branch '{branch}'. "
        f"A temporary worktree has been created at:\n"
        f"  {wt_path}\n"
        f"Re-run your edit using the worktree path:\n"
        f"  {redirect_path}\n"
        f"When done, commit on the worktree branch and merge via PR."
    )
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
