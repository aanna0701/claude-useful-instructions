#!/usr/bin/env python3
"""Claude Code PostToolUse hook — cleanup merged worktrees (local-only flow).

Fires after Bash tool calls. If the command contained 'git merge' or
'git worktree remove' and a feature branch was merged into its parent,
cleans up:
  1. The worktree directory
  2. The local branch
  3. The remote branch (if origin exists)
  4. The .work/contracts/{ID}-{slug}/ directory — moved to .work/archive/
     for WORK_ARCHIVE_TTL_DAYS days (default 7) before being purged.

Also runs on session Stop to catch any merged branches left behind, and
sweeps .work/archive/ for entries older than the TTL on every fire.

Exit code 0 always (never block).
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Days a closed contract stays in .work/archive/ before purge.
# Override with WORK_ARCHIVE_TTL_DAYS in the environment.
_DEFAULT_ARCHIVE_TTL_DAYS = 7

_HOOK_DIR = Path(__file__).resolve().parent
_LIB_DIR = _HOOK_DIR / "lib" if (_HOOK_DIR / "lib").is_dir() else _HOOK_DIR.parent / "lib"
if str(_LIB_DIR) not in sys.path:
    sys.path.insert(0, str(_LIB_DIR))

from git_utils import (  # noqa: E402
    get_current_branch,
    get_repo_root,
    has_remote,
)
from worktree_state import WorktreeState  # noqa: E402


_FEATURE_RE = re.compile(r"^feature-[a-z]+-(.+)$")


def _main_worktree_branch(main_root: Path) -> str | None:
    """Return the branch checked out in the primary worktree."""
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
    """True when *branch* must never be auto-deleted."""
    import os as _os
    release_defaults = {"main", "master", "develop", "research", "staging"}
    extra = _os.environ.get("GIT_CLEANUP_PROTECTED_BRANCHES", "")
    extra_set = {b.strip() for b in extra.split(",") if b.strip()}
    hub = _main_worktree_branch(main_root)
    protected = release_defaults | extra_set | ({hub} if hub else set())
    return branch in protected


def _archive_ttl_seconds() -> int:
    raw = os.environ.get("WORK_ARCHIVE_TTL_DAYS", "").strip()
    try:
        days = int(raw) if raw else _DEFAULT_ARCHIVE_TTL_DAYS
    except ValueError:
        days = _DEFAULT_ARCHIVE_TTL_DAYS
    return max(0, days) * 86400


def _archive_contract_dir(main_root: Path, branch: str) -> None:
    """Move .work/contracts/*-{slug}/ to .work/archive/ with an .archived-at marker.

    Archived contracts stay around for WORK_ARCHIVE_TTL_DAYS (default 7) so a
    follow-up implementation can crib from the previous spec/review. They are
    purged by `_purge_expired_archives` on every hook fire.
    """
    m = _FEATURE_RE.match(branch)
    if not m:
        return
    slug = m.group(1)
    contracts = main_root / ".work" / "contracts"
    if not contracts.is_dir():
        return
    archive_root = main_root / ".work" / "archive"
    archive_root.mkdir(parents=True, exist_ok=True)
    for child in contracts.iterdir():
        if not (child.is_dir() and child.name.endswith(f"-{slug}")):
            continue
        dest = archive_root / child.name
        # If a same-named archive already exists, suffix with epoch seconds.
        if dest.exists():
            dest = archive_root / f"{child.name}.{int(time.time())}"
        try:
            shutil.move(str(child), str(dest))
            (dest / ".archived-at").write_text(f"{int(time.time())}\n")
            print(
                f"[worktree-cleanup] Archived contract: {dest.relative_to(main_root)} "
                f"(purged after WORK_ARCHIVE_TTL_DAYS={_archive_ttl_seconds() // 86400}d)",
                file=sys.stderr,
            )
        except OSError:
            pass


def _purge_expired_archives(main_root: Path) -> None:
    """Delete archived contracts older than WORK_ARCHIVE_TTL_DAYS."""
    archive_root = main_root / ".work" / "archive"
    if not archive_root.is_dir():
        return
    ttl = _archive_ttl_seconds()
    if ttl == 0:
        return
    cutoff = time.time() - ttl
    for child in archive_root.iterdir():
        if not child.is_dir():
            continue
        marker = child / ".archived-at"
        try:
            ts = int(marker.read_text().strip()) if marker.exists() else int(child.stat().st_mtime)
        except (OSError, ValueError):
            ts = int(child.stat().st_mtime)
        if ts < cutoff:
            try:
                shutil.rmtree(child)
                print(
                    f"[worktree-cleanup] Purged expired archive: {child.relative_to(main_root)}",
                    file=sys.stderr,
                )
            except OSError:
                pass


def _cleanup_worktree(main_root: Path, wt_path: Path, branch: str) -> None:
    """Remove worktree, local branch, remote branch, and contract dir."""
    wt_str = str(wt_path)

    if _is_protected_branch(branch, main_root):
        print(
            f"[worktree-cleanup] Refuse to delete protected branch: {branch}",
            file=sys.stderr,
        )
        if wt_path.exists() and wt_path != main_root:
            subprocess.run(
                ["git", "worktree", "remove", wt_str, "--force"],
                capture_output=True, text=True, cwd=str(main_root),
            )
        return

    if wt_path.exists():
        subprocess.run(
            ["git", "worktree", "remove", wt_str, "--force"],
            capture_output=True, text=True, cwd=str(main_root),
        )
        print(f"[worktree-cleanup] Removed worktree: {wt_str}", file=sys.stderr)

    subprocess.run(
        ["git", "branch", "-D", branch],
        capture_output=True, text=True, cwd=str(main_root),
    )

    if has_remote(main_root):
        subprocess.run(
            ["git", "push", "origin", "--delete", branch],
            capture_output=True, text=True, cwd=str(main_root),
            timeout=30,
        )
        print(f"[worktree-cleanup] Deleted remote branch: {branch}", file=sys.stderr)

    _archive_contract_dir(main_root, branch)


def _find_merged_worktrees(main_root: Path) -> list[tuple[Path, str]]:
    """Find worktrees whose branches have been merged into the current main branch."""
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
            current_branch = line.split(" ", 1)[1].replace("refs/heads/", "")
        elif line == "" and current_wt and current_branch:
            if current_wt == main_root:
                current_wt = None
                current_branch = None
                continue

            if main_branch and main_branch != "HEAD":
                check = subprocess.run(
                    ["git", "merge-base", "--is-ancestor", current_branch, main_branch],
                    capture_output=True, text=True, cwd=str(main_root),
                )
                if check.returncode == 0:
                    merged.append((current_wt, current_branch))

            current_wt = None
            current_branch = None

    return merged


def _cleanup_orphan_branches(main_root: Path) -> None:
    """Delete local (and remote) feature-* / tmp/guard-* branches merged into main but with no worktree."""
    main_branch = get_current_branch(main_root)
    if not main_branch or main_branch == "HEAD":
        return

    wt_result = subprocess.run(
        ["git", "worktree", "list", "--porcelain"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    wt_branches: set[str] = set()
    for line in (wt_result.stdout or "").splitlines():
        if line.startswith("branch "):
            wt_branches.add(line.split(" ", 1)[1].replace("refs/heads/", ""))

    result = subprocess.run(
        ["git", "branch", "--merged", main_branch, "--format=%(refname:short)"],
        capture_output=True, text=True, cwd=str(main_root),
    )
    if result.returncode != 0:
        return

    safe_prefixes = ("feature-", "tmp/guard-")
    remote = has_remote(main_root)

    for branch in result.stdout.strip().splitlines():
        branch = branch.strip()
        if not branch or branch == main_branch:
            continue
        if _is_protected_branch(branch, main_root):
            continue
        if branch in wt_branches:
            continue
        if not any(branch.startswith(p) for p in safe_prefixes):
            continue

        subprocess.run(
            ["git", "branch", "-D", branch],
            capture_output=True, text=True, cwd=str(main_root),
        )
        if remote:
            subprocess.run(
                ["git", "push", "origin", "--delete", branch],
                capture_output=True, text=True, cwd=str(main_root),
                timeout=30,
            )
        _archive_contract_dir(main_root, branch)
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
    tool_input = payload.get("tool_input", {}) or {}
    command = tool_input.get("command", "")

    is_merge = False
    if tool_name == "Bash":
        if any(kw in command for kw in ("git merge", "git worktree remove")):
            is_merge = True
    elif tool_name == "":
        # Stop hook — always check for stale worktrees
        is_merge = True

    if not is_merge:
        return

    root = get_repo_root(Path.cwd())
    if not root:
        return

    state = WorktreeState.for_session()
    if state.exists():
        wt_path = state.worktree_path()
        branch = state.branch_name()
        if wt_path and branch and not wt_path.exists():
            # Worktree already removed — clear state.
            state.cleanup()

    merged = _find_merged_worktrees(root)
    for wt_path, branch in merged:
        _cleanup_worktree(root, wt_path, branch)

    _cleanup_orphan_branches(root)

    subprocess.run(
        ["git", "worktree", "prune"],
        capture_output=True, text=True, cwd=str(root),
    )

    _purge_expired_archives(root)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Never block
