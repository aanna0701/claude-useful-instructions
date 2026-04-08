#!/bin/bash
# auto_pr.sh — Stop hook: cleanup + fallback push/PR for worktrees
#
# Primarily a cleanup hook. The auto-pr-commit PostToolUse hook handles
# PR creation at first commit. This hook catches edge cases where the
# PostToolUse hook didn't fire (e.g., non-Claude-Code sessions).
#
# State directory: /tmp/.claude-worktree-state-{PPID}/
#   worktree.path  — worktree directory path
#   branch.name    — worktree branch name
#   base.branch    — base branch for PR
#   issue.number   — GitHub issue number (optional)
#   pr.number      — PR number (set by auto-pr-commit hook)
#   repo.slug      — owner/repo string
#
# Depends on: gh CLI (authenticated), git

set -euo pipefail

STATE_DIR="/tmp/.claude-worktree-state-${PPID}"
OLD_MARKER="/tmp/.claude-guard-trunk-${PPID}"

# ── 1. Check for state (new format or old marker) ──────────────────────
if [[ -d "$STATE_DIR" ]]; then
    WT_DIR=$(cat "$STATE_DIR/worktree.path" 2>/dev/null || true)
    WT_BRANCH=$(cat "$STATE_DIR/branch.name" 2>/dev/null || true)
    BASE_BRANCH=$(cat "$STATE_DIR/base.branch" 2>/dev/null || true)
    PR_NUM=$(cat "$STATE_DIR/pr.number" 2>/dev/null || true)
elif [[ -f "$OLD_MARKER" ]]; then
    # Legacy marker migration
    WT_DIR=$(sed -n '1p' "$OLD_MARKER")
    WT_BRANCH=$(sed -n '2p' "$OLD_MARKER")
    BASE_BRANCH=""
    PR_NUM=""
else
    exit 0
fi

# Need at least a branch name
if [[ -z "$WT_BRANCH" ]]; then
    if [[ -d "$WT_DIR" ]] && git -C "$WT_DIR" rev-parse --git-dir &>/dev/null; then
        WT_BRANCH=$(git -C "$WT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi
    if [[ -z "$WT_BRANCH" ]]; then
        rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
        exit 0
    fi
fi

# ── 2. If PR already created (by auto-pr-commit hook), just cleanup ────
if [[ -n "$PR_NUM" ]]; then
    rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
    exit 0
fi

# ── 3. Determine working directory ─────────────────────────────────────
if [[ -d "$WT_DIR" ]] && git -C "$WT_DIR" rev-parse --git-dir &>/dev/null; then
    WORK_DIR="$WT_DIR"
else
    # Worktree gone — find main repo
    # Pattern: {project}-feature-* or {project}-tmp-guard-{ppid}
    MAIN_REPO=$(echo "$WT_DIR" | sed -E 's/-(feature-[a-z0-9-]+|tmp-guard-[0-9]+)$//')
    if [[ ! -d "$MAIN_REPO/.git" ]]; then
        rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
        exit 0
    fi
    WORK_DIR="$MAIN_REPO"
    if ! git -C "$WORK_DIR" rev-parse --verify "$WT_BRANCH" &>/dev/null; then
        rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
        exit 0
    fi
fi

# ── 4. Resolve base branch ─────────────────────────────────────────────
if [[ -z "$BASE_BRANCH" ]]; then
    # Try common candidates
    for candidate in research develop main master; do
        if git -C "$WORK_DIR" rev-parse --verify "$candidate" &>/dev/null; then
            BASE_BRANCH="$candidate"
            break
        fi
    done
    BASE_BRANCH="${BASE_BRANCH:-main}"
fi

# ── 5. Check for commits ahead of base ─────────────────────────────────
AHEAD=$(git -C "$WORK_DIR" rev-list --count "${BASE_BRANCH}..${WT_BRANCH}" 2>/dev/null || echo "0")
if [[ "$AHEAD" -eq 0 ]]; then
    rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
    exit 0
fi

# ── 6. Fallback: push + create PR ──────────────────────────────────────
OWNER_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
if [[ -z "$OWNER_REPO" ]]; then
    echo "[auto_pr] Could not determine GitHub repo. Skipping." >&2
    rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
    exit 0
fi

COMMIT_LOG=$(git -C "$WORK_DIR" log --format="- %s" "${BASE_BRANCH}..${WT_BRANCH}" 2>/dev/null)
FIRST_COMMIT=$(git -C "$WORK_DIR" log --format="%s" "${BASE_BRANCH}..${WT_BRANCH}" | tail -1)

if [[ "$AHEAD" -eq 1 ]]; then
    TITLE="$FIRST_COMMIT"
else
    TYPE=$(echo "$FIRST_COMMIT" | grep -oE '^(feat|fix|refactor|docs|test|chore|perf|ci)' || echo "chore")
    TITLE="${TYPE}: ${WT_BRANCH##*/} (${AHEAD} commits)"
fi

git -C "$WORK_DIR" push -u origin "$WT_BRANCH" 2>/dev/null || {
    echo "[auto_pr] Push failed. Skipping PR creation." >&2
    rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
    exit 0
}

ISSUE_NUM=$(cat "$STATE_DIR/issue.number" 2>/dev/null || true)

PR_BODY="## Summary
${COMMIT_LOG}"

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
    rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
    exit 0
}

echo "[auto_pr] Fallback PR created: ${PR_URL}" >&2

# ── 7. Cleanup ─────────────────────────────────────────────────────────
rm -rf "$STATE_DIR" "$OLD_MARKER" 2>/dev/null
