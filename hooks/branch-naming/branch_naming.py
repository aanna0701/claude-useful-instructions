#!/usr/bin/env python3
"""Claude Code PreToolUse hook — enforce branch naming convention.

All new branches must follow the pattern:
  feature-{slug}           (for feat type)
  feature-{type}-{slug}    (for fix, refac, docs, perf, test, chore, audit)
  feature-adhoc-{stamp}    (auto-created by guard-branch)

Blocks Bash commands that create branches with non-conforming names:
  git branch <name>
  git checkout -b <name>
  git worktree add -b <name>
  git switch -c <name>

Exit codes:
  0 — allow
  2 — block with error message
"""
from __future__ import annotations

import json
import re
import sys


# Allowed branch patterns
BRANCH_PATTERN = re.compile(
    r"^feature-"                          # Must start with feature-
    r"("
    r"[a-z0-9][a-z0-9-]*"                # feature-{slug} (feat type)
    r"|(?:fix|refac|docs|perf|test|chore|audit|adhoc)-[a-z0-9][a-z0-9-]*"
    r")$"
)

# Special branches that are always allowed
EXEMPT_BRANCHES = {"main", "master", "develop", "research", "staging"}

# Patterns to detect branch creation in commands
BRANCH_CREATE_PATTERNS = [
    # git branch <name> [base]
    re.compile(r"git\s+branch\s+(?!-[dDm])(\S+)"),
    # git checkout -b <name>
    re.compile(r"git\s+checkout\s+-b\s+(\S+)"),
    # git switch -c <name>
    re.compile(r"git\s+switch\s+-c\s+(\S+)"),
    # git worktree add -b <name> <path>
    re.compile(r"git\s+worktree\s+add\s+-b\s+(\S+)"),
]


def _extract_new_branch(command: str) -> str | None:
    """Extract the new branch name from a git command, or None if not a branch creation."""
    for pattern in BRANCH_CREATE_PATTERNS:
        m = pattern.search(command)
        if m:
            return m.group(1)
    return None


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return

    tool_input = payload.get("tool_input", {})
    command = tool_input.get("command", "")

    if not command:
        return

    branch_name = _extract_new_branch(command)
    if not branch_name:
        return

    # Exempt special branches
    if branch_name in EXEMPT_BRANCHES:
        return

    # Exempt worktree-internal branches (Claude Code's own worktree mechanism)
    if branch_name.startswith("worktree-"):
        return

    # Validate naming
    if BRANCH_PATTERN.match(branch_name):
        return

    msg = (
        f"BLOCKED: Branch name '{branch_name}' does not follow the naming convention.\n"
        f"\n"
        f"Required pattern: feature-{{slug}}\n"
        f"  feat type:    feature-{{slug}}              e.g. feature-user-auth\n"
        f"  fix type:     feature-fix-{{slug}}           e.g. feature-fix-login-crash\n"
        f"  refactor:     feature-refac-{{slug}}         e.g. feature-refac-db-schema\n"
        f"  docs:         feature-docs-{{slug}}          e.g. feature-docs-api-guide\n"
        f"  perf:         feature-perf-{{slug}}          e.g. feature-perf-query-cache\n"
        f"  test:         feature-test-{{slug}}          e.g. feature-test-auth-flow\n"
        f"  chore:        feature-chore-{{slug}}         e.g. feature-chore-deps-update\n"
        f"  audit:        feature-audit-{{slug}}         e.g. feature-audit-security\n"
        f"\n"
        f"Please rename your branch to follow this pattern."
    )
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
