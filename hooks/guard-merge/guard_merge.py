#!/usr/bin/env python3
"""Claude Code PreToolUse hook — gate merges behind a review label.

Policy:
  - A merge attempt is allowed only if the target PR carries a label of the
    form `reviewed:passed:{short_sha}` whose sha matches the PR's current
    HEAD commit. This ties the approval to a specific revision — any new
    push invalidates the gate.

Caught operations:
  - gh pr merge [N] [...]
  - gh api ... pulls/<N>/merge        (REST merge endpoint — any verb)
  - mcp__*__merge_pull_request        (GitHub MCP merge tool)
  - git merge <protected>             (protected = hub branches, static)
  - git push [remote] <protected>

Exit codes:
  0 — allow
  2 — block with explanation (stderr)
"""
from __future__ import annotations

import json
import re
import subprocess
import sys

# Static hub branches — direct `git merge` / `git push` to these is always blocked.
# The review-label gate below applies on top of this, for PR-based merges.
PROTECTED_BRANCHES = {"main", "develop", "research"}
_PROTECTED_PAT = "|".join(PROTECTED_BRANCHES)

REVIEW_LABEL_PREFIX = "reviewed:passed:"

_GIT_MERGE_RE = re.compile(
    r"\bgit\s+merge\b.*?\s+(?:" + _PROTECTED_PAT + r")(?:\s|$)"
)
_GIT_PUSH_RE = re.compile(
    r"\bgit\s+push\b.*?(?:HEAD:)?(?:" + _PROTECTED_PAT + r")(?:\s|$)"
)
_GH_PR_MERGE_RE = re.compile(r"\bgh\s+pr\s+merge\b(?:\s+(\d+))?")
_GH_API_MERGE_RE = re.compile(r"\bgh\s+api\b[^\n]*?/pulls/(\d+)/merge\b")


def _block(msg: str) -> None:
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(2)


def _gh_json(args: list[str]) -> dict | list | None:
    try:
        out = subprocess.run(
            ["gh", *args], capture_output=True, text=True, timeout=10
        )
        if out.returncode != 0:
            return None
        return json.loads(out.stdout)
    except (subprocess.SubprocessError, json.JSONDecodeError, FileNotFoundError):
        return None


def _resolve_pr_number(explicit: str | None) -> int | None:
    if explicit:
        try:
            return int(explicit)
        except ValueError:
            return None
    # Fallback: current branch → PR
    data = _gh_json(["pr", "view", "--json", "number"])
    if isinstance(data, dict) and isinstance(data.get("number"), int):
        return data["number"]
    return None


def _check_review_gate(pr_number: int, origin: str) -> None:
    """Block merge if PR lacks `reviewed:passed:{head_sha}` label."""
    data = _gh_json(
        ["pr", "view", str(pr_number), "--json", "labels,headRefOid,url"]
    )
    if not isinstance(data, dict):
        _block(
            f"BLOCKED: PR #{pr_number} 상태 조회 실패 ({origin}).\n"
            f"gh 인증 / 네트워크를 확인하거나 수동으로 리뷰 게이트 통과 후 재시도하세요."
        )

    head_sha: str = data.get("headRefOid", "") or ""
    short = head_sha[:7]
    labels = {
        lbl.get("name", "") for lbl in data.get("labels", []) if isinstance(lbl, dict)
    }
    expected = f"{REVIEW_LABEL_PREFIX}{short}"

    stale = sorted(
        lbl for lbl in labels
        if lbl.startswith(REVIEW_LABEL_PREFIX) and lbl != expected
    )

    if expected in labels:
        return  # ✅ approved for this exact sha

    stale_note = (
        f"\n  이전 리뷰 라벨({', '.join(stale)})은 현재 HEAD({short})와 불일치 "
        f"→ 재푸시 후 `/work-review` 재실행 필요."
        if stale else ""
    )
    _block(
        f"BLOCKED: PR #{pr_number} 머지 시도가 차단되었습니다 ({origin}).\n"
        f"  현재 HEAD: {short}\n"
        f"  필요한 라벨: `{expected}`\n"
        f"  PR URL: {data.get('url', '')}{stale_note}\n"
        f"`/work-review {pr_number}` 를 실행해 리뷰 통과 후 재시도하세요."
    )


def _check_bash(command: str) -> None:
    if _GIT_MERGE_RE.search(command):
        _block(
            "BLOCKED: 보호된 브랜치(main / develop / research)로의 `git merge` 차단.\n"
            "PR을 통해 `/work-review` 게이트 통과 후 머지하세요."
        )

    if _GIT_PUSH_RE.search(command):
        _block(
            "BLOCKED: 보호된 브랜치(main / develop / research)로의 직접 push 차단.\n"
            "PR을 통해 머지하세요."
        )

    m = _GH_API_MERGE_RE.search(command)
    if m:
        pr = _resolve_pr_number(m.group(1))
        if pr is None:
            _block(
                "BLOCKED: `gh api .../pulls/N/merge` — PR 번호 해석 실패.\n"
                "리뷰 게이트 통과 여부를 확인할 수 없어 차단합니다."
            )
        _check_review_gate(pr, "gh api pulls/N/merge")
        return

    m = _GH_PR_MERGE_RE.search(command)
    if m:
        pr = _resolve_pr_number(m.group(1))
        if pr is None:
            _block(
                "BLOCKED: `gh pr merge` — PR 번호 해석 실패 (현재 브랜치에 열린 PR 없음).\n"
                "리뷰 게이트 통과 여부를 확인할 수 없어 차단합니다."
            )
        _check_review_gate(pr, "gh pr merge")
        return


def _check_mcp_merge(tool_name: str, tool_input: dict) -> None:
    pr = tool_input.get("pull_number") or tool_input.get("pullNumber")
    try:
        pr_int = int(pr) if pr is not None else None
    except (TypeError, ValueError):
        pr_int = None

    if pr_int is None:
        owner = tool_input.get("owner", "?")
        repo = tool_input.get("repo", "?")
        _block(
            f"BLOCKED: MCP merge_pull_request — PR 번호 누락 ({owner}/{repo}).\n"
            f"리뷰 게이트 통과 여부를 확인할 수 없어 차단합니다."
        )
    _check_review_gate(pr_int, f"MCP {tool_name}")


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
