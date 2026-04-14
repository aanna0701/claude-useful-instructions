#!/usr/bin/env python3
"""Claude Code PostToolUse hook — auto-create draft PR on first commit.

Fires after every Bash tool call. If the command contained 'git commit'
and succeeded, checks if a PR already exists for this branch. If not,
pushes the branch and creates a draft PR.

Uses WorktreeState to track PR numbers across the session.
Falls back to .claude-worktree-meta for base branch recovery.

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
    get_main_repo_from_worktree,
    get_parent_branch,
    get_repo_root,
    push_branch,
    resolve_owner_repo,
)
from worktree_state import WorktreeState  # noqa: E402



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


def _update_existing_pr(git_dir: Path, branch: str, pr_num: int, state: WorktreeState) -> None:
    """Update an early/WIP PR with actual commit info."""
    repo = resolve_owner_repo(git_dir)
    if not repo:
        return

    # Check if title still has [WIP] placeholder
    result = subprocess.run(
        ["gh", "pr", "view", str(pr_num), "--repo", repo, "--json", "title", "-q", ".title"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return

    current_title = result.stdout.strip()
    if not current_title.startswith("[WIP]"):
        return  # Already updated, nothing to do

    # Get base branch for commit log
    base = state.base_branch() or get_parent_branch(git_dir)
    if not base:
        return

    # Push latest commits
    push_branch(git_dir, branch)

    # Build new title and body from commits
    commit_log, title = _get_commit_info(git_dir, base, branch)
    body = f"## Changes\n{commit_log}\n"

    subprocess.run(
        ["gh", "pr", "edit", str(pr_num), "--repo", repo, "--title", title, "--body", body],
        capture_output=True, text=True, timeout=30,
    )
    print(f"[auto-pr-commit] Updated PR #{pr_num} title: {title}", file=sys.stderr)


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

    # Check if PR already exists (early PR from guard-branch or previous session)
    pr_num = state.pr_number()
    if not pr_num:
        existing_pr = _check_existing_pr(root, branch)
        if existing_pr:
            pr_num_match = re.search(r"/(\d+)$", existing_pr)
            if pr_num_match:
                pr_num = int(pr_num_match.group(1))
                state.set_pr_number(pr_num)
                state.set_pr_url(existing_pr)

    if pr_num:
        # PR exists — update title/body if it still has the [WIP] placeholder
        _update_existing_pr(root, branch, pr_num, state)
        return

    # Determine base branch — never fallback to main repo's current branch
    base = state.base_branch()
    if not base:
        # Fallback: read from persistent .claude-worktree-meta in worktree
        base = get_parent_branch(root)
    if not base:
        print("[auto-pr-commit] No base branch in state or meta. "
              "Create PR manually with: gh pr create --base <branch>", file=sys.stderr)
        return

    # Validate: stored base must match parent repo's current branch
    main_repo = get_main_repo_from_worktree(root)
    if main_repo:
        parent_current = get_current_branch(main_repo)
        if parent_current and parent_current != "HEAD" and parent_current != base:
            print(f"[auto-pr-commit] BASE MISMATCH: stored base '{base}' "
                  f"≠ parent current '{parent_current}'. "
                  f"Skipping auto-PR to prevent wrong-branch merge. "
                  f"Create PR manually if intended.", file=sys.stderr)
            return

    # Push branch
    if not push_branch(root, branch):
        print("[auto-pr-commit] Push failed, skipping PR creation.", file=sys.stderr)
        return

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
