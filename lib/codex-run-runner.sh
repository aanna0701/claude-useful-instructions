#!/usr/bin/env bash

resolve_groups() {
  local feat_ids=("$@")
  local manifest="work/dispatch.json"

  if [ -f "$manifest" ] && command -v jq &>/dev/null; then
    local num_groups
    num_groups=$(jq '(.parallel_groups // []) | length' "$manifest" 2>/dev/null || echo 0)

    if [ "$num_groups" -gt 0 ]; then
      for ((g=0; g<num_groups; g++)); do
        local group_items=()
        while IFS= read -r item; do
          for fid in "${feat_ids[@]}"; do
            if [[ "$item" == "$fid"* || "$fid" == "$item"* ]]; then
              group_items+=("$fid")
              break
            fi
          done
        done < <(jq -r "(.parallel_groups[$g] // []) | if type == \"array\" then .[] else (.items // [])[] end" "$manifest")

        if [ ${#group_items[@]} -gt 0 ]; then
          echo "${group_items[*]}"
        fi
      done
      return 0
    fi
  fi

  echo "${feat_ids[*]}"
}

monitor_group() {
  local -n group_ids_ref=$1
  local -n pids_ref=$2
  local -n log_files_ref=$3
  local -n last_log_mtime_ref=$4
  local -n last_status_ref=$5
  local -n last_progress_epoch_ref=$6
  local -n exit_codes_ref=$7
  local -n waited_pids_ref=$8
  local stall_timeout="$9"

  local all_done=false
  while ! $all_done; do
    sleep 10
    all_done=true
    local done_count=0

    for fid in "${group_ids_ref[@]}"; do
      local pid="${pids_ref[$fid]:-}"
      local wdir
      wdir=$(resolve_work_dir "$fid")
      local slug
      slug=$(resolve_work_item_slug "$wdir")
      local status_source
      status_source=$(resolve_status_source_dir "$fid" "$wdir")
      local status
      status=$(get_item_status "$status_source")
      local now_epoch
      now_epoch=$(date +%s)
      local log_file="${log_files_ref[$fid]:-}"
      local log_mtime=0
      if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        log_mtime=$(stat -c %Y "$log_file" 2>/dev/null || echo 0)
      fi
      if [ "$log_mtime" -gt "${last_log_mtime_ref[$fid]:-0}" ] || [ "$status" != "${last_status_ref[$fid]:-}" ]; then
        last_log_mtime_ref["$fid"]="$log_mtime"
        last_status_ref["$fid"]="$status"
        last_progress_epoch_ref["$fid"]="$now_epoch"
      fi

      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        local stalled_for=$((now_epoch - ${last_progress_epoch_ref[$fid]:-$now_epoch}))
        if [ "$stall_timeout" -gt 0 ] && [ "$stalled_for" -ge "$stall_timeout" ]; then
          local stall_message="Runner detected no status or log progress for $stalled_for seconds and stopped the Codex process. Inspect $log_file, then rerun codex-run.sh."
          echo "  $slug stalled for ${stalled_for}s; terminating pid $pid"
          kill "$pid" 2>/dev/null || true
          sleep 1
          kill -9 "$pid" 2>/dev/null || true
          mark_status_blocked_everywhere "$fid" "$wdir" "runner-stalled" "$stall_message"
          last_status_ref["$fid"]="blocked"
          continue
        fi
        all_done=false
        printf "  %-40s %s (pid %s)\n" "$slug" "$status" "$pid"
      else
        if [ -n "$pid" ] && [ -z "${waited_pids_ref[$fid]:-}" ]; then
          if wait "$pid"; then
            exit_codes_ref["$fid"]=0
          else
            exit_codes_ref["$fid"]=$?
          fi
          waited_pids_ref["$fid"]=1
        fi
        local exit_code="${exit_codes_ref[$fid]:-?}"
        if [[ "$status" == "done" ]]; then
          ((done_count++)) || true
          printf "  %-40s ✓ done\n" "$slug"
        else
          if [ "$status" = "unknown" ]; then
            mark_status_blocked_everywhere "$fid" "$wdir" "runner-missing-status" "Codex process exited with code $exit_code before recording a final status. Inspect $log_file and update status.md before rerunning."
            status="blocked"
            last_status_ref["$fid"]="$status"
          fi
          printf "  %-40s ✗ exited (status: %s, code: %s)\n" "$slug" "$status" "$exit_code"
          ((done_count++)) || true
        fi
      fi
    done

    if ! $all_done; then
      echo "  ... ($done_count/${#group_ids_ref[@]} complete, checking again in 10s)"
      echo ""
    fi
  done
}

dispatch_group() {
  local group_ids=("$@")
  local -A pids=()
  local -A log_files=()
  local -A last_log_mtime=()
  local -A last_status=()
  local -A last_progress_epoch=()
  local -A exit_codes=()
  local -A waited_pids=()
  local stall_timeout="${CODEX_RUN_STALL_TIMEOUT_SECS:-1800}"

  mkdir -p "$LOG_DIR"

  for fid in "${group_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local slug
    slug=$(resolve_work_item_slug "$wdir")
    local log_file="$LOG_DIR/${slug}.log"
    local git_dir=""
    git_dir=$(resolve_git_dir "$fid" "$wdir")
    local prompt
    prompt=$(build_codex_prompt "$fid")
    update_status_state_everywhere "$fid" "$wdir" "in-progress" "Codex"

    if command -v codex &>/dev/null; then
      if ! preflight_target_dir "$fid" "$wdir" "$git_dir"; then
        echo "  Blocked: $slug → target preflight failed; skipping Codex spawn"
        continue
      fi
      if [ "$git_dir" != "." ] && [ -d "$git_dir" ]; then
        echo "  Spawning: $slug → $log_file (cd $git_dir)"
      else
        echo "  Spawning: $slug → $log_file"
      fi
      if [ "$git_dir" != "." ] && [ -d "$git_dir" ]; then
        codex exec --full-auto --cd "$git_dir" "$prompt" > "$log_file" 2>&1 &
      else
        codex exec --full-auto "$prompt" > "$log_file" 2>&1 &
      fi
      pids["$fid"]=$!
      log_files["$fid"]="$log_file"
      last_log_mtime["$fid"]=$(stat -c %Y "$log_file" 2>/dev/null || echo 0)
      last_status["$fid"]="in-progress"
      last_progress_epoch["$fid"]=$(date +%s)
    else
      echo "  [manual] $slug → $log_file"
      echo "$prompt" > "$log_file"
    fi
  done

  if ! command -v codex &>/dev/null; then
    return 0
  fi

  monitor_group group_ids pids log_files last_log_mtime last_status last_progress_epoch exit_codes waited_pids "$stall_timeout"
}

print_manual_dispatch_instructions() {
  local -n groups_ref=$1
  local feat_ids_label="$2"
  local num_groups=${#groups_ref[@]}

  echo ""
  echo "codex CLI not found. Run manually in separate terminals:"
  echo ""
  local gn=0
  for group_line in "${groups_ref[@]}"; do
    ((gn++)) || true
    IFS=' ' read -ra gids <<< "$group_line"
    if [ "$num_groups" -gt 1 ]; then
      echo "  # Group $gn (run in parallel):"
    fi
    for fid in "${gids[@]}"; do
      local wdir
      wdir=$(resolve_work_dir "$fid")
      echo "  codex exec --full-auto < $LOG_DIR/$(resolve_work_item_slug "$wdir").log"
    done
    if [ "$gn" -lt "$num_groups" ]; then
      echo "  # Wait for group $gn to finish before starting group $((gn+1))"
      echo ""
    fi
  done
  echo ""
  echo "After all complete, run:"
  echo "  /work-review $feat_ids_label"
}

collect_dispatch_results() {
  local -n feat_ids_ref=$1
  local -n review_ids_ref=$2
  local -n warn_ids_ref=$3
  local -n success_ref=$4
  local -n warn_ref=$5
  local -n failed_ref=$6

  for fid in "${feat_ids_ref[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local status_source
    status_source=$(resolve_status_source_dir "$fid" "$wdir")
    local status
    status=$(get_item_status "$status_source")
    if [[ "$status" == "done" ]]; then
      if verify_commits "$fid"; then
        ((success_ref++)) || true
        review_ids_ref+=("$fid")
      else
        ((warn_ref++)) || true
        warn_ids_ref+=("$fid")
        review_ids_ref+=("$fid")
      fi
    else
      ((failed_ref++)) || true
    fi
  done
}

cmd_dispatch() {
  local feat_ids=("$@")

  echo "Step 1/4: Boundary check"
  if ! boundary_check "${feat_ids[@]}"; then
    echo ""
    echo "Resolve boundary conflicts before dispatching."
    echo "To run sequentially despite conflicts: dispatch each FEAT separately."
    exit 1
  fi

  echo ""
  echo "Step 2/4: Dispatching ${#feat_ids[@]} Codex instance(s)"
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

  if ! command -v codex &>/dev/null; then
    print_manual_dispatch_instructions groups "${feat_ids[*]}"
    exit 0
  fi

  echo ""
  echo "Step 3/4: Results + Verification"
  echo "──────────────────────────────────────────────"
  local success=0 failed=0 warn=0
  local review_ids=()
  local warn_ids=()

  collect_dispatch_results feat_ids review_ids warn_ids success warn failed

  if [ ${#review_ids[@]} -gt 0 ]; then
    echo ""
    echo "Pushing branches + creating draft PRs..."
    for fid in "${review_ids[@]}"; do
      local pr_result
      pr_result=$(push_and_create_pr "$fid" 2>&1) || true
      echo "$pr_result"
    done
  fi

  echo "══════════════════════════════════════════════"
  echo "  Dispatch Complete"
  echo "  Verified: $success  Warnings: $warn  Failed: $failed"
  echo "══════════════════════════════════════════════"
  echo ""

  if [ "$warn" -gt 0 ]; then
    echo "⚠ Items with warnings (missing commits or dirty worktree):"
    for wid in "${warn_ids[@]}"; do
      echo "  - $wid"
    done
    echo ""
    echo "Fix: cd into the worktree, commit changes, then review."
    echo ""
  fi

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
