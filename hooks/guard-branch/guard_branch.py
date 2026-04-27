#!/usr/bin/env python3
"""Claude Code PreToolUse hook — redirect code edits to a worktree.

All code edits on the main repo are blocked and redirected to an
auto-created worktree. The worktree branches off the current branch
(no branch-map needed).

How it decides:
  - If cwd is already a worktree (.git is a file) → allow all edits
  - If cwd is the main repo → block code edits, redirect to worktree
  - Orchestration files (.work/, docs/, .claude/, etc.) are always allowed
  - Only activates for projects with .claude-worktree-enabled marker

One worktree per session (keyed on parent PID). Worktree is created on
first code-edit attempt and reused for the rest of the session.

Exit codes:
  0 — allow
  2 — block with redirect message (stderr)
"""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Add hooks/lib to path for shared utilities
_HOOK_DIR = Path(__file__).resolve().parent
# Support both dev layout (hooks/{name}/) and installed layout (~/.claude/hooks/)
_LIB_DIR = _HOOK_DIR / "lib" if (_HOOK_DIR / "lib").is_dir() else _HOOK_DIR.parent / "lib"
if str(_LIB_DIR) not in sys.path:
    sys.path.insert(0, str(_LIB_DIR))

from git_utils import (  # noqa: E402
    get_current_branch,
    get_repo_root,
    is_worktree,
    write_worktree_meta,
)
from worktree_state import WorktreeState  # noqa: E402

# Orchestration paths allowed directly on the main repo
ALLOWED_PREFIXES = (
    ".work/",
    "work/",
    "docs/",
    ".claude/",
    ".github/",
    "hooks/",
    "templates/",
    "scripts/",
    "lib/",
    "CLAUDE.md",
    "AGENTS.md",
    "README.md",
    "pyproject.toml",
    "uv.lock",
    "Makefile",
    ".pre-commit-config.yaml",
    ".clang-format",
    ".clang-tidy",
    "ruff.toml",
)


def _is_orchestration_file(rel_path: str) -> bool:
    for prefix in ALLOWED_PREFIXES:
        if rel_path.startswith(prefix) or rel_path == prefix.rstrip("/"):
            return True
    return False


def _ensure_worktree(main_root: Path, base_branch: str) -> tuple[Path, str, WorktreeState]:
    """Create or reuse a session-scoped worktree. Returns (wt_path, wt_branch, state)."""
    state = WorktreeState.for_session()

    # Reuse existing worktree if valid
    if state.exists():
        wt_path = state.worktree_path()
        wt_branch = state.branch_name()
        if wt_path and wt_path.exists() and wt_branch:
            return wt_path, wt_branch, state

    project = main_root.name
    stamp = datetime.now().strftime("%m%d-%H%M")
    # Branch naming: feature-adhoc-{stamp}
    wt_branch = f"feature-adhoc-{stamp}"
    wt_dir = main_root.parent / f"{project}-feature-adhoc-{stamp}"

    # Handle existing directory
    if wt_dir.exists():
        check = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            capture_output=True, text=True, cwd=str(main_root),
        )
        wt_str = str(wt_dir.resolve())
        if wt_str not in check.stdout:
            subprocess.run(["rm", "-rf", str(wt_dir)], capture_output=True)
        else:
            existing_branch = get_current_branch(wt_dir)
            state.set_worktree_path(wt_dir)
            state.set_branch_name(existing_branch or wt_branch)
            state.set_base_branch(base_branch)
            return wt_dir, existing_branch or wt_branch, state

    # Create worktree branching off current branch
    subprocess.run(
        ["git", "worktree", "add", "-b", wt_branch, str(wt_dir), base_branch],
        capture_output=True, text=True, cwd=str(main_root),
        timeout=30,
    )

    # Populate state
    state.set_worktree_path(wt_dir)
    state.set_branch_name(wt_branch)
    state.set_base_branch(base_branch)

    # Persist base branch in worktree (survives session/PPID changes)
    write_worktree_meta(wt_dir, base_branch)

    # Ensure meta file is git-ignored in the worktree
    wt_gitignore = wt_dir / ".gitignore"
    meta_entry = ".claude-worktree-meta"
    if wt_gitignore.exists():
        existing = wt_gitignore.read_text()
        if meta_entry not in existing:
            wt_gitignore.write_text(existing.rstrip("\n") + f"\n{meta_entry}\n")
    else:
        wt_gitignore.write_text(f"{meta_entry}\n")

    return wt_dir, wt_branch, state


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

    # Determine git root for the file's location
    file_dir = abs_path.parent if not abs_path.is_dir() else abs_path
    while not file_dir.exists() and file_dir != file_dir.parent:
        file_dir = file_dir.parent

    root = get_repo_root(file_dir)
    if not root:
        return

    # If we're already in a worktree — allow all edits
    if is_worktree(root):
        return

    # Resolve relative path
    try:
        rel_path = str(abs_path.relative_to(root))
    except ValueError:
        return

    # Orchestration files are fine on the main repo
    if _is_orchestration_file(rel_path):
        return

    # Only activate for projects that opted in (install.sh --core or --collab)
    if not (root / ".claude-worktree-enabled").exists():
        return

    # --- Main repo + code file → redirect to worktree ---
    base_branch = get_current_branch(root)
    if not base_branch or base_branch == "HEAD":
        return  # Detached HEAD — don't interfere

    wt_path, _wt_branch, state = _ensure_worktree(root, base_branch)
    redirect_path = wt_path / rel_path

    msg = (
        f"REDIRECT: You are on branch '{base_branch}' in the main repo.\n"
        f"A worktree has been created at:\n"
        f"  {wt_path}\n"
        f"Re-run your edit using the worktree path:\n"
        f"  {redirect_path}\n"
        f"When done, commit and merge locally (no PR)."
    )
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
