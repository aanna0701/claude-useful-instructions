#!/usr/bin/env bash
# install.sh — Claude 설정을 ~/.claude/ 에 적용

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude settings from $REPO_DIR → $CLAUDE_DIR"
echo "────────────────────────────────────────────────────────"

# commands/
if [ -d "$REPO_DIR/commands" ]; then
  mkdir -p "$CLAUDE_DIR/commands"
  cp -v "$REPO_DIR/commands/"*.md "$CLAUDE_DIR/commands/"
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
