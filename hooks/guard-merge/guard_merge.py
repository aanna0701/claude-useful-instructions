#!/usr/bin/env python3
"""Claude Code PreToolUse hook — block merges into protected branches.

Blocks any attempt (via Bash or GitHub MCP tool) to merge into:
  main, develop, research

Caught operations:
  - git merge <protected>
  - git push [remote] <protected>  (including HEAD:<protected>)
  - gh pr merge  (target branch unknown from command; block entirely)
  - mcp__*__merge_pull_request  (GitHub MCP merge tool)

Exit codes:
  0 — allow
  2 — block with explanation (stderr)
"""
from __future__ import annotations

import json
import re
import sys

PROTECTED_BRANCHES = {"main", "develop", "research"}
_PROTECTED_PAT = "|".join(PROTECTED_BRANCHES)

# git merge <protected>
_GIT_MERGE_RE = re.compile(
    r"\bgit\s+merge\b.*?\s+(?:" + _PROTECTED_PAT + r")(?:\s|$)"
)
# git push [remote] <protected>  or  git push origin HEAD:<protected>
_GIT_PUSH_RE = re.compile(
    r"\bgit\s+push\b.*?(?:HEAD:)?(?:" + _PROTECTED_PAT + r")(?:\s|$)"
)
# gh pr merge (any form — target branch is PR's base, not in the command)
_GH_PR_MERGE_RE = re.compile(r"\bgh\s+pr\s+merge\b")


def _block(msg: str) -> None:
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(2)


def _matched_branch(pattern: re.Pattern, command: str) -> str:
    """Return the first protected branch name found in command, or empty string."""
    m = pattern.search(command)
    if not m:
        return ""
    for b in PROTECTED_BRANCHES:
        if re.search(r"(?:HEAD:)?" + re.escape(b) + r"(?:\s|$)", command):
            return b
    return ""


def _check_bash(command: str) -> None:
    if _GIT_MERGE_RE.search(command):
        branch = _matched_branch(_GIT_MERGE_RE, command) or "<protected>"
        _block(
            f"BLOCKED: `git merge {branch}` 실행이 차단되었습니다.\n"
            f"'{branch}'는 보호된 브랜치입니다 (main / develop / research).\n"
            f"직접 머지할 수 없습니다 — PR을 통해 팀 리뷰 후 머지하세요."
        )

    if _GIT_PUSH_RE.search(command):
        branch = _matched_branch(_GIT_PUSH_RE, command) or "<protected>"
        _block(
            f"BLOCKED: `{branch}` 브랜치에 직접 push가 차단되었습니다.\n"
            f"'{branch}'는 보호된 브랜치입니다 (main / develop / research).\n"
            f"PR을 통해 머지하세요."
        )

    if _GH_PR_MERGE_RE.search(command):
        _block(
            "BLOCKED: `gh pr merge` 명령이 차단되었습니다.\n"
            "보호된 브랜치(main / develop / research)로의 자동 머지는 허용되지 않습니다.\n"
            "GitHub 웹 UI에서 직접 머지하거나 팀 승인 후 진행하세요."
        )


def _check_mcp_merge(tool_name: str, tool_input: dict) -> None:
    owner = tool_input.get("owner", "")
    repo = tool_input.get("repo", "")
    pr = tool_input.get("pull_number", tool_input.get("pullNumber", "?"))
    _block(
        f"BLOCKED: GitHub MCP merge_pull_request 호출이 차단되었습니다.\n"
        f"  PR #{pr}  ({owner}/{repo})\n"
        f"보호된 브랜치(main / develop / research)로의 자동 머지는 허용되지 않습니다.\n"
        f"GitHub 웹 UI에서 직접 머지하거나 팀 승인 후 진행하세요."
    )


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return

    tool_name: str = payload.get("tool_name", "")
    tool_input: dict = payload.get("tool_input", {})

    if tool_name == "Bash":
        command = tool_input.get("command", "")
        if command:
            _check_bash(command)
        return

    if "merge_pull_request" in tool_name:
        _check_mcp_merge(tool_name, tool_input)
        return


if __name__ == "__main__":
    main()
