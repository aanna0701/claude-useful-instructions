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



_BRANCH_RE = re.compile(r"^feature-(feat|fix|perf|chore|test|refac)-(.+)$")


def _work_item_info(git_dir: Path, branch: str) -> tuple[str | None, str | None, Path | None]:
    """Return (ID, TYPE, contract_path) if this branch maps to a v2 work item."""
    m = _BRANCH_RE.match(branch)
    if not m:
        return None, None, None
    work_type = m.group(1).upper()
    slug = m.group(2)
    items_dir = git_dir / "work" / "items"
    if not items_dir.is_dir():
        return None, work_type, None
    for item_dir in items_dir.iterdir():
        if not item_dir.is_dir():
            continue
        name = item_dir.name
        if not name.endswith(f"-{slug}"):
            continue
        item_id = name[: -(len(slug) + 1)]
        contract = item_dir / "contract.md"
        return item_id, work_type, contract if contract.is_file() else None
    return None, work_type, None


def _build_v2_body(git_dir: Path, branch: str, commit_log: str) -> str:
    """Build a v2-style PR body with machine-readable markers."""
    item_id, work_type, contract_path = _work_item_info(git_dir, branch)
    if not item_id:
        # Non-work-item branch: keep legacy body.
        return f"## Changes\n{commit_log}\n"
    slug = branch.split("-", 2)[-1] if "-" in branch else branch
    contract_ref = f"work/items/{item_id}-{slug}/contract.md"
    return (
        f"<!-- work-item:{item_id} -->\n"
        f"<!-- work-type:{work_type} -->\n\n"
        f"## Contract\n"
        f"See `{contract_ref}`\n\n"
        f"## Acceptance\n"
        f"- [ ] (transcribe from contract.md)\n\n"
        f"## Changes\n{commit_log}\n"
    )


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

    # Get base branch for commit log — prefer main repo's current HEAD so
    # the commit log uses the same base that the PR is actually targeting.
    base = None
    main_repo = get_main_repo_from_worktree(git_dir)
    if main_repo:
        parent_current = get_current_branch(main_repo)
        if parent_current and parent_current != "HEAD":
            base = parent_current
    if not base:
        base = state.base_branch() or get_parent_branch(git_dir)
    if not base:
        return

    # Push latest commits
    push_branch(git_dir, branch)

    # Build new title and body from commits
    commit_log, title = _get_commit_info(git_dir, base, branch)
    body = _build_v2_body(git_dir, branch, commit_log)

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

    # Determine base branch — the authoritative source is the main repo's
    # currently checked-out branch (the user's mental model: "PR base = whatever
    # branch the repo root has checked out right now"). Sticky session state
    # and .claude-worktree-meta are only fallbacks for edge cases where the
    # main repo isn't introspectable (e.g. detached HEAD).
    base = None
    main_repo = get_main_repo_from_worktree(root)
    if main_repo:
        parent_current = get_current_branch(main_repo)
        if parent_current and parent_current != "HEAD":
            base = parent_current
    if not base:
        base = state.base_branch() or get_parent_branch(root)
    if not base:
        print("[auto-pr-commit] No base branch could be resolved "
              "(main repo detached HEAD and no stored state). "
              "Create PR manually with: gh pr create --base <branch>", file=sys.stderr)
        return

    # Keep session state in sync with the resolved base so later commits and
    # other hooks see a consistent value.
    if state.base_branch() != base:
        state.set_base_branch(base)

    # Push branch
    if not push_branch(root, branch):
        print("[auto-pr-commit] Push failed, skipping PR creation.", file=sys.stderr)
        return

    # Build PR body
    commit_log, title = _get_commit_info(root, base, branch)
    body = _build_v2_body(root, branch, commit_log)

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
        print(f"[auto-pr-commit] Draft PR created: {pr_url}", file=sys.stderr)
    else:
        print("[auto-pr-commit] PR creation failed.", file=sys.stderr)


if __name__ == "__main__":
    main()
