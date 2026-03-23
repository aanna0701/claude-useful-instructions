#!/usr/bin/env bash
# codex-dispatch.sh — Dispatch multiple work items to Codex with boundary validation
#
# Usage:
#   bash codex-dispatch.sh FEAT-001 FEAT-002 FEAT-003   # Check + dispatch all
#   bash codex-dispatch.sh --check FEAT-001 FEAT-002     # Boundary check only (dry run)
#   bash codex-dispatch.sh --status                      # Show all open work items
#   bash codex-dispatch.sh --from-manifest               # Dispatch from work/dispatch.json
#
# For each FEAT, validates boundary overlaps between contracts, then prints
# parallel-safe dispatch commands or runs codex-implement.sh directly.

set -euo pipefail

# ─── Helpers ──────────────────────────────────────────────────────────────────

resolve_work_dir() {
  local feat_id="$1"
  for dir in work/items/${feat_id}*/; do
    [ -d "$dir" ] && echo "${dir%/}" && return 0
  done
  return 1
}

# Extract "Allowed Modifications" paths from a contract.md
# Returns one path per line (trimmed, without leading "- ")
extract_allowed() {
  local contract="$1"
  local in_section=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+Allowed[[:space:]]+Modifications ]]; then
      in_section=true
      continue
    fi
    if $in_section; then
      # Stop at next section header
      [[ "$line" =~ ^### ]] && break
      [[ "$line" =~ ^## ]] && break
      # Extract list items
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
        local path="${BASH_REMATCH[1]}"
        # Strip trailing comments/descriptions after " — " or " - "
        path="${path%% — *}"
        path="${path%% - *}"
        # Trim whitespace
        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        [ -n "$path" ] && echo "$path"
      fi
    fi
  done < "$contract"
}

# Check if two paths overlap (one contains the other, or exact match)
paths_overlap() {
  local a="$1" b="$2"
  # Exact match
  [[ "$a" == "$b" ]] && return 0
  # a is parent of b (a ends with /, b starts with a)
  [[ "$a" == */ && "$b" == "$a"* ]] && return 0
  # b is parent of a
  [[ "$b" == */ && "$a" == "$b"* ]] && return 0
  # a is parent of b (a without trailing /)
  [[ "$b" == "$a/"* ]] && return 0
  [[ "$a" == "$b/"* ]] && return 0
  return 1
}

# ─── Commands ─────────────────────────────────────────────────────────────────

cmd_status() {
  echo "Open Work Items"
  echo "──────────────────────────────────────────────"
  local count=0
  for dir in work/items/FEAT-*/; do
    [ -d "$dir" ] || continue
    local slug
    slug=$(basename "$dir")
    local status="unknown"
    if [ -f "$dir/status.md" ]; then
      status=$(grep -oP '\| Status \| \K[^|]+' "$dir/status.md" 2>/dev/null | tr -d ' ' || echo "unknown")
    fi
    printf "  %-40s %s\n" "$slug" "$status"
    ((count++)) || true
  done
  if [ "$count" -eq 0 ]; then
    echo "  (no work items found)"
  fi
  echo "──────────────────────────────────────────────"
}

cmd_check() {
  local feat_ids=("$@")
  local -A feat_dirs=()
  local -A feat_paths=()

  # Resolve directories and extract boundaries
  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid") || { echo "ERROR: Work item not found: $fid" >&2; exit 1; }
    feat_dirs["$fid"]="$wdir"

    local contract="$wdir/contract.md"
    [ -f "$contract" ] || { echo "ERROR: No contract.md in $wdir" >&2; exit 1; }

    local paths_str=""
    while IFS= read -r p; do
      paths_str="${paths_str:+$paths_str|}$p"
    done < <(extract_allowed "$contract")
    feat_paths["$fid"]="$paths_str"
  done

  # Check pairwise overlaps
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
        # Join with newline delimiter to preserve multi-word entries
        local joined=""
        for of in "${overlap_files[@]}"; do
          joined="${joined:+$joined
}$of"
        done
        conflicts["$fi|$fj"]="$joined"
      fi
    done
  done

  # Print boundary matrix
  echo ""
  echo "Boundary Check"
  echo "──────────────────────────────────────────────"

  # Header
  printf "%-16s" ""
  for fid in "${feat_ids[@]}"; do
    printf "%-16s" "$fid"
  done
  echo ""

  for fi in "${feat_ids[@]}"; do
    printf "%-16s" "$fi"
    for fj in "${feat_ids[@]}"; do
      if [ "$fi" = "$fj" ]; then
        printf "%-16s" "—"
      else
        local key="$fi|$fj"
        local key_rev="$fj|$fi"
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
    echo ""
    echo "Conflicting items must run sequentially, not in parallel."
    return 1
  else
    echo ""
    echo "✓ All boundaries independent — safe for parallel dispatch"
    return 0
  fi
}

cmd_dispatch() {
  local feat_ids=("$@")

  # Run boundary check first
  if ! cmd_check "${feat_ids[@]}"; then
    echo ""
    echo "──────────────────────────────────────────────"
    echo "Resolve boundary conflicts before dispatching."
    echo "To dispatch sequentially despite conflicts, run each FEAT separately."
    exit 1
  fi

  echo ""
  echo "Dispatch Commands"
  echo "──────────────────────────────────────────────"
  echo "Run these in separate terminals for parallel execution:"
  echo ""

  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local slug
    slug=$(basename "$wdir")
    echo "  # Terminal — $slug"
    echo "  bash codex-implement.sh $fid"
    echo ""
  done

  echo "──────────────────────────────────────────────"
  echo "Dispatching ${#feat_ids[@]} work items."
  echo "Monitor progress: bash codex-dispatch.sh --status"
}

cmd_from_manifest() {
  local manifest="work/dispatch.json"
  [ -f "$manifest" ] || { echo "ERROR: $manifest not found" >&2; exit 1; }

  # Parse parallel_groups from JSON (minimal jq-free parsing)
  if command -v jq &>/dev/null; then
    local num_groups
    num_groups=$(jq '.parallel_groups | length' "$manifest")

    for ((g=0; g<num_groups; g++)); do
      local group_items
      group_items=$(jq -r ".parallel_groups[$g][]" "$manifest")

      echo ""
      echo "═══ Group $((g+1)) of $num_groups ═══"

      local ids=()
      while IFS= read -r item; do
        ids+=("$item")
      done <<< "$group_items"

      cmd_dispatch "${ids[@]}"

      if [ $((g+1)) -lt "$num_groups" ]; then
        echo ""
        echo "⏳ Wait for Group $((g+1)) to complete before starting Group $((g+2))."
      fi
    done
  else
    echo "ERROR: jq is required for --from-manifest. Install with: apt install jq" >&2
    echo "Alternative: specify FEAT IDs directly: bash codex-dispatch.sh FEAT-001 FEAT-002" >&2
    exit 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

CHECK_ONLY=false
FROM_MANIFEST=false

case "${1:-}" in
  --check|-c)
    CHECK_ONLY=true
    shift
    ;;
  --status|-s)
    cmd_status
    exit 0
    ;;
  --from-manifest|-m)
    cmd_from_manifest
    exit 0
    ;;
  --help|-h)
    echo "Usage: codex-dispatch.sh [options] FEAT-ID [FEAT-ID ...]"
    echo ""
    echo "Commands:"
    echo "  FEAT-001 FEAT-002 ...    Check boundaries + dispatch"
    echo "  --check, -c  FEAT-IDs   Boundary check only (dry run)"
    echo "  --status, -s             Show all open work items"
    echo "  --from-manifest, -m      Dispatch from work/dispatch.json"
    echo "  --help, -h               Show this help"
    exit 0
    ;;
esac

if [ $# -eq 0 ]; then
  echo "Usage: codex-dispatch.sh [--check] FEAT-ID [FEAT-ID ...]" >&2
  echo "       codex-dispatch.sh --status" >&2
  echo "       codex-dispatch.sh --from-manifest" >&2
  exit 1
fi

FEAT_IDS=("$@")

if $CHECK_ONLY; then
  cmd_check "${FEAT_IDS[@]}"
else
  cmd_dispatch "${FEAT_IDS[@]}"
fi
