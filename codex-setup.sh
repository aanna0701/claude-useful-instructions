#!/usr/bin/env bash
# codex-setup.sh — Set up Codex integration for Claude-Codex collaboration
#
# Usage: bash codex-setup.sh [PROJECT_DIR]
#   PROJECT_DIR: project root (default: current directory)
#
# What it does:
#   1. Copies AGENTS.md to project root (backs up existing)
#   2. Copies codex-implement.sh to project root
#   3. Creates work/items/ directory structure
#
# Run this inside a Codex session or manually to initialize the Codex side
# of the Claude-Codex collaboration workflow.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd || echo "$PROJECT_DIR")"

echo "Codex Setup: $PROJECT_DIR"
echo "────────────────────────────────────────────────────────"

# ── Install AGENTS.md ─────────────────────────────────────────────────────
AGENTS_SRC="$SCRIPT_DIR/templates/codex/AGENTS.md"
AGENTS_DST="$PROJECT_DIR/AGENTS.md"

if [ ! -f "$AGENTS_SRC" ]; then
  echo "ERROR: Template not found: $AGENTS_SRC" >&2
  echo "Run this script from the claude-useful-instructions repo directory." >&2
  exit 1
fi

if [ -f "$AGENTS_DST" ]; then
  BACKUP="$AGENTS_DST.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing AGENTS.md → $(basename "$BACKUP")"
  cp "$AGENTS_DST" "$BACKUP"
fi

cp -v "$AGENTS_SRC" "$AGENTS_DST"
chmod 644 "$AGENTS_DST"

# ── Install codex-implement.sh ─────────────────────────────────────────────
IMPL_SRC="$SCRIPT_DIR/codex-implement.sh"
IMPL_DST="$PROJECT_DIR/codex-implement.sh"

if [ -f "$IMPL_SRC" ]; then
  cp -v "$IMPL_SRC" "$IMPL_DST"
  chmod +x "$IMPL_DST"
else
  echo "WARNING: codex-implement.sh not found in repo, skipping." >&2
fi

# ── Create work directory ─────────────────────────────────────────────────
WORK_DIR="$PROJECT_DIR/work/items"
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p "$WORK_DIR"
  touch "$WORK_DIR/.gitkeep"
  echo "Created $WORK_DIR/"
else
  echo "work/items/ already exists, skipping."
fi

# ── Summary ───────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────"
echo "Codex setup complete."
echo ""
echo "Installed:"
echo "  AGENTS.md             → $AGENTS_DST"
echo "  codex-implement.sh    → $IMPL_DST"
echo "  work/items/            → $WORK_DIR/"
echo ""
echo "Usage:"
echo "  bash codex-implement.sh FEAT-001    # Load work item and start implementing"
echo ""
echo "Use Claude's /work-plan command to create work items for Codex."
