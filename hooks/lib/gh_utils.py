"""Shared GitHub utilities for Claude Code hooks.

All functions accept a git_dir parameter and use --repo flag internally,
so they work regardless of the current working directory.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path


def resolve_owner_repo(git_dir: Path) -> str | None:
    """Derive owner/repo from git remote origin URL.

    Handles formats:
      - git@github.com:owner/repo.git
      - https://github.com/owner/repo.git
      - https://TOKEN@github.com/owner/repo.git
    Returns 'owner/repo' or None if not a GitHub remote.
    """
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    if result.returncode != 0:
        return None

    url = result.stdout.strip()

    # SSH format: git@github.com:owner/repo.git
    m = re.match(r"git@github\.com:(.+?)(?:\.git)?$", url)
    if m:
        return m.group(1)

    # HTTPS format (with optional token): https://...github.com/owner/repo.git
    m = re.match(r"https://(?:[^@]+@)?github\.com/(.+?)(?:\.git)?$", url)
    if m:
        return m.group(1)

    return None


def get_current_branch(git_dir: Path) -> str:
    """Get the current branch name. Returns empty string on failure."""
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def get_repo_root(git_dir: Path) -> Path | None:
    """Get the git repository root directory."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    return Path(result.stdout.strip()) if result.returncode == 0 else None


def is_worktree(git_dir: Path) -> bool:
    """Check if the given directory is a git worktree (not the main repo).

    A worktree has .git as a file (pointing to the main repo's .git/worktrees/),
    while the main repo has .git as a directory.
    """
    dot_git = git_dir / ".git"
    return dot_git.is_file()


def get_main_repo_from_worktree(git_dir: Path) -> Path | None:
    """If git_dir is a worktree, return the main repo root. Otherwise None."""
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    if result.returncode != 0:
        return None

    # First "worktree" entry in porcelain output is always the main repo
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            return Path(line.split(" ", 1)[1])
    return None


def create_issue(
    git_dir: Path,
    title: str,
    body: str,
    labels: list[str] | None = None,
) -> int | None:
    """Create a GitHub issue. Returns issue number or None on failure."""
    repo = resolve_owner_repo(git_dir)
    if not repo:
        return None

    cmd = [
        "gh", "issue", "create",
        "--repo", repo,
        "--title", title,
        "--body", body,
    ]
    for label in labels or []:
        # Ensure label exists (ignore errors if already exists)
        subprocess.run(
            ["gh", "label", "create", label, "--repo", repo, "--color", "0E8A16"],
            capture_output=True, text=True,
        )
        cmd.extend(["--label", label])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        return None

    # gh outputs the issue URL, extract number from end
    m = re.search(r"/(\d+)\s*$", result.stdout.strip())
    return int(m.group(1)) if m else None


def create_draft_pr(
    git_dir: Path,
    base: str,
    head: str,
    title: str,
    body: str,
    issue_num: int | None = None,
) -> str | None:
    """Create a draft PR. Returns PR URL or None on failure."""
    repo = resolve_owner_repo(git_dir)
    if not repo:
        return None

    if issue_num:
        body = f"{body}\n\nCloses #{issue_num}"

    cmd = [
        "gh", "pr", "create",
        "--repo", repo,
        "--base", base,
        "--head", head,
        "--title", title,
        "--body", body,
        "--draft",
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        return None

    return result.stdout.strip()


def push_branch(git_dir: Path, branch: str) -> bool:
    """Push a branch to origin with -u flag. Returns True on success."""
    result = subprocess.run(
        ["git", "push", "-u", "origin", branch],
        capture_output=True, text=True, cwd=str(git_dir), timeout=60,
    )
    return result.returncode == 0
