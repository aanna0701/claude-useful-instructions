#!/usr/bin/env python3
"""Claude Code PostToolUse hook — auto-create draft PR on first commit.

Fires after every Bash tool call. If the command contained 'git commit'
and succeeded, checks if a PR already exists for this branch. If not,
pushes the branch and creates a draft PR.

Uses WorktreeState to track issue/PR numbers across the session.
Falls back to reading work item status.md for collab worktrees.

Exit code 0 always (PostToolUse hooks never block).
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

# Add hooks/lib to path
_HOOK_DIR = Path(__file__).resolve().parent
# Support both dev layout (hooks/{name}/) and installed layout (~/.claude/hooks/)
_LIB_DIR = _HOOK_DIR / "lib" if (_HOOK_DIR / "lib").is_dir() else _HOOK_DIR.parent / "lib"
if str(_LIB_DIR) not in sys.path:
    sys.path.insert(0, str(_LIB_DIR))

from gh_utils import (  # noqa: E402
    create_draft_pr,
    get_current_branch,
    get_repo_root,
    push_branch,
    resolve_owner_repo,
)
from worktree_state import WorktreeState  # noqa: E402


def _find_issue_from_work_items(repo_root: Path, branch: str) -> int | None:
    """Try to find issue number from work/items/*/status.md for collab worktrees."""
    work_items = repo_root / "work" / "items"
    if not work_items.exists():
        return None

    # Extract slug from branch name (e.g., feat/FEAT-123-slug -> FEAT-123-slug)
    slug = branch.split("/", 1)[-1] if "/" in branch else branch

    for item_dir in work_items.iterdir():
        if not item_dir.is_dir():
            continue
        if slug in item_dir.name:
            status_file = item_dir / "status.md"
            if status_file.exists():
                content = status_file.read_text()
                # Look for Issue field: #123 or empty
                m = re.search(r"Issue[:\s|]+#?(\d+)", content)
                if m:
                    return int(m.group(1))
    return None


def _update_work_item_status(repo_root: Path, branch: str, pr_url: str) -> None:
    """Update status.md PR field for collab worktrees."""
    work_items = repo_root / "work" / "items"
    if not work_items.exists():
        return

    slug = branch.split("/", 1)[-1] if "/" in branch else branch

    for item_dir in work_items.iterdir():
        if not item_dir.is_dir():
            continue
        if slug in item_dir.name:
            status_file = item_dir / "status.md"
            if status_file.exists():
                content = status_file.read_text()
                # Update PR field
                content = re.sub(
                    r"(PR[:\s|]+)\S*",
                    rf"\g<1>{pr_url}",
                    content,
                    count=1,
                )
                status_file.write_text(content)
            break


def _get_commit_info(git_dir: Path, base: str, head: str) -> tuple[str, str]:
    """Get commit log and derive a PR title."""
    log_result = subprocess.run(
        ["git", "log", "--format=- %s", f"{base}..{head}"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    commit_log = log_result.stdout.strip() if log_result.returncode == 0 else ""

    # Count commits
    count_result = subprocess.run(
        ["git", "rev-list", "--count", f"{base}..{head}"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    count = int(count_result.stdout.strip()) if count_result.returncode == 0 else 0

    # First commit message as title
    first_result = subprocess.run(
        ["git", "log", "--format=%s", f"{base}..{head}"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    lines = first_result.stdout.strip().splitlines() if first_result.returncode == 0 else []

    if count == 1 and lines:
        title = lines[-1]
    elif count > 1 and lines:
        first = lines[-1]
        type_match = re.match(r"^(feat|fix|refactor|docs|test|chore|perf|ci)", first)
        prefix = type_match.group(1) if type_match else "chore"
        slug = head.split("/")[-1]
        title = f"{prefix}: {slug} ({count} commits)"
    else:
        title = f"changes on {head}"

    return commit_log, title


def _check_existing_pr(git_dir: Path, branch: str) -> str | None:
    """Check if a PR already exists for this branch. Returns PR URL or None."""
    repo = resolve_owner_repo(git_dir)
    if not repo:
        return None

    result = subprocess.run(
        ["gh", "pr", "view", branch, "--repo", repo, "--json", "url", "-q", ".url"],
        capture_output=True, text=True,
    )
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()
    return None


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return

    # Only process Bash tool calls
    if payload.get("tool_name") != "Bash":
        return

    tool_input = payload.get("tool_input", {})
    command = tool_input.get("command", "")

    # Quick check: does the command contain 'git commit'?
    if "git commit" not in command:
        return

    # Check for commit success in response
    tool_response = payload.get("tool_response", {})
    stdout = tool_response.get("stdout", "")
    if "nothing to commit" in stdout or "no changes added" in stdout:
        return

    # Get current git context
    cwd = Path.cwd()
    root = get_repo_root(cwd)
    if not root:
        return

    branch = get_current_branch(root)
    if not branch or branch in ("main", "master", "HEAD"):
        return  # Don't create PRs for trunk branches

    # Load session state
    state = WorktreeState.for_session()

    # If PR already tracked in state, skip
    if state.pr_number():
        return

    # Check if PR already exists on GitHub
    existing_pr = _check_existing_pr(root, branch)
    if existing_pr:
        pr_num_match = re.search(r"/(\d+)$", existing_pr)
        if pr_num_match:
            state.set_pr_number(int(pr_num_match.group(1)))
            state.set_pr_url(existing_pr)
        return

    # Determine base branch
    base = state.base_branch()
    if not base:
        # Try to infer from branch pattern
        # adhoc/* branches → need to check git merge-base
        result = subprocess.run(
            ["git", "log", "--format=%D", "--all", "--ancestry-path", f"{branch}.."],
            capture_output=True, text=True, cwd=str(root),
        )
        # Fallback: check common base branches
        for candidate in ("research", "develop", "main", "master"):
            check = subprocess.run(
                ["git", "rev-parse", "--verify", candidate],
                capture_output=True, text=True, cwd=str(root),
            )
            if check.returncode == 0:
                base = candidate
                break
        if not base:
            base = "main"

    # Push branch
    if not push_branch(root, branch):
        print("[auto-pr-commit] Push failed, skipping PR creation.", file=sys.stderr)
        return

    # Get issue number (from state or work items)
    issue_num = state.issue_number() or _find_issue_from_work_items(root, branch)

    # Build PR body
    commit_log, title = _get_commit_info(root, base, branch)
    body = f"## Changes\n{commit_log}\n"

    # Create draft PR
    pr_url = create_draft_pr(
        git_dir=root,
        base=base,
        head=branch,
        title=title,
        body=body,
        issue_num=issue_num,
    )

    if pr_url:
        pr_num_match = re.search(r"/(\d+)$", pr_url)
        if pr_num_match:
            state.set_pr_number(int(pr_num_match.group(1)))
        state.set_pr_url(pr_url)
        _update_work_item_status(root, branch, pr_url)
        print(f"[auto-pr-commit] Draft PR created: {pr_url}", file=sys.stderr)
    else:
        print("[auto-pr-commit] PR creation failed.", file=sys.stderr)


if __name__ == "__main__":
    main()
