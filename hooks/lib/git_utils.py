"""Shared git utilities for Claude Code hooks (local-only flow, no GitHub PRs)."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path


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
    """Check if the given directory is a git worktree (not the main repo)."""
    return (git_dir / ".git").is_file()


def get_main_repo_from_worktree(git_dir: Path) -> Path | None:
    """If git_dir is a worktree, return the main repo root. Otherwise None."""
    result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    if result.returncode != 0:
        return None
    for line in result.stdout.splitlines():
        if line.startswith("worktree "):
            return Path(line.split(" ", 1)[1])
    return None


def has_remote(git_dir: Path) -> bool:
    """True if the repo has an 'origin' remote configured."""
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        capture_output=True, text=True, cwd=str(git_dir),
    )
    return result.returncode == 0


_META_FILENAME = ".claude-worktree-meta"


def write_worktree_meta(wt_dir: Path, base_branch: str, **extra: str) -> None:
    """Write persistent metadata into the worktree directory."""
    data = {"base_branch": base_branch, **extra}
    (wt_dir / _META_FILENAME).write_text(json.dumps(data) + "\n")


def read_worktree_meta(wt_dir: Path) -> dict | None:
    """Read persistent metadata from the worktree directory."""
    meta_file = wt_dir / _META_FILENAME
    if not meta_file.exists():
        return None
    try:
        return json.loads(meta_file.read_text())
    except (json.JSONDecodeError, OSError):
        return None


def get_parent_branch(wt_dir: Path) -> str | None:
    """Resolve base branch for a worktree from .claude-worktree-meta."""
    meta = read_worktree_meta(wt_dir)
    return meta["base_branch"] if meta else None
