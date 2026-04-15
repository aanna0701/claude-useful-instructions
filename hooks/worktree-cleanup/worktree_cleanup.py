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



def _main_worktree_branch(main_root: Path) -> str | None:
    """Return the branch checked out in the primary worktree (the repo root).

    This is the developer's current integration context — whatever branch was
    active when secondary worktrees were spawned. Deleting it would yank the
    ground under every in-flight PR based on it, so we treat it as protected
    automatically (no hard-coded name).
    """
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    if result.returncode != 0:
        return None
    current_wt: Path | None = None
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            current_wt = Path(line.split(" ", 1)[1])
        elif line.startswith("branch ") and current_wt == main_root:
            return line.split(" ", 1)[1].replace("refs/heads/", "")
        elif line == "":
            current_wt = None
    return None


def _is_protected_branch(branch: str, main_root: Path) -> bool:
    """True when *branch* must never be auto-deleted.

    Sources (all auto-detected, no hard-coded project branches):
      1. The primary-worktree branch — the current integration hub.
      2. Long-lived release branches by convention
         (main / master / develop / research / staging).
      3. Anything the user pins via GIT_CLEANUP_PROTECTED_BRANCHES.
    """
    import os as _os
    release_defaults = {"main", "master", "develop", "research", "staging"}
    extra = _os.environ.get("GIT_CLEANUP_PROTECTED_BRANCHES", "")
    extra_set = {b.strip() for b in extra.split(",") if b.strip()}
    hub = _main_worktree_branch(main_root)
    protected = release_defaults | extra_set | ({hub} if hub else set())
    return branch in protected


def _is_base_of_open_pr(repo: str | None, branch: str) -> bool:
    """True if any open PR targets *branch* as its base."""
    if not repo:
        return False
    check = subprocess.run(
        ["gh", "pr", "list", "--repo", repo, "--base", branch,
         "--state", "open", "--json", "number", "-q", "length"],
        capture_output=True, text=True, timeout=15,
    )
    try:
        return int((check.stdout or "0").strip()) > 0
    except ValueError:
        return False


def _cleanup_worktree(main_root: Path, wt_path: Path, branch: str) -> None:
    """Remove worktree, local branch, and remote branch.

    Defense-in-depth: refuses to delete protected hub branches or branches
    that are the base of any open PR. Upstream callers should filter first,
    but a buggy caller shouldn't be able to nuke the integration branch.
    """
    wt_str = str(wt_path)
    repo = resolve_owner_repo(main_root)

    if _is_protected_branch(branch, main_root):
        print(
            f"[worktree-cleanup] Refuse to delete protected branch: {branch}",
            file=sys.stderr,
        )
        # Still remove the worktree directory — branch is the protected part.
        if wt_path.exists() and wt_path != main_root:
            subprocess.run(
                ["git", "worktree", "remove", wt_str, "--force"],
                capture_output=True, text=True, cwd=str(main_root),
            )
        return

    if _is_base_of_open_pr(repo, branch):
        print(
            f"[worktree-cleanup] Refuse to delete {branch}: base of open PR(s)",
            file=sys.stderr,
        )
        if wt_path.exists() and wt_path != main_root:
            subprocess.run(
                ["git", "worktree", "remove", wt_str, "--force"],
                capture_output=True, text=True, cwd=str(main_root),
            )
        return

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

            # Safety: never clean a branch with an OPEN PR. Auto-sync workflows
            # or local ancestry quirks can otherwise make a live work-item's
            # worktree vanish mid-session.
            repo = resolve_owner_repo(main_root)
            if repo:
                pr_check = subprocess.run(
                    ["gh", "pr", "view", current_branch, "--repo", repo,
                     "--json", "state", "-q", ".state"],
                    capture_output=True, text=True, timeout=15,
                )
                if pr_check.returncode == 0 and pr_check.stdout.strip() == "OPEN":
                    current_wt = None
                    current_branch = None
                    continue

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


def _cleanup_orphan_branches(main_root: Path, repo: str | None) -> None:
    """Delete local (and remote) branches that are merged into main but have no worktree.

    Targets feature-* and tmp/guard-* branches only — never touches main/master/develop.
    """
    main_branch = get_current_branch(main_root)
    if not main_branch or main_branch == "HEAD":
        return

    # Collect branches that are active worktrees (skip those)
    wt_result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    wt_branches: set[str] = set()
    for line in (wt_result.stdout or "").splitlines():
        if line.startswith("branch "):
            wt_branches.add(line.split(" ", 1)[1].replace("refs/heads/", ""))

    # List local branches merged into main
    result = subprocess.run(
        ["git", "branch", "--merged", main_branch, "--format=%(refname:short)"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    if result.returncode != 0:
        return

    safe_prefixes = ("feature-", "tmp/guard-")

    for branch in result.stdout.strip().splitlines():
        branch = branch.strip()
        if not branch or branch == main_branch:
            continue
        # Auto-detected protection: primary-worktree branch, release defaults,
        # and the user's GIT_CLEANUP_PROTECTED_BRANCHES list. No hard-coded
        # project names.
        if _is_protected_branch(branch, main_root):
            continue
        if branch in wt_branches:
            continue
        if not any(branch.startswith(p) for p in safe_prefixes):
            continue

        # Safety 1: never delete a branch with an OPEN PR as HEAD.
        # ancestry-into-main can be true the instant a feature branch is created
        # from main HEAD, before any merge happens. Without this check, creating
        # a feature branch and pushing it would race the cleanup hook and the
        # head_ref_deleted event would auto-close the brand-new PR.
        if repo:
            check = subprocess.run(
                ["gh", "pr", "view", branch, "--repo", repo, "--json", "state",
                 "-q", ".state"],
                capture_output=True, text=True, timeout=15,
            )
            pr_state = check.stdout.strip() if check.returncode == 0 else ""
            if pr_state == "OPEN":
                continue

            # Safety 2: never delete a branch that is the BASE of any open PR.
            # Deleting it triggers base_ref_deleted on GitHub which auto-closes
            # every child PR (observed case: hub branch for stacked PRs).
            if _is_base_of_open_pr(repo, branch):
                print(
                    f"[worktree-cleanup] Skip {branch}: base of open PR(s)",
                    file=sys.stderr,
                )
                continue

        # Delete local branch
        subprocess.run(
            ["git", "branch", "-D", branch],
            capture_output=True, text=True, cwd=str(main_root),
        )
        # Delete remote branch if it exists
        if repo:
            subprocess.run(
                ["git", "push", "origin", "--delete", branch],
                capture_output=True, text=True, cwd=str(main_root),
                timeout=30,
            )
        print(f"[worktree-cleanup] Cleaned orphan branch: {branch}", file=sys.stderr)


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
                        state.cleanup()
                        return

    # Scan for any other merged worktrees
    merged = _find_merged_worktrees(root)
    repo = resolve_owner_repo(root)
    for wt_path, branch in merged:
        _cleanup_worktree(root, wt_path, branch)

    # Clean up merged local branches that have no worktree
    _cleanup_orphan_branches(root, repo)

    # Prune stale worktree refs
    subprocess.run(
        ["git", "worktree", "prune"],
        capture_output=True, text=True, cwd=str(root),
    )


if __name__ == "__main__":
    main()
