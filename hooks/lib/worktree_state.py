"""Structured worktree state management for Claude Code hooks.

Replaces the old 2-line marker file (/tmp/.claude-guard-trunk-{PPID})
with a directory-based state at /tmp/.claude-worktree-state-{PPID}/.

Each field is a separate file for atomic reads/writes.
"""
from __future__ import annotations

import os
import shutil
from pathlib import Path

_OLD_MARKER_PREFIX = "/tmp/.claude-guard-trunk-"
_STATE_DIR_PREFIX = "/tmp/.claude-worktree-state-"


class WorktreeState:
    """Manages per-session worktree state."""

    def __init__(self, state_dir: Path) -> None:
        self._dir = state_dir

    @staticmethod
    def for_session() -> WorktreeState:
        """Get state for the current Claude Code session (keyed on PPID)."""
        ppid = os.getppid()
        state = WorktreeState(Path(f"{_STATE_DIR_PREFIX}{ppid}"))

        # Migrate from old marker format if needed
        old_marker = Path(f"{_OLD_MARKER_PREFIX}{ppid}")
        if old_marker.exists() and not state.exists():
            state._migrate_old_marker(old_marker)

        return state

    def _migrate_old_marker(self, old_marker: Path) -> None:
        """Migrate from the old 2-line marker file format."""
        lines = old_marker.read_text().strip().splitlines()
        if not lines:
            return
        self._dir.mkdir(parents=True, exist_ok=True)
        self.set_worktree_path(Path(lines[0]))
        if len(lines) > 1:
            self.set_branch_name(lines[1])
        old_marker.unlink(missing_ok=True)

    def exists(self) -> bool:
        return self._dir.is_dir()

    def ensure(self) -> None:
        self._dir.mkdir(parents=True, exist_ok=True)

    # ── Field accessors ─────────────────────────────────────────────────

    def _read(self, name: str) -> str | None:
        f = self._dir / name
        return f.read_text().strip() if f.exists() else None

    def _write(self, name: str, value: str) -> None:
        self.ensure()
        (self._dir / name).write_text(value)

    # Worktree path
    def worktree_path(self) -> Path | None:
        v = self._read("worktree.path")
        return Path(v) if v else None

    def set_worktree_path(self, path: Path) -> None:
        self._write("worktree.path", str(path))

    # Branch name
    def branch_name(self) -> str | None:
        return self._read("branch.name")

    def set_branch_name(self, name: str) -> None:
        self._write("branch.name", name)

    # Base branch (the branch the worktree was created from)
    def base_branch(self) -> str | None:
        return self._read("base.branch")

    def set_base_branch(self, name: str) -> None:
        self._write("base.branch", name)

    # Issue number
    def issue_number(self) -> int | None:
        v = self._read("issue.number")
        return int(v) if v else None

    def set_issue_number(self, number: int) -> None:
        self._write("issue.number", str(number))

    # PR number
    def pr_number(self) -> int | None:
        v = self._read("pr.number")
        return int(v) if v else None

    def set_pr_number(self, number: int) -> None:
        self._write("pr.number", str(number))

    # PR URL
    def pr_url(self) -> str | None:
        return self._read("pr.url")

    def set_pr_url(self, url: str) -> None:
        self._write("pr.url", url)

    # Repo slug (owner/repo)
    def repo_slug(self) -> str | None:
        return self._read("repo.slug")

    def set_repo_slug(self, slug: str) -> None:
        self._write("repo.slug", slug)

    # ── Cleanup ─────────────────────────────────────────────────────────

    def cleanup(self) -> None:
        """Remove the state directory."""
        if self._dir.exists():
            shutil.rmtree(self._dir, ignore_errors=True)
        # Also clean up old marker if it exists
        old = Path(f"{_OLD_MARKER_PREFIX}{os.getppid()}")
        old.unlink(missing_ok=True)
