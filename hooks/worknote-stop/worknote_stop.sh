#!/bin/bash
# worknote-stop — write git activity to per-repo daily worknote on session end
# Cost: 0 tokens (shell only, no Claude invocation)
# Output: ~/.claude/worknote/YYYY-MM-DD/<repo>.md (one file per repo per day)

set -euo pipefail

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
WORKNOTE_DIR="${HOME}/.claude/worknote/${DATE}"

# Detect repo name (fallback to cwd basename)
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$PWD")
WORKNOTE="${WORKNOTE_DIR}/${REPO}.md"

# Collect today's commits (since 6 AM local)
COMMITS=$(git log --since="06:00" --format="- %h %s" 2>/dev/null || true)

# Collect uncommitted changes
STAGED=$(git diff --cached --stat 2>/dev/null || true)
UNSTAGED=$(git diff --stat 2>/dev/null || true)

# Skip if nothing to record
if [[ -z "${COMMITS}" && -z "${STAGED}" && -z "${UNSTAGED}" ]]; then
    exit 0
fi

mkdir -p "${WORKNOTE_DIR}"

# Overwrite per-repo file (always latest snapshot, no duplicates)
{
    echo "## ${REPO}"
    echo ""
    echo "_Last updated: ${TIME}_"

    if [[ -n "${COMMITS}" ]]; then
        echo ""
        echo "### Commits"
        echo "${COMMITS}"
    fi

    if [[ -n "${STAGED}" ]]; then
        echo ""
        echo "### Staged"
        echo "${STAGED}"
    fi

    if [[ -n "${UNSTAGED}" ]]; then
        echo ""
        echo "### Changed"
        echo "${UNSTAGED}"
    fi
} > "${WORKNOTE}"

# ── Retention: delete local worknotes older than 30 days ──────────────────
RETENTION_DAYS=30
find "${HOME}/.claude/worknote" -maxdepth 1 -type d -name "20*" -mtime +${RETENTION_DAYS} \
    -exec rm -rf {} + 2>/dev/null || true
