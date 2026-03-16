#!/usr/bin/env bash
# install.sh — Copy Claude settings (commands, agents, rules, skills) into <TARGET>/.claude/
# Usage: ./install.sh [TARGET_DIR]
#   TARGET_DIR: project root to install into (default: ~, i.e. ~/.claude)

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Accept optional project root as first argument (default: $HOME)
if [ -n "$1" ]; then
  PROJECT_ROOT="$(cd "$1" 2>/dev/null && pwd || echo "$1")"
else
  PROJECT_ROOT="$HOME"
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo "Installing Claude settings from $REPO_DIR → $CLAUDE_DIR"
echo "────────────────────────────────────────────────────────"

# commands/ (including subdirectories like references/)
if [ -d "$REPO_DIR/commands" ]; then
  find "$REPO_DIR/commands" -type d | while read -r dir; do
    relative="${dir#$REPO_DIR/}"
    mkdir -p "$CLAUDE_DIR/$relative"
  done
  find "$REPO_DIR/commands" -name "*.md" | while read -r file; do
    relative="${file#$REPO_DIR/}"
    cp -v "$file" "$CLAUDE_DIR/$relative"
  done
fi

# agents/
if [ -d "$REPO_DIR/agents" ]; then
  mkdir -p "$CLAUDE_DIR/agents"
  cp -v "$REPO_DIR/agents/"*.md "$CLAUDE_DIR/agents/"
fi

# rules/
if [ -d "$REPO_DIR/rules" ]; then
  find "$REPO_DIR/rules" -type d | while read -r dir; do
    relative="${dir#$REPO_DIR/}"
    mkdir -p "$CLAUDE_DIR/$relative"
  done
  find "$REPO_DIR/rules" -name "*.md" | while read -r file; do
    relative="${file#$REPO_DIR/}"
    cp -v "$file" "$CLAUDE_DIR/$relative"
  done
fi

# skills/ (copy entire folder structure per skill)
if [ -d "$REPO_DIR/skills" ]; then
  for skill_dir in "$REPO_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    target="$CLAUDE_DIR/skills/$skill_name"
    mkdir -p "$target"
    # Preserve subdirectory structure (references/, scripts/, assets/)
    find "$skill_dir" -type d | while read -r dir; do
      relative="${dir#$skill_dir}"
      [ -n "$relative" ] && mkdir -p "$target/$relative"
    done
    find "$skill_dir" -type f | while read -r file; do
      relative="${file#$skill_dir}"
      cp -v "$file" "$target/$relative"
    done
  done
fi

echo "────────────────────────────────────────────────────────"
echo "Done. Claude settings applied."
