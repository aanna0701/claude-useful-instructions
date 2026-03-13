#!/usr/bin/env bash
# install.sh — Copy Claude settings (commands, agents, rules) into <TARGET>/.claude/
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

# commands/
if [ -d "$REPO_DIR/commands" ]; then
  mkdir -p "$CLAUDE_DIR/commands"
  cp -v "$REPO_DIR/commands/"*.md "$CLAUDE_DIR/commands/"
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

echo "────────────────────────────────────────────────────────"
echo "Done. Claude settings applied."
