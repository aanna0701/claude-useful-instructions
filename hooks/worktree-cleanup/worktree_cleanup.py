#!/usr/bin/env python3
"""Claude Code PostToolUse hook — cleanup merged worktrees and remote branches.

Fires after Bash tool calls. If the command contained 'gh pr merge' or
'git merge' and succeeded, cleans up:
  1. The worktree directory
  2. The local branch
  3. The remote branch

Also runs on session Stop to catch any merged branches left behind.

Exit code 0 always (never block).
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

_HOOK_DIR = Path(__file__).resolve().parent
# Support both dev layout (hooks/{name}/) and installed layout (~/.claude/hooks/)
_LIB_DIR = _HOOK_DIR / "lib" if (_HOOK_DIR / "lib").is_dir() else _HOOK_DIR.parent / "lib"
if str(_LIB_DIR) not in sys.path:
    sys.path.insert(0, str(_LIB_DIR))

from gh_utils import get_repo_root, resolve_owner_repo  # noqa: E402
from worktree_state import WorktreeState  # noqa: E402


def _cleanup_worktree(main_root: Path, wt_path: Path, branch: str) -> None:
    """Remove worktree, local branch, and remote branch."""
    wt_str = str(wt_path)

    # Remove git worktree
    if wt_path.exists():
        subprocess.run(
            ["git", "worktree", "remove", wt_str, "--force"],
            capture_output=True, text=True, cwd=str(main_root),
        )
        print(f"[worktree-cleanup] Removed worktree: {wt_str}", file=sys.stderr)

    # Delete local branch
    subprocess.run(
        ["git", "branch", "-D", branch],
        capture_output=True, text=True, cwd=str(main_root),
    )

    # Delete remote branch
    repo = resolve_owner_repo(main_root)
    if repo:
        subprocess.run(
            ["git", "push", "origin", "--delete", branch],
            capture_output=True, text=True, cwd=str(main_root),
            timeout=30,
        )
        print(f"[worktree-cleanup] Deleted remote branch: {branch}", file=sys.stderr)


def _find_merged_worktrees(main_root: Path) -> list[tuple[Path, str]]:
    """Find worktrees whose branches have been merged (no commits ahead of base)."""
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    if result.returncode != 0:
        return []

    merged = []
    current_wt = None
    current_branch = None

    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            current_wt = Path(line.split(" ", 1)[1])
        elif line.startswith("branch "):
            ref = line.split(" ", 1)[1]
            current_branch = ref.replace("refs/heads/", "")
        elif line == "" and current_wt and current_branch:
            # Skip the main worktree
            if current_wt == main_root:
                current_wt = None
                current_branch = None
                continue

            # Check if branch is merged into any common base
            for base in ("research", "develop", "main", "master"):
                check = subprocess.run(
                    ["git", "merge-base", "--is-ancestor", current_branch, base],
                    capture_output=True, text=True, cwd=str(main_root),
                )
                if check.returncode == 0:
                    merged.append((current_wt, current_branch))
                    break

            current_wt = None
            current_branch = None

    return merged


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})
    command = tool_input.get("command", "")

    # Trigger on merge-related commands
    is_merge = False
    if tool_name == "Bash":
        if any(kw in command for kw in ("gh pr merge", "git merge", "git worktree remove")):
            is_merge = True
    elif tool_name == "":
        # Stop hook — always check for stale worktrees
        is_merge = True

    if not is_merge:
        return

    root = get_repo_root(Path.cwd())
    if not root:
        return

    # Clean up session worktree if tracked
    state = WorktreeState.for_session()
    if state.exists():
        wt_path = state.worktree_path()
        branch = state.branch_name()
        if wt_path and branch:
            # Check if PR is merged
            pr_num = state.pr_number()
            if pr_num:
                repo = state.repo_slug() or resolve_owner_repo(root)
                if repo:
                    check = subprocess.run(
                        ["gh", "pr", "view", str(pr_num), "--repo", repo, "--json", "state", "-q", ".state"],
                        capture_output=True, text=True,
                    )
                    if check.returncode == 0 and check.stdout.strip() == "MERGED":
                        _cleanup_worktree(root, wt_path, branch)
                        state.cleanup()
                        return

    # Scan for any other merged worktrees
    merged = _find_merged_worktrees(root)
    for wt_path, branch in merged:
        _cleanup_worktree(root, wt_path, branch)

    # Prune stale worktree refs
    subprocess.run(
        ["git", "worktree", "prune"],
        capture_output=True, text=True, cwd=str(root),
    )


if __name__ == "__main__":
    main()
