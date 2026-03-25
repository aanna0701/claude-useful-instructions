#!/usr/bin/env bash
# codex-run.sh — Boundary check + parallel Codex dispatch + monitoring
# Run with --help for usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="work/.dispatch-logs"
SLACK_HOOKS_DIR="$HOME/.claude/hooks"

# ─── Slack notification ───────────────────────────────────────────────────────

notify_slack() {
  local message="$1"

  if [ ! -f "$SLACK_HOOKS_DIR/slack_common.py" ]; then
    if [ "${CODEX_RUN_SLACK_DEBUG:-0}" = "1" ]; then
      echo "[codex-run] Slack helper missing: $SLACK_HOOKS_DIR/slack_common.py" >&2
    fi
    return 0
  fi

  local err_file
  err_file="$(mktemp)"

  if ! SLACK_MSG="$message" python3 - <<'PY' 2>"$err_file"
import os
import sys

hooks_dir = os.path.join(os.environ.get("HOME", ""), ".claude", "hooks")
sys.path.insert(0, hooks_dir)

from slack_common import load_config, send_slack  # type: ignore

token, channel = load_config()
if not token or not channel:
    raise RuntimeError("Slack config missing: ~/.claude/hooks/slack_config.json")

send_slack(token, channel, os.environ["SLACK_MSG"], "codex-run")
PY
  then
    if [ "${CODEX_RUN_SLACK_DEBUG:-0}" = "1" ]; then
      echo "[codex-run] Slack send failed:" >&2
      sed -n '1,40p' "$err_file" >&2
    fi
  elif [ -s "$err_file" ] && [ "${CODEX_RUN_SLACK_DEBUG:-0}" = "1" ]; then
    echo "[codex-run] Slack send output:" >&2
    sed -n '1,40p' "$err_file" >&2
  fi

  rm -f "$err_file"
}

cmd_notify_test() {
  local test_text="🧪 *Codex Run Test*
• Host: $(hostname)
• Repo: $(basename "$PWD")
• Path: $PWD
• Time: $(date '+%Y-%m-%d %H:%M:%S')"

  echo "Sending Slack test notification..."
  notify_slack "$test_text"
  echo "Slack test notification attempted."
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

resolve_work_dir() {
  local feat_id="$1"
  for dir in work/items/${feat_id}*/; do
    [ -d "$dir" ] && echo "${dir%/}" && return 0
  done
  return 1
}

extract_allowed() {
  local contract="$1"
  local in_section=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+Allowed[[:space:]]+Modifications ]]; then
      in_section=true
      continue
    fi
    if $in_section; then
      [[ "$line" =~ ^### ]] && break
      [[ "$line" =~ ^## ]] && break
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
        local path="${BASH_REMATCH[1]}"
        path="${path%% — *}"
        path="${path%% - *}"
        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        [ -n "$path" ] && echo "$path"
      fi
    fi
  done < "$contract"
}

paths_overlap() {
  local a="$1" b="$2"
  [[ "$a" == "$b" ]] && return 0
  [[ "$a" == */ && "$b" == "$a"* ]] && return 0
  [[ "$b" == */ && "$a" == "$b"* ]] && return 0
  [[ "$b" == "$a/"* ]] && return 0
  [[ "$a" == "$b/"* ]] && return 0
  return 1
}

get_item_status() {
  local wdir="$1"
  python3 - "$wdir/status.md" <<'PY' 2>/dev/null || echo "unknown"
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

for line in text.splitlines():
    # Table format: | Status | value |
    match = re.match(r'^\|\s*Status\s*\|\s*([^|]+?)\s*\|$', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)
    # Heading format: ## Current Status: value
    match = re.match(r'^##\s*Current\s+Status:\s*(\S+)', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)

print("unknown")
PY
}

# ─── Boundary Check ──────────────────────────────────────────────────────────

boundary_check() {
  local feat_ids=("$@")
  local -A feat_paths=()

  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid") || { echo "ERROR: Work item not found: $fid" >&2; exit 1; }
    local contract="$wdir/contract.md"
    [ -f "$contract" ] || { echo "ERROR: No contract.md in $wdir" >&2; exit 1; }

    local paths_str=""
    while IFS= read -r p; do
      paths_str="${paths_str:+$paths_str|}$p"
    done < <(extract_allowed "$contract")
    feat_paths["$fid"]="$paths_str"
  done

  local has_overlap=false
  local -A conflicts=()

  for ((i=0; i<${#feat_ids[@]}; i++)); do
    for ((j=i+1; j<${#feat_ids[@]}; j++)); do
      local fi="${feat_ids[$i]}" fj="${feat_ids[$j]}"
      local pi="${feat_paths[$fi]}" pj="${feat_paths[$fj]}"

      IFS='|' read -ra paths_i <<< "$pi"
      IFS='|' read -ra paths_j <<< "$pj"

      local overlap_files=()
      for pa in "${paths_i[@]}"; do
        [ -z "$pa" ] && continue
        for pb in "${paths_j[@]}"; do
          [ -z "$pb" ] && continue
          if paths_overlap "$pa" "$pb"; then
            if [[ "$pa" == "$pb" ]]; then
              overlap_files+=("$pa")
            else
              overlap_files+=("$pa overlaps $pb")
            fi
          fi
        done
      done

      if [ ${#overlap_files[@]} -gt 0 ]; then
        has_overlap=true
        local joined=""
        for of in "${overlap_files[@]}"; do
          joined="${joined:+$joined
}$of"
        done
        conflicts["$fi|$fj"]="$joined"
      fi
    done
  done

  # Print matrix
  echo ""
  echo "Boundary Check"
  echo "──────────────────────────────────────────────"

  printf "%-16s" ""
  for fid in "${feat_ids[@]}"; do printf "%-16s" "$fid"; done
  echo ""

  for fi in "${feat_ids[@]}"; do
    printf "%-16s" "$fi"
    for fj in "${feat_ids[@]}"; do
      if [ "$fi" = "$fj" ]; then
        printf "%-16s" "—"
      else
        local key="$fi|$fj" key_rev="$fj|$fi"
        if [ -n "${conflicts[$key]:-}" ] || [ -n "${conflicts[$key_rev]:-}" ]; then
          printf "%-16s" "⚠ OVERLAP"
        else
          printf "%-16s" "✓"
        fi
      fi
    done
    echo ""
  done
  echo "──────────────────────────────────────────────"

  if $has_overlap; then
    echo ""
    echo "⚠ Conflicts detected:"
    for key in "${!conflicts[@]}"; do
      local fi="${key%%|*}" fj="${key##*|}"
      echo "  $fi × $fj:"
      while IFS= read -r line; do
        [ -n "$line" ] && echo "    - $line"
      done <<< "${conflicts[$key]}"
    done
    return 1
  else
    echo "✓ All boundaries independent — safe for parallel dispatch"
    return 0
  fi
}

# ─── Status ───────────────────────────────────────────────────────────────────

cmd_status() {
  echo "Work Items"
  echo "──────────────────────────────────────────────"
  local count=0
  for dir in work/items/FEAT-*/; do
    [ -d "$dir" ] || continue
    local slug status
    slug=$(basename "$dir")
    status=$(get_item_status "$dir")
    printf "  %-40s %s\n" "$slug" "$status"
    ((count++)) || true
  done
  [ "$count" -eq 0 ] && echo "  (no work items found)"
  echo "──────────────────────────────────────────────"
}

# ─── Auto-link worktrees ─────────────────────────────────────────────────────

auto_link_worktrees() {
  if [ -x "$SCRIPT_DIR/link-work.sh" ]; then
    # Only run if we're in a multi-worktree setup
    local wt_count
    wt_count=$(git worktree list 2>/dev/null | wc -l)
    if [ "$wt_count" -gt 1 ]; then
      echo "Linking worktrees..."
      bash "$SCRIPT_DIR/link-work.sh" 2>/dev/null || true
    fi
  fi
}

# ─── Build Codex prompt ──────────────────────────────────────────────────────

build_codex_prompt() {
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id")
  local slug
  slug=$(basename "$wdir")
  local review_file="$wdir/review.md"
  local review_instructions=""

  if [ -f "$review_file" ]; then
    review_instructions=$(cat <<EOF
4. $wdir/review.md — latest review feedback; treat every MUST-fix item as required

Additional revise-loop rules:
- On re-dispatch, review.md is the authoritative delta over the original implementation state
- FIX every MUST-fix item from review.md before optional cleanup
- UPDATE $wdir/status.md to reflect each review item you resolved

EOF
)
  fi

  cat << EOF
You are implementing work item $slug. Read these files in order:

1. $wdir/brief.md — understand objective and scope
2. $wdir/contract.md — understand boundaries, interfaces, invariants
3. $wdir/checklist.md — understand verification requirements
${review_instructions}
Follow AGENTS.md for all implementation rules. Additionally:
- COMMIT with: feat($feat_id): description
- UPDATE $wdir/status.md after each milestone
- When DONE: set "## Current Status: done" in $wdir/status.md

Begin implementation.
EOF
}

# ─── Resolve parallel groups ──────────────────────────────────────────────────

# Read parallel_groups from work/dispatch.json if it exists, otherwise treat all as one group
resolve_groups() {
  local feat_ids=("$@")
  local manifest="work/dispatch.json"

  if [ -f "$manifest" ] && command -v jq &>/dev/null; then
    local num_groups
    num_groups=$(jq '.parallel_groups | length' "$manifest" 2>/dev/null || echo 0)

    if [ "$num_groups" -gt 0 ]; then
      # Filter groups to only include requested FEAT IDs
      for ((g=0; g<num_groups; g++)); do
        local group_items=()
        while IFS= read -r item; do
          for fid in "${feat_ids[@]}"; do
            if [[ "$item" == "$fid"* || "$fid" == "$item"* ]]; then
              group_items+=("$fid")
              break
            fi
          done
        done < <(jq -r ".parallel_groups[$g][]" "$manifest")

        if [ ${#group_items[@]} -gt 0 ]; then
          echo "${group_items[*]}"
        fi
      done
      return 0
    fi
  fi

  # Fallback: all in one group
  echo "${feat_ids[*]}"
}

# ─── Spawn and monitor a group ────────────────────────────────────────────────

dispatch_group() {
  local group_ids=("$@")
  local -A pids=()

  mkdir -p "$LOG_DIR"

  for fid in "${group_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local slug
    slug=$(basename "$wdir")
    local log_file="$LOG_DIR/${slug}.log"
    local prompt
    prompt=$(build_codex_prompt "$fid")

    # Initialize status (support both table and heading formats)
    sed -i 's/| Status | .*/| Status | in-progress |/' "$wdir/status.md"
    sed -i 's/^## Current Status: .*/## Current Status: in-progress/' "$wdir/status.md"
    sed -i 's/| Agent | .*/| Agent | Codex |/' "$wdir/status.md"
    sed -i 's/^## Agent: .*/## Agent: Codex/' "$wdir/status.md"
    sed -i "s/^updated: .*/updated: $(date '+%Y-%m-%d %H:%M')/" "$wdir/status.md"

    # Resolve target worktree: status.md → dispatch.json → contract.md
    local target_dir=""
    if [ -f "$wdir/status.md" ]; then
      target_dir=$(grep -oP '^\| Worktree Path \| \K[^\s|]+' "$wdir/status.md" || true)
      # Ignore placeholder
      [ "$target_dir" = "—" ] && target_dir=""
    fi
    if [ -z "$target_dir" ] && [ -f "work/dispatch.json" ] && command -v jq &>/dev/null; then
      target_dir=$(jq -r --arg fid "$fid" '.items[] | select(.feat_id == $fid) | .worktree_path // empty' work/dispatch.json 2>/dev/null || true)
    fi
    if [ -z "$target_dir" ] && [ -f "$wdir/contract.md" ]; then
      target_dir=$(grep -oP '^\- \*\*Path\*\*: `\K[^`]+' "$wdir/contract.md" || true)
    fi

    if command -v codex &>/dev/null; then
      echo "  Spawning: $slug → $log_file${target_dir:+ (cd $target_dir)}"
      if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
        codex exec --full-auto --cd "$target_dir" "$prompt" > "$log_file" 2>&1 &
      else
        codex exec --full-auto "$prompt" > "$log_file" 2>&1 &
      fi
      pids["$fid"]=$!
    else
      echo "  [manual] $slug → $log_file"
      echo "$prompt" > "$log_file"
    fi
  done

  # If no codex CLI, just return
  if ! command -v codex &>/dev/null; then
    return 0
  fi

  # Monitor until all done
  local all_done=false
  while ! $all_done; do
    sleep 10
    all_done=true
    local done_count=0

    for fid in "${group_ids[@]}"; do
      local pid="${pids[$fid]:-}"
      local wdir
      wdir=$(resolve_work_dir "$fid")
      local slug
      slug=$(basename "$wdir")
      local status
      status=$(get_item_status "$wdir")

      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        all_done=false
        printf "  %-40s %s (pid %s)\n" "$slug" "$status" "$pid"
      else
        if [[ "$status" == "done" ]]; then
          ((done_count++)) || true
          printf "  %-40s ✓ done\n" "$slug"
        else
          printf "  %-40s ✗ exited (status: %s)\n" "$slug" "$status"
          ((done_count++)) || true
        fi
      fi
    done

    if ! $all_done; then
      echo "  ... ($done_count/${#group_ids[@]} complete, checking again in 10s)"
      echo ""
    fi
  done
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

cmd_dispatch() {
  local feat_ids=("$@")

  # Step 1: Boundary check
  echo "Step 1/4: Boundary check"
  if ! boundary_check "${feat_ids[@]}"; then
    echo ""
    echo "Resolve boundary conflicts before dispatching."
    echo "To run sequentially despite conflicts: dispatch each FEAT separately."
    exit 1
  fi

  # Step 2: Auto-link worktrees
  echo ""
  echo "Step 2/4: Worktree links"
  auto_link_worktrees
  echo "Done."

  notify_slack "🚀 *Codex Run Start*
• Items: ${feat_ids[*]}
• Host: $(hostname)
• Repo: $(basename "$PWD")"

  # Step 3: Resolve groups and dispatch
  echo ""
  echo "Step 3/4: Dispatching ${#feat_ids[@]} Codex instance(s)"
  echo "──────────────────────────────────────────────"

  local groups=()
  while IFS= read -r group_line; do
    [ -n "$group_line" ] && groups+=("$group_line")
  done < <(resolve_groups "${feat_ids[@]}")

  local num_groups=${#groups[@]}
  local group_num=0

  for group_line in "${groups[@]}"; do
    ((group_num++)) || true
    IFS=' ' read -ra group_ids <<< "$group_line"

    if [ "$num_groups" -gt 1 ]; then
      echo ""
      echo "═══ Group $group_num/$num_groups: ${group_ids[*]} (parallel) ═══"
    fi

    dispatch_group "${group_ids[@]}"

    if [ "$group_num" -lt "$num_groups" ] && command -v codex &>/dev/null; then
      echo ""
      echo "  Group $group_num complete. Starting group $((group_num+1))..."
    fi
  done

  echo "──────────────────────────────────────────────"

  # If no codex CLI, print manual instructions
  if ! command -v codex &>/dev/null; then
    echo ""
    echo "codex CLI not found. Run manually in separate terminals:"
    echo ""
    local gn=0
    for group_line in "${groups[@]}"; do
      ((gn++)) || true
      IFS=' ' read -ra gids <<< "$group_line"
      if [ "$num_groups" -gt 1 ]; then
        echo "  # Group $gn (run in parallel):"
      fi
      for fid in "${gids[@]}"; do
        local wdir
        wdir=$(resolve_work_dir "$fid")
        echo "  codex exec --full-auto < $LOG_DIR/$(basename "$wdir").log"
      done
      if [ "$gn" -lt "$num_groups" ]; then
        echo "  # Wait for group $gn to finish before starting group $((gn+1))"
        echo ""
      fi
    done
    echo ""
    echo "After all complete, run:"
    echo "  /work-review ${feat_ids[*]}"
    exit 0
  fi

  # Step 4: Collect results
  echo ""
  echo "Step 4/4: Results"
  local success=0 failed=0
  local review_ids=()
  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local status
    status=$(get_item_status "$wdir")
    if [[ "$status" == "done" ]]; then
      ((success++)) || true
      review_ids+=("$fid")
    else
      ((failed++)) || true
    fi
  done

  # Print summary + next step
  echo "══════════════════════════════════════════════"
  echo "  Dispatch Complete"
  echo "  Success: $success  Failed: $failed"
  echo "══════════════════════════════════════════════"
  echo ""

  if [ ${#review_ids[@]} -gt 0 ]; then
    echo "Next step — paste this into Claude:"
    echo ""
    echo "  /work-review ${review_ids[*]}"
    echo ""
  fi

  if [ "$failed" -gt 0 ]; then
    echo "Check logs for failed items: ls $LOG_DIR/"
  fi

  # Slack notification
  local slack_text="🔧 *Codex Run Complete*
• Success: $success  Failed: $failed
• Items: ${feat_ids[*]}
• Host: $(hostname)"
  if [ ${#review_ids[@]} -gt 0 ]; then
    slack_text+="
• Next: \`/work-review ${review_ids[*]}\`"
  fi
  notify_slack "$slack_text"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --check|-c)
    shift
    boundary_check "$@"
    ;;
  --status|-s)
    cmd_status
    ;;
  --notify-test)
    cmd_notify_test
    ;;
  --help|-h)
    cat << 'HELP'
Usage: codex-run.sh [options] FEAT-ID [FEAT-ID ...]

  FEAT-001 FEAT-002 ...    Boundary check + parallel dispatch + monitor
  --check, -c  FEAT-IDs    Boundary check only (dry run)
  --status, -s              Show all work item statuses
  --notify-test             Send a Slack test notification
  --help, -h                Show this help

Flow:
  1. Validates contract boundary overlaps
  2. Auto-links worktrees (if applicable)
  3. Spawns parallel codex exec processes
  4. Monitors status.md until all items complete
  5. Prints /work-review command for Claude
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
