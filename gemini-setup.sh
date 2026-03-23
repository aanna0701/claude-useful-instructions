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
#   4. Auto-registers MCP config in .claude/settings.local.json (skips if already present)

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

# ── Register MCP config in settings.local.json ───────────────────────────

SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"
mkdir -p "$PROJECT_DIR/.claude"

MCP_PERMISSIONS=(
  "mcp__gemini_review__gemini_summarize_design_pack"
  "mcp__gemini_review__gemini_derive_contract"
  "mcp__gemini_review__gemini_audit_implementation"
  "mcp__gemini_review__gemini_compare_diffs"
  "mcp__gemini_review__gemini_draft_release_notes"
)

python3 << PYEOF
import json, sys, os

settings_file = "$SETTINGS_FILE"
mcp_dst = "$MCP_DST"
permissions = $(printf '%s\n' "${MCP_PERMISSIONS[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")

# Load existing settings or start fresh
settings = {}
if os.path.isfile(settings_file):
    with open(settings_file, "r") as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            settings = {}

# Check if gemini-review is already registered
mcp_servers = settings.get("mcpServers", {})
if "gemini-review" in mcp_servers:
    print("MCP config: gemini-review already registered — skipped.")
    sys.exit(0)

# Add MCP server config
mcp_servers["gemini-review"] = {
    "command": "uv",
    "args": ["run", "--directory", mcp_dst, "python", "server.py"],
    "env": {"GEMINI_API_KEY": "\${GEMINI_API_KEY}"}
}
settings["mcpServers"] = mcp_servers

# Add permissions (merge with existing, deduplicate)
existing_allow = settings.get("permissions", {}).get("allow", [])
merged_allow = list(dict.fromkeys(existing_allow + permissions))
settings.setdefault("permissions", {})["allow"] = merged_allow

# Write back
with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"MCP config: registered gemini-review → {settings_file}")
PYEOF

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────────────"
echo "Gemini MCP setup complete."
echo ""
echo "Optional: Set GEMINI_MODEL to override default (gemini-2.5-pro)."
echo "  export GEMINI_MODEL='gemini-2.5-flash'  # cheaper, faster"
