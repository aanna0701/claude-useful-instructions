#!/usr/bin/env bash
# gemini-setup.sh — Set up Gemini MCP server for Claude-Codex-Gemini collaboration
#
# Usage: bash gemini-setup.sh [PROJECT_DIR]
#   PROJECT_DIR: project root (default: current directory)
#
# What it does:
#   1. Installs Python dependencies via uv
#   2. Validates GEMINI_API_KEY is set
#   3. Copies MCP server to project
#   4. Registers MCP server via `claude mcp add` (user scope → ~/.claude.json)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd || echo "$PROJECT_DIR")"

echo "Gemini MCP Setup: $PROJECT_DIR"
echo "────────────────────────────────────────────────────────"

# ── Check prerequisites ───────────────────────────────────────────────────

if ! command -v uv &>/dev/null; then
  echo "ERROR: 'uv' is required but not found." >&2
  echo "Install: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "ERROR: 'python3' is required but not found." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI is required but not found." >&2
  echo "Install: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi

# ── Validate API key ─────────────────────────────────────────────────────

if [ -z "$GEMINI_API_KEY" ]; then
  echo "GEMINI_API_KEY is not set in current shell."
  echo ""
  echo "Get a key at: https://aistudio.google.com/apikey"
  echo ""
  read -rp "Enter your Gemini API key: " GEMINI_API_KEY
  if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: API key is required." >&2
    exit 1
  fi
  echo ""
fi

# ── Copy MCP server ──────────────────────────────────────────────────────

MCP_SRC="$SCRIPT_DIR/mcp/gemini-review"
MCP_DST="$PROJECT_DIR/mcp/gemini-review"

# Resolve real paths to detect self-copy (e.g., running from project dir)
MCP_SRC_REAL="$(realpath "$MCP_SRC" 2>/dev/null || echo "$MCP_SRC")"
MCP_DST_REAL="$(realpath "$MCP_DST" 2>/dev/null || echo "$MCP_DST")"

if [ ! -d "$MCP_SRC" ]; then
  echo "ERROR: MCP server source not found: $MCP_SRC" >&2
  exit 1
fi

if [ "$MCP_SRC_REAL" = "$MCP_DST_REAL" ]; then
  echo "MCP server already in place — skipped copy."
else
  mkdir -p "$MCP_DST"
  cp -rv "$MCP_SRC"/* "$MCP_DST/"
  echo "Copied MCP server → $MCP_DST/"
fi

# ── Install Python dependencies ──────────────────────────────────────────

echo ""
echo "Installing Python dependencies..."
cd "$MCP_DST"
uv sync 2>/dev/null || uv pip install -r <(echo "mcp>=1.0
google-genai>=1.0") --python python3
cd "$PROJECT_DIR"
echo "Dependencies installed."

# ── Register MCP server via claude CLI ────────────────────────────────────

# Remove existing registration to allow re-registration (update API key etc.)
claude mcp remove -s user gemini-review 2>/dev/null || true

# Register with user scope (writes to ~/.claude.json, works across all projects/worktrees)
claude mcp add -s user \
  -e "GEMINI_API_KEY=$GEMINI_API_KEY" \
  -- gemini-review \
  "$(command -v uv)" run --directory "$MCP_DST" python server.py

echo "MCP server registered (user scope → ~/.claude.json)"
echo "  API key: ${GEMINI_API_KEY:0:10}...${GEMINI_API_KEY: -4}"

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────────────"
echo "Gemini MCP setup complete."
echo ""
echo "Optional: Set GEMINI_MODEL to override default (gemini-2.5-flash)."
echo "  export GEMINI_MODEL='gemini-2.5-pro'  # deeper reasoning"
