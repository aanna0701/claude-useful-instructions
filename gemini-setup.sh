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
#   4. Prints Claude Code MCP configuration to add to settings

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

# ── Validate API key ─────────────────────────────────────────────────────

if [ -z "$GEMINI_API_KEY" ]; then
  echo "WARNING: GEMINI_API_KEY is not set."
  echo ""
  echo "To set it, add to your shell profile (~/.bashrc or ~/.zshrc):"
  echo "  export GEMINI_API_KEY='your-api-key-here'"
  echo ""
  echo "Get a key at: https://aistudio.google.com/apikey"
  echo ""
  echo "Continuing setup without API key validation..."
  echo ""
fi

# ── Copy MCP server ──────────────────────────────────────────────────────

MCP_SRC="$SCRIPT_DIR/mcp/gemini-review"
MCP_DST="$PROJECT_DIR/mcp/gemini-review"

if [ ! -d "$MCP_SRC" ]; then
  echo "ERROR: MCP server source not found: $MCP_SRC" >&2
  exit 1
fi

mkdir -p "$MCP_DST"
cp -rv "$MCP_SRC"/* "$MCP_DST/"
echo "Copied MCP server → $MCP_DST/"

# ── Install Python dependencies ──────────────────────────────────────────

echo ""
echo "Installing Python dependencies..."
cd "$MCP_DST"
uv sync 2>/dev/null || uv pip install -r <(echo "mcp>=1.0
google-generativeai>=0.8") --python python3
cd "$PROJECT_DIR"
echo "Dependencies installed."

# ── Print configuration ──────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────────────"
echo "Gemini MCP setup complete."
echo ""
echo "Add this to your Claude Code settings:"
echo ""
echo "  For project-level: $PROJECT_DIR/.claude/settings.local.json"
echo "  For global:        ~/.claude/settings.json"
echo ""
cat << EOF
{
  "mcpServers": {
    "gemini-review": {
      "command": "uv",
      "args": ["run", "--directory", "$MCP_DST", "python", "server.py"],
      "env": {
        "GEMINI_API_KEY": "\${GEMINI_API_KEY}"
      }
    }
  },
  "permissions": {
    "allow": [
      "mcp__gemini_review__gemini_summarize_design_pack",
      "mcp__gemini_review__gemini_derive_contract",
      "mcp__gemini_review__gemini_audit_implementation",
      "mcp__gemini_review__gemini_compare_diffs",
      "mcp__gemini_review__gemini_draft_release_notes"
    ]
  }
}
EOF
echo ""
echo "Optional: Set GEMINI_MODEL to override default (gemini-2.5-pro)."
echo "  export GEMINI_MODEL='gemini-2.5-flash'  # cheaper, faster"
