#!/usr/bin/env bash

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
  fi

  echo "✓ All boundaries independent — safe for parallel dispatch"
  return 0
}
