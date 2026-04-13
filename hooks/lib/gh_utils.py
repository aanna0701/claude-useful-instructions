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



def create_draft_pr(
    git_dir: Path,
    base: str,
    head: str,
    title: str,
    body: str,
) -> str | None:
    """Create a draft PR. Returns PR URL or None on failure."""
    repo = resolve_owner_repo(git_dir)
    if not repo:
        return None

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


# ── Worktree meta (persistent base branch) ──────────────────────────

_META_FILENAME = ".claude-worktree-meta"


def write_worktree_meta(wt_dir: Path, base_branch: str, **extra: str) -> None:
    """Write persistent metadata into the worktree directory."""
    import json
    data = {"base_branch": base_branch, **extra}
    (wt_dir / _META_FILENAME).write_text(json.dumps(data) + "\n")


def read_worktree_meta(wt_dir: Path) -> dict | None:
    """Read persistent metadata from the worktree directory. Returns None if missing."""
    import json
    meta_file = wt_dir / _META_FILENAME
    if not meta_file.exists():
        return None
    try:
        return json.loads(meta_file.read_text())
    except (json.JSONDecodeError, OSError):
        return None


def get_parent_branch(wt_dir: Path) -> str | None:
    """Resolve base branch for a worktree, with fallback chain:

    1. .claude-worktree-meta file in the worktree directory
    2. None (never fallback to main repo's current branch)
    """
    meta = read_worktree_meta(wt_dir)
    return meta["base_branch"] if meta else None
