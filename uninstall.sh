#!/usr/bin/env bash
# uninstall.sh — Remove Claude settings (commands, agents, rules, skills) installed by install.sh
# Usage: ./uninstall.sh [TARGET_DIR]
#   TARGET_DIR: project root to uninstall from (default: ~, i.e. ~/.claude)

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Accept optional project root as first argument (default: $HOME)
if [ -n "$1" ]; then
  PROJECT_ROOT="$(cd "$1" 2>/dev/null && pwd || echo "$1")"
else
  PROJECT_ROOT="$HOME"
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo "Uninstalling Claude settings from $CLAUDE_DIR"
echo "────────────────────────────────────────────────────────"

removed=0

# commands/ — remove only files that exist in this repo
if [ -d "$REPO_DIR/commands" ]; then
  find "$REPO_DIR/commands" -name "*.md" | while read -r file; do
    relative="${file#$REPO_DIR/}"
    target="$CLAUDE_DIR/$relative"
    if [ -f "$target" ]; then
      rm -v "$target"
      removed=$((removed + 1))
    fi
  done
  # Remove empty subdirectories (deepest first)
  find "$CLAUDE_DIR/commands" -type d -empty -delete 2>/dev/null || true
fi

# agents/ — remove only files that exist in this repo
if [ -d "$REPO_DIR/agents" ]; then
  for file in "$REPO_DIR/agents/"*.md; do
    target="$CLAUDE_DIR/agents/$(basename "$file")"
    if [ -f "$target" ]; then
      rm -v "$target"
      removed=$((removed + 1))
    fi
  done
  [ -d "$CLAUDE_DIR/agents" ] && rmdir "$CLAUDE_DIR/agents" 2>/dev/null || true
fi

# rules/ — remove only files that exist in this repo
if [ -d "$REPO_DIR/rules" ]; then
  find "$REPO_DIR/rules" -name "*.md" | while read -r file; do
    relative="${file#$REPO_DIR/}"
    target="$CLAUDE_DIR/$relative"
    if [ -f "$target" ]; then
      rm -v "$target"
      removed=$((removed + 1))
    fi
  done
  find "$CLAUDE_DIR/rules" -type d -empty -delete 2>/dev/null || true
fi

# skills/ — remove only skill folders that exist in this repo
if [ -d "$REPO_DIR/skills" ]; then
  for skill_dir in "$REPO_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    target="$CLAUDE_DIR/skills/$skill_name"
    if [ -d "$target" ]; then
      rm -rv "$target"
      removed=$((removed + 1))
    fi
  done
  [ -d "$CLAUDE_DIR/skills" ] && rmdir "$CLAUDE_DIR/skills" 2>/dev/null || true
fi

echo "────────────────────────────────────────────────────────"
echo "Done. Removed $removed item(s)."
