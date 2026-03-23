#!/usr/bin/env bash
# codex-implement.sh — Read a work item and print structured implementation context
#
# Usage: bash codex-implement.sh <FEAT-ID>
#   FEAT-ID: Work item ID (e.g., FEAT-001 or FEAT-001-jwt-auth-middleware)
#
# Codex runs this script to load the work item context, then implements accordingly.
# The script reads brief → contract → checklist, initializes status, and prints
# a structured implementation plan for the agent to follow.

set -e

FEAT_ID="${1:?Usage: bash codex-implement.sh <FEAT-ID>}"

# ── Resolve work item directory ───────────────────────────────────────────
WORK_DIR=""
for dir in work/items/${FEAT_ID}*/; do
  [ -d "$dir" ] && WORK_DIR="$dir" && break
done

if [ -z "$WORK_DIR" ] || [ ! -d "$WORK_DIR" ]; then
  echo "ERROR: Work item not found: $FEAT_ID" >&2
  echo "Available items:" >&2
  ls work/items/ 2>/dev/null || echo "  (none — work/items/ does not exist)" >&2
  exit 1
fi

# Remove trailing slash for clean paths
WORK_DIR="${WORK_DIR%/}"
FEAT_SLUG="$(basename "$WORK_DIR")"

# ── Verify required files ─────────────────────────────────────────────────
MISSING=()
for f in brief.md contract.md checklist.md status.md; do
  [ -f "$WORK_DIR/$f" ] || MISSING+=("$f")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: Missing files in $WORK_DIR: ${MISSING[*]}" >&2
  exit 1
fi

# ── Initialize status ────────────────────────────────────────────────────
# Update status.md to in-progress
sed -i 's/| Status | .*/| Status | in-progress |/' "$WORK_DIR/status.md"
sed -i 's/| Agent | .*/| Agent | Codex |/' "$WORK_DIR/status.md"
sed -i "s/| Branch | .*/| Branch | feat\/$FEAT_SLUG |/" "$WORK_DIR/status.md"
sed -i "s/^updated: .*/updated: $(date '+%Y-%m-%d %H:%M')/" "$WORK_DIR/status.md"

# ── Print structured context ─────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  WORK ITEM: $FEAT_SLUG"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "━━━ BRIEF ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$WORK_DIR/brief.md"
echo ""

echo "━━━ CONTRACT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$WORK_DIR/contract.md"
echo ""

echo "━━━ CHECKLIST ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$WORK_DIR/checklist.md"
echo ""

echo "━━━ INSTRUCTIONS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'INSTRUCTIONS'
You are now implementing this work item. Follow these rules:

1. CREATE branch: git checkout -b feat/FEAT_SLUG
2. IMPLEMENT only what the contract specifies
3. MODIFY only files listed in "Allowed Modifications"
4. NEVER touch files in "Forbidden Zones"
5. WRITE tests per "Test Requirements"
6. COMMIT with: feat(FEAT-NNN): description
7. UPDATE status.md after each milestone:
   - Check off completed items in Progress
   - List changed files with descriptions
8. If AMBIGUOUS: write to status.md Ambiguities, choose minimal interpretation
9. When DONE: set status to "done" in status.md

STATUS FILE: WORK_DIR/status.md
INSTRUCTIONS

# Replace placeholders with actual values
echo ""
echo "Branch: feat/$FEAT_SLUG"
echo "Status file: $WORK_DIR/status.md"
echo ""
echo "Status initialized: in-progress | Agent: Codex"
echo "Begin implementation."
