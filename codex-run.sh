#!/usr/bin/env bash
# codex-run.sh — Boundary check + parallel Codex dispatch + monitoring
# Run with --help for usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="work/.dispatch-logs"
CODEX_RUN_UV_GROUPS="${CODEX_RUN_UV_GROUPS:-host dev}"

source "$SCRIPT_DIR/lib/codex-run-work.sh"
source "$SCRIPT_DIR/lib/codex-run-git.sh"
source "$SCRIPT_DIR/lib/codex-run-boundary.sh"
source "$SCRIPT_DIR/lib/codex-run-runner.sh"

case "${1:-}" in
  --check|-c)
    shift
    boundary_check "$@"
    ;;
  --status|-s)
    cmd_status
    ;;
  --help|-h)
    cat << 'HELP'
Usage: codex-run.sh [options] FEAT-ID [FEAT-ID ...]

  FEAT-001 FEAT-002 ...    Boundary check + parallel dispatch + monitor
  --check, -c  FEAT-IDs    Boundary check only (dry run)
  --status, -s             Show all work item statuses
  --help, -h               Show this help

Flow:
  1. Validates contract boundary overlaps
  2. Auto-syncs each worktree from its contract parent branch
  3. Spawns parallel codex exec processes + monitors
  4. Verifies commits on completion
  5. Pushes branches + creates draft PRs
  6. Prints /work-review command for Claude
HELP
    ;;
  -*)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  *)
    if [ $# -eq 0 ]; then
      echo "Usage: codex-run.sh FEAT-ID [FEAT-ID ...]" >&2
      echo "       codex-run.sh --check FEAT-ID [FEAT-ID ...]" >&2
      echo "       codex-run.sh --status" >&2
      exit 1
    fi
    cmd_dispatch "$@"
    ;;
esac
