#!/usr/bin/env bash
# codex-dispatch.sh — Boundary check + parallel Codex execution + completion monitoring
#
# Usage:
#   bash codex-dispatch.sh FEAT-001 FEAT-002 FEAT-003   # Run all in parallel
#   bash codex-dispatch.sh --check FEAT-001 FEAT-002     # Boundary check only (dry run)
#   bash codex-dispatch.sh --status                      # Show all work item statuses
#
# What it does:
#   1. Validates boundary overlaps between contracts
#   2. Auto-links work/ across worktrees (if applicable)
#   3. Spawns parallel `codex exec` processes for each FEAT
#   4. Monitors status.md until all items are done
#   5. Prints the /work-review command for Claude
#
# Human touches the workflow exactly twice:
#   After /work-plan:  bash codex-dispatch.sh FEAT-001 FEAT-002
#   After completion:  /work-review FEAT-001 FEAT-002

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="work/.dispatch-logs"

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
  grep -oP '\| Status \| \K[^|]+' "$wdir/status.md" 2>/dev/null | tr -d ' ' || echo "unknown"
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

  cat << EOF
You are implementing work item $slug. Read these files in order:

1. $wdir/brief.md — understand objective and scope
2. $wdir/contract.md — understand boundaries, interfaces, invariants
3. $wdir/checklist.md — understand verification requirements

Rules:
- IMPLEMENT only what the contract specifies
- MODIFY only files listed in "Allowed Modifications"
- NEVER touch files in "Forbidden Zones"
- WRITE tests per "Test Requirements"
- COMMIT with: feat($feat_id): description
- UPDATE $wdir/status.md after each milestone
- When DONE: set Status to "done" in $wdir/status.md

Begin implementation.
EOF
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

  # Step 3: Spawn Codex processes
  echo ""
  echo "Step 3/4: Dispatching ${#feat_ids[@]} Codex instance(s)"
  echo "──────────────────────────────────────────────"

  mkdir -p "$LOG_DIR"
  local -A pids=()

  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local slug
    slug=$(basename "$wdir")
    local log_file="$LOG_DIR/${slug}.log"
    local prompt
    prompt=$(build_codex_prompt "$fid")

    # Initialize status
    sed -i 's/| Status | .*/| Status | in-progress |/' "$wdir/status.md"
    sed -i 's/| Agent | .*/| Agent | Codex |/' "$wdir/status.md"
    sed -i "s/^updated: .*/updated: $(date '+%Y-%m-%d %H:%M')/" "$wdir/status.md"

    if command -v codex &>/dev/null; then
      echo "  Spawning: $slug → $log_file"
      codex exec --sandbox workspace-write -a auto-edit "$prompt" > "$log_file" 2>&1 &
      pids["$fid"]=$!
    else
      echo "  [codex CLI not found] Manual execution required for $slug"
      echo "  Prompt saved to: $log_file"
      echo "$prompt" > "$log_file"
    fi
  done

  echo "──────────────────────────────────────────────"

  # If no codex CLI, print manual instructions and exit
  if ! command -v codex &>/dev/null; then
    echo ""
    echo "codex CLI not found. Run manually in separate terminals:"
    echo ""
    for fid in "${feat_ids[@]}"; do
      local wdir
      wdir=$(resolve_work_dir "$fid")
      echo "  codex exec --sandbox workspace-write -a auto-edit < $LOG_DIR/$(basename "$wdir").log"
    done
    echo ""
    echo "After all complete, run:"
    echo "  /work-review ${feat_ids[*]}"
    exit 0
  fi

  # Step 4: Monitor completion
  echo ""
  echo "Step 4/4: Monitoring progress"
  echo "──────────────────────────────────────────────"

  local all_done=false
  while ! $all_done; do
    sleep 10
    all_done=true
    local done_count=0
    local total=${#feat_ids[@]}

    for fid in "${feat_ids[@]}"; do
      local pid="${pids[$fid]:-}"
      local wdir
      wdir=$(resolve_work_dir "$fid")
      local slug
      slug=$(basename "$wdir")
      local status
      status=$(get_item_status "$wdir")

      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        # Process still running
        all_done=false
        printf "  %-40s %s (pid %s)\n" "$slug" "$status" "$pid"
      else
        # Process exited
        if [[ "$status" == "done" ]]; then
          ((done_count++)) || true
          printf "  %-40s ✓ done\n" "$slug"
        else
          printf "  %-40s ✗ exited (status: %s)\n" "$slug" "$status"
          ((done_count++)) || true  # Count as done even if failed
        fi
      fi
    done

    if ! $all_done; then
      echo "  ... ($done_count/$total complete, checking again in 10s)"
      echo ""
    fi
  done

  echo "──────────────────────────────────────────────"
  echo ""

  # Collect results
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
  --help|-h)
    cat << 'HELP'
Usage: codex-dispatch.sh [options] FEAT-ID [FEAT-ID ...]

  FEAT-001 FEAT-002 ...    Boundary check + parallel dispatch + monitor
  --check, -c  FEAT-IDs    Boundary check only (dry run)
  --status, -s              Show all work item statuses
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
      echo "Usage: codex-dispatch.sh FEAT-ID [FEAT-ID ...]" >&2
      echo "       codex-dispatch.sh --check FEAT-ID [FEAT-ID ...]" >&2
      echo "       codex-dispatch.sh --status" >&2
      exit 1
    fi
    cmd_dispatch "$@"
    ;;
esac
