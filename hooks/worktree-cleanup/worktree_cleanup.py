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

from gh_utils import get_current_branch, get_repo_root, resolve_owner_repo  # noqa: E402
from worktree_state import WorktreeState  # noqa: E402


def _close_issue(repo: str, issue_num: int) -> None:
    """Close a GitHub issue and apply status:merged label."""
    subprocess.run(
        ["gh", "issue", "close", str(issue_num), "--repo", repo],
        capture_output=True, text=True, timeout=15,
    )
    # Best-effort label update
    subprocess.run(
        ["gh", "issue", "edit", str(issue_num), "--repo", repo,
         "--add-label", "status:merged"],
        capture_output=True, text=True, timeout=15,
    )
    print(f"[worktree-cleanup] Closed issue #{issue_num}", file=sys.stderr)


def _extract_issue_from_pr(repo: str, branch: str) -> int | None:
    """Extract linked issue number from a PR's body (Closes #N pattern)."""
    result = subprocess.run(
        ["gh", "pr", "view", branch, "--repo", repo,
         "--json", "body", "-q", ".body"],
        capture_output=True, text=True, timeout=15,
    )
    if result.returncode != 0:
        return None
    m = re.search(r"(?:Closes|Fixes|Resolves)\s+#(\d+)", result.stdout, re.IGNORECASE)
    return int(m.group(1)) if m else None


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


def _is_pr_done(main_root: Path, branch: str) -> bool:
    """Check if the branch's PR is merged or closed on GitHub."""
    repo = resolve_owner_repo(main_root)
    if not repo:
        return False
    check = subprocess.run(
        ["gh", "pr", "view", branch, "--repo", repo, "--json", "state", "-q", ".state"],
        capture_output=True, text=True, timeout=15,
    )
    return check.returncode == 0 and check.stdout.strip() in ("MERGED", "CLOSED")


def _find_merged_worktrees(main_root: Path) -> list[tuple[Path, str]]:
    """Find worktrees whose branches have been merged or whose PRs are done."""
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    if result.returncode != 0:
        return []

    merged = []
    current_wt = None
    current_branch = None
    main_branch = get_current_branch(main_root)

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

            should_clean = False

            # Check 1: branch is ancestor of main (locally merged)
            if main_branch and main_branch != "HEAD":
                check = subprocess.run(
                    ["git", "merge-base", "--is-ancestor", current_branch, main_branch],
                    capture_output=True, text=True, cwd=str(main_root),
                )
                if check.returncode == 0:
                    should_clean = True

            # Check 2: PR is merged or closed on GitHub
            if not should_clean:
                try:
                    should_clean = _is_pr_done(main_root, current_branch)
                except (subprocess.TimeoutExpired, OSError):
                    pass

            if should_clean:
                merged.append((current_wt, current_branch))

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
            pr_num = state.pr_number()
            if pr_num:
                repo = state.repo_slug() or resolve_owner_repo(root)
                if repo:
                    check = subprocess.run(
                        ["gh", "pr", "view", str(pr_num), "--repo", repo, "--json", "state", "-q", ".state"],
                        capture_output=True, text=True,
                    )
                    pr_state = check.stdout.strip() if check.returncode == 0 else ""
                    # Clean up on MERGED or CLOSED (failed/rejected PRs)
                    if pr_state in ("MERGED", "CLOSED"):
                        _cleanup_worktree(root, wt_path, branch)
                        issue_num = state.issue_number()
                        if issue_num and repo:
                            _close_issue(repo, issue_num)
                        state.cleanup()
                        return

    # Scan for any other merged worktrees
    merged = _find_merged_worktrees(root)
    repo = resolve_owner_repo(root)
    for wt_path, branch in merged:
        _cleanup_worktree(root, wt_path, branch)
        # Close linked issue from PR body
        if repo:
            try:
                issue_num = _extract_issue_from_pr(repo, branch)
                if issue_num:
                    _close_issue(repo, issue_num)
            except (subprocess.TimeoutExpired, OSError):
                pass

    # Prune stale worktree refs
    subprocess.run(
        ["git", "worktree", "prune"],
        capture_output=True, text=True, cwd=str(root),
    )


if __name__ == "__main__":
    main()
