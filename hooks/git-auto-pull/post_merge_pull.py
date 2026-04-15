#!/usr/bin/env python3
"""Claude Code PostToolUse hook — auto pull after PR merge.

Fires after Bash / mcp merge_pull_request. If a PR was just merged
(via `gh pr merge` or MCP merge_pull_request), fast-forwards the main
repo worktree on the PR's base branch so subsequent work sees the
merged commits.

Safety:
- Never blocks: exit 0 on all paths.
- Skips if worktree is dirty (no auto-stash); reports to user.
- Only fast-forwards; no rebase, no merge.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

_MERGE_CMD_RE = re.compile(r"\bgh\s+pr\s+merge\b")
_MERGED_OK_RE = re.compile(r"(Merged pull request|merged|✓ Merged)", re.IGNORECASE)


def _run(args: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=30)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def _main_worktree(cwd: Path) -> Path | None:
    code, out, _ = _run(["git", "worktree", "list", "--porcelain"], cwd=cwd)
    if code != 0:
        return None
    # First "worktree <path>" line is the main repo worktree
    for line in out.splitlines():
        if line.startswith("worktree "):
            return Path(line[len("worktree "):])
    return None


def _is_dirty(path: Path) -> bool:
    code, out, _ = _run(["git", "status", "--porcelain"], cwd=path)
    return code == 0 and bool(out)


def _current_branch(path: Path) -> str:
    _, out, _ = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=path)
    return out


def _detect_base_branch(cwd: Path, command: str) -> str | None:
    # Try to read --base from the command; otherwise ask gh for repo default.
    m = re.search(r"--base[= ]([^\s]+)", command)
    if m:
        return m.group(1)
    code, out, _ = _run(
        ["gh", "repo", "view", "--json", "defaultBranchRef", "-q", ".defaultBranchRef.name"],
        cwd=cwd,
    )
    return out if code == 0 and out else None


def _emit(msg: str) -> None:
    print(json.dumps({"message": msg}), file=sys.stderr)


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
    tool_response = payload.get("tool_response", {}) or {}

    # Accept both: Bash `gh pr merge`, and MCP merge_pull_request.
    merged = False
    command = ""
    if tool_name == "Bash":
        command = tool_input.get("command", "")
        if not _MERGE_CMD_RE.search(command):
            return
        stdout = tool_response.get("stdout", "") or ""
        stderr = tool_response.get("stderr", "") or ""
        if _MERGED_OK_RE.search(stdout) or _MERGED_OK_RE.search(stderr):
            merged = True
    elif "merge_pull_request" in tool_name:
        # MCP tools typically succeed silently; treat no-error as success.
        if not tool_response.get("isError"):
            merged = True
    else:
        return

    if not merged:
        return

    cwd = Path.cwd()
    main_wt = _main_worktree(cwd)
    if main_wt is None:
        return

    base = _detect_base_branch(cwd, command)
    if not base:
        return

    if _is_dirty(main_wt):
        _emit(
            f"PR merged. Skipped auto-pull on {main_wt} — working tree is dirty. "
            f"Run `git pull --ff-only` there manually after committing/stashing."
        )
        return

    code, _, err = _run(["git", "fetch", "origin", base], cwd=main_wt)
    if code != 0:
        _emit(f"PR merged. Auto-fetch failed on {main_wt}: {err}")
        return

    current = _current_branch(main_wt)
    if current == base:
        code, out, err = _run(["git", "merge", "--ff-only", f"origin/{base}"], cwd=main_wt)
        if code == 0:
            if "Already up to date" not in out:
                _emit(f"PR merged → fast-forwarded {main_wt} ({base})")
        else:
            _emit(f"PR merged. Auto fast-forward failed on {main_wt}: {err}")
    else:
        # Update the base branch ref without checking it out.
        code, _, err = _run(
            ["git", "fetch", "origin", f"{base}:{base}"], cwd=main_wt
        )
        if code == 0:
            _emit(f"PR merged → updated {base} ref on {main_wt} (current branch: {current})")
        else:
            _emit(f"PR merged. Could not update {base} on {main_wt}: {err}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Never block
