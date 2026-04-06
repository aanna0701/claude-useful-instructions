#!/bin/bash
# auto_pr.sh — Stop hook: auto push + issue + PR for guard-trunk worktrees
# Runs on session end. If a guard-trunk worktree has unpushed commits,
# creates a GitHub issue and PR automatically.
#
# Works even if the worktree directory was already removed during the session
# (e.g. after merge) — falls back to checking the branch from the main repo.
#
# Marker format (2 lines):
#   line 1: worktree directory path
#   line 2: branch name
#
# Depends on: gh CLI (authenticated), git
# Cost: 0 Claude tokens (shell + gh only)

set -euo pipefail

MARKER="/tmp/.claude-guard-trunk-${PPID}"

# ── 1. Check for active marker ──────────────────────────────────────────
if [[ ! -f "$MARKER" ]]; then
    exit 0
fi

WT_DIR=$(sed -n '1p' "$MARKER")
WT_BRANCH=$(sed -n '2p' "$MARKER")

# Need at least a branch name to proceed
if [[ -z "$WT_BRANCH" ]]; then
    # Legacy marker (path only) — try to extract branch from worktree
    if [[ -d "$WT_DIR" ]] && git -C "$WT_DIR" rev-parse --git-dir &>/dev/null; then
        WT_BRANCH=$(git -C "$WT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi
    if [[ -z "$WT_BRANCH" ]]; then
        rm -f "$MARKER"
        exit 0
    fi
fi

# ── 2. Determine working directory (worktree or main repo) ─────────────
if [[ -d "$WT_DIR" ]] && git -C "$WT_DIR" rev-parse --git-dir &>/dev/null; then
    WORK_DIR="$WT_DIR"
else
    # Worktree gone — find the main repo from the worktree path pattern
    # Pattern: {main_repo}-tmp-guard-{ppid}
    MAIN_REPO=$(echo "$WT_DIR" | sed 's/-tmp-guard-[0-9]*$//')
    if [[ ! -d "$MAIN_REPO/.git" ]]; then
        rm -f "$MARKER"
        exit 0
    fi
    WORK_DIR="$MAIN_REPO"

    # Verify the branch still exists
    if ! git -C "$WORK_DIR" rev-parse --verify "$WT_BRANCH" &>/dev/null; then
        rm -f "$MARKER"
        exit 0
    fi
fi

cd "$WORK_DIR"

# ── 3. Resolve base branch from branch-map.yaml ────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH_MAP="${REPO_ROOT}/.claude/branch-map.yaml"
BASE_BRANCH="main"

if [[ -f "$BRANCH_MAP" ]]; then
    DMT=$(grep -E '^\s*default_merge_target:\s*' "$BRANCH_MAP" | head -1 | sed 's/.*:\s*//' | tr -d '[:space:]')
    if [[ -n "$DMT" ]]; then
        BASE_BRANCH="$DMT"
    fi
fi

# ── 4. Check for commits ahead of base ──────────────────────────────────
AHEAD=$(git rev-list --count "${BASE_BRANCH}..${WT_BRANCH}" 2>/dev/null || echo "0")
if [[ "$AHEAD" -eq 0 ]]; then
    # No new commits — nothing to PR
    rm -f "$MARKER"
    exit 0
fi

# ── 5. Collect commit info ──────────────────────────────────────────────
OWNER_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)

if [[ -z "$OWNER_REPO" ]]; then
    echo "[auto_pr] Could not determine GitHub repo. Skipping." >&2
    exit 0
fi

COMMIT_LOG=$(git log --format="- %s" "${BASE_BRANCH}..${WT_BRANCH}" 2>/dev/null)
FIRST_COMMIT=$(git log --format="%s" "${BASE_BRANCH}..${WT_BRANCH}" | tail -1)
FILE_STATS=$(git diff --stat "${BASE_BRANCH}..${WT_BRANCH}" 2>/dev/null | tail -1)

# Derive a title
if [[ "$AHEAD" -eq 1 ]]; then
    TITLE="$FIRST_COMMIT"
else
    TYPE=$(echo "$FIRST_COMMIT" | grep -oE '^(feat|fix|refactor|docs|test|chore|perf|ci)' || echo "chore")
    TITLE="${TYPE}: ${WT_BRANCH##*/} (${AHEAD} commits)"
fi

# ── 6. Push branch ─────────────────────────────────────────────────────
git push -u origin "$WT_BRANCH" 2>/dev/null || {
    echo "[auto_pr] Push failed. Skipping issue/PR creation." >&2
    rm -f "$MARKER"
    exit 0
}

# ── 7. Create GitHub issue ──────────────────────────────────────────────
ISSUE_BODY=$(cat <<EOF
Auto-generated from Claude Code session.

## Changes
${COMMIT_LOG}

## Stats
${FILE_STATS}

_Branch: \`${WT_BRANCH}\`_
EOF
)

ISSUE_URL=$(gh issue create \
    --repo "$OWNER_REPO" \
    --title "$TITLE" \
    --body "$ISSUE_BODY" \
    2>/dev/null) || {
    echo "[auto_pr] Issue creation failed. Creating PR without issue link." >&2
    ISSUE_URL=""
}

ISSUE_NUM=""
if [[ -n "$ISSUE_URL" ]]; then
    ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$' || true)
fi

# ── 8. Create Pull Request ─────────────────────────────────────────────
PR_BODY=$(cat <<EOF
## Summary
${COMMIT_LOG}

## Stats
${FILE_STATS}
EOF
)

if [[ -n "$ISSUE_NUM" ]]; then
    PR_BODY="${PR_BODY}

Closes #${ISSUE_NUM}"
fi

PR_URL=$(gh pr create \
    --repo "$OWNER_REPO" \
    --base "$BASE_BRANCH" \
    --head "$WT_BRANCH" \
    --title "$TITLE" \
    --body "$PR_BODY" \
    2>/dev/null) || {
    echo "[auto_pr] PR creation failed." >&2
    rm -f "$MARKER"
    exit 0
}

echo "[auto_pr] Created: ${ISSUE_URL:-no issue} / ${PR_URL}" >&2

# ── 9. Cleanup marker ──────────────────────────────────────────────────
rm -f "$MARKER"
