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

extract_contract_field() {
  local contract="$1"
  local field="$2"

  [ -f "$contract" ] || return 1

  python3 - "$contract" "$field" <<'PY' 2>/dev/null || true
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
field = sys.argv[2]

for line in text.splitlines():
    if not line.startswith("|"):
        continue
    parts = [part.strip() for part in line.split("|")]
    if len(parts) >= 4 and parts[1] == field:
        value = parts[2]
        if value not in {"", "Value"}:
            print(value)
            raise SystemExit(0)

match = re.search(rf'^- \*\*{re.escape(field)}\*\*: `([^`]+)`\s*$', text, re.MULTILINE)
if match:
    print(match.group(1))
PY
}

resolve_target_dir() {
  local feat_id="$1"
  local wdir="$2"
  local target_dir=""

  if [ -f "$wdir/status.md" ]; then
    target_dir=$(grep -oP '^\| Worktree Path \| \K[^\s|]+' "$wdir/status.md" || true)
    [ "$target_dir" = "—" ] && target_dir=""
  fi
  if [ -z "$target_dir" ] && [ -f "work/dispatch.json" ] && command -v jq &>/dev/null; then
    target_dir=$(jq -r --arg fid "$feat_id" '.items[] | select(.id == $fid) | .worktree_path // empty' work/dispatch.json 2>/dev/null || true)
  fi
  if [ -z "$target_dir" ] && [ -f "$wdir/contract.md" ]; then
    target_dir=$(extract_contract_field "$wdir/contract.md" "Target Worktree" || true)
    [ "$target_dir" = "—" ] && target_dir=""
  fi

  echo "$target_dir"
}

update_status_state() {
  local status_file="$1"
  local status_value="$2"
  local agent_value="$3"

  python3 - "$status_file" "$status_value" "$agent_value" <<'PY'
import re
import sys
from datetime import datetime
from pathlib import Path

path = Path(sys.argv[1])
status_value = sys.argv[2]
agent_value = sys.argv[3]
text = path.read_text(encoding="utf-8")

text = re.sub(r'^updated: .*$', f'updated: {datetime.now():%Y-%m-%d %H:%M}', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Status\s*\|\s*[^|]+?\s*\|$', f'| Status | {status_value} |', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Agent\s*\|\s*[^|]+?\s*\|$', f'| Agent | {agent_value} |', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Current\s+Status:\s*\S+.*$', f'## Current Status: {status_value}', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Agent:\s*.*$', f'## Agent: {agent_value}', text, flags=re.MULTILINE)

path.write_text(text, encoding="utf-8")
PY
}

mark_status_blocked() {
  local status_file="$1"
  local issue_value="$2"
  local blocker_text="$3"

  python3 - "$status_file" "$issue_value" "$blocker_text" <<'PY'
import re
import sys
from datetime import datetime
from pathlib import Path

path = Path(sys.argv[1])
issue_value = sys.argv[2]
blocker_text = sys.argv[3]
text = path.read_text(encoding="utf-8")

text = re.sub(r'^updated: .*$', f'updated: {datetime.now():%Y-%m-%d %H:%M}', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Status\s*\|\s*[^|]+?\s*\|$', '| Status | blocked |', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Issue\s*\|\s*[^|]+?\s*\|$', f'| Issue | {issue_value} |', text, flags=re.MULTILINE)

pattern = re.compile(r'(^## Blockers\n)(.*?)(?=\n## |\Z)', re.MULTILINE | re.DOTALL)
match = pattern.search(text)
replacement_body = f"- {blocker_text}"
if match:
    text = text[:match.start()] + match.group(1) + replacement_body + text[match.end():]

path.write_text(text, encoding="utf-8")
PY
}

sync_branch_from_parent() {
  local feat_id="$1"
  local wdir="$2"
  local git_dir="$3"

  local contract="$wdir/contract.md"
  [ -f "$contract" ] || return 0

  local parent_branch=""
  parent_branch=$(extract_contract_field "$contract" "Parent Branch" || true)
  if [ -z "$parent_branch" ] || [ "$parent_branch" = "—" ] || [[ "$parent_branch" == \[* ]]; then
    return 0
  fi

  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  local parent_ref="$parent_branch"

  echo "    [sync] checking branch freshness: $branch <- $parent_branch"

  git -C "$git_dir" fetch origin "$parent_branch" >/dev/null 2>&1 || git -C "$git_dir" fetch origin >/dev/null 2>&1 || true
  if git -C "$git_dir" show-ref --verify --quiet "refs/remotes/origin/$parent_branch"; then
    parent_ref="origin/$parent_branch"
  fi

  if git -C "$git_dir" merge-base --is-ancestor "$parent_ref" HEAD >/dev/null 2>&1; then
    echo "    [sync] already includes $parent_ref"
    return 0
  fi

  echo "    [sync] merging $parent_ref into $branch"
  if git -C "$git_dir" merge --no-edit "$parent_ref" >/dev/null 2>&1; then
    echo "    [sync] merge complete"
    return 0
  fi

  git -C "$git_dir" merge --abort >/dev/null 2>&1 || true
  mark_status_blocked "$wdir/status.md" "needs-sync" "Runner auto-sync from parent branch '$parent_branch' failed. Resolve branch sync or merge conflicts, then rerun codex-run.sh."
  echo "    [sync] merge failed; status marked blocked"
  return 1
}

# Ensure worktree has planning artifacts (copy + commit on feature branch)
sync_worktree_artifacts() {
  local feat_id="$1"
  local target_dir="$2"
  local base_repo
  base_repo="$(git rev-parse --show-toplevel)"

  [ -z "$target_dir" ] || [ ! -d "$target_dir" ] && return 0
  [ "$target_dir" = "$base_repo" ] && return 0

  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 0
  local slug
  slug=$(basename "$wdir")
  local needs_commit=false

  # Copy work item files if missing in worktree
  local wt_feat_dir="$target_dir/work/items/$slug"
  if [ ! -f "$wt_feat_dir/contract.md" ] && [ -d "$wdir" ]; then
    mkdir -p "$wt_feat_dir"
    cp "$wdir"/*.md "$wt_feat_dir/"
    git -C "$target_dir" add -f "work/items/$slug/"
    needs_commit=true
    echo "    [sync] copied work/items/$slug/"
  fi

  # Copy AGENTS.md if missing
  if [ ! -f "$target_dir/AGENTS.md" ] && [ -f "$base_repo/AGENTS.md" ]; then
    cp "$base_repo/AGENTS.md" "$target_dir/AGENTS.md"
    git -C "$target_dir" add AGENTS.md
    needs_commit=true
    echo "    [sync] copied AGENTS.md"
  fi

  # Commit seeded artifacts on the feature branch
  if $needs_commit; then
    git -C "$target_dir" commit -m "chore($slug): seed work item artifacts" || true
    echo "    [sync] committed artifacts on feature branch"
  fi
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

rescue_uncommitted() {
  # If Codex couldn't commit due to sandbox restrictions, commit on its behalf.
  # Codex sandbox blocks .git/ metadata writes (index.lock) — this is expected.
  # Codex is responsible for: implementation, verification, status.md update
  # Runner is responsible for: git add, git commit, git push
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(basename "$wdir")

  # Resolve worktree path from status.md / dispatch / contract
  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")
  local git_dir="${target_dir:-.}"

  local dirty
  dirty=$(git -C "$git_dir" status --short 2>/dev/null | head -20)
  [ -z "$dirty" ] && return 0

  echo "    ⚠ $slug: uncommitted changes — performing rescue commit (Codex sandbox limitation)"

  # Pre-commit checks
  local diff_issues
  diff_issues=$(git -C "$git_dir" diff --check 2>&1 || true)
  if [ -n "$diff_issues" ]; then
    echo "    ⚠ $slug: git diff --check warnings:"
    echo "$diff_issues" | head -10 | sed 's/^/      /'
  fi

  echo "    $slug: staged changes:"
  echo "$dirty" | sed 's/^/      /'

  # Read intended commit message from status.md (written by Codex)
  local commit_msg="feat($feat_id): implement work item (rescue commit)"
  local status_file="$git_dir/work/items/$slug/status.md"
  if [ -f "$status_file" ]; then
    local intended
    intended=$(
      python3 - "$status_file" <<'PY' 2>/dev/null || true
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
lines = text.splitlines()
capture = False
for line in lines:
    if line.startswith("## Intended Commit Message"):
        capture = True
        continue
    if capture and line.startswith("## "):
        break
    if capture:
        stripped = line.strip()
        if stripped and not stripped.startswith("("):
            print(stripped)
            raise SystemExit(0)
PY
    )
    if [ -n "$intended" ]; then
      commit_msg="$intended"
      echo "    $slug: using intended commit message from status.md"
    fi
  fi

  # Stage all changes and commit
  # Force-add work items (gitignored by work/ rule) then add everything else
  git -C "$git_dir" add -f "work/items/$slug/" 2>/dev/null || true
  git -C "$git_dir" add -A 2>/dev/null || { echo "    ✗ $slug: rescue git add failed"; return 1; }
  git -C "$git_dir" commit -m "$commit_msg" 2>/dev/null || { echo "    ✗ $slug: rescue git commit failed"; return 1; }

  # If status.md wasn't updated to done, normalize it and commit separately
  if [ -f "$status_file" ]; then
    local current_status
    current_status=$(get_item_status "$git_dir/work/items/$slug")
    if [[ "$current_status" != "done" ]]; then
      python3 - "$status_file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(r'^\|\s*Status\s*\|\s*[^|]+?\s*\|$', '| Status | done |', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Current\s+Status:\s*\S+.*$', '## Current Status: done', text, flags=re.MULTILINE)
path.write_text(text, encoding="utf-8")
PY
      if ! git -C "$git_dir" diff --quiet -- "work/items/$slug/status.md" 2>/dev/null; then
        git -C "$git_dir" add -f "work/items/$slug/status.md" 2>/dev/null || true
        git -C "$git_dir" commit -m "chore($feat_id): mark done (rescue commit)" 2>/dev/null || true
      fi
    fi
  fi

  echo "    ✓ $slug: rescue commit succeeded"
  return 0
}

verify_commits() {
  # Check that a feature branch has at least one feat() commit beyond its parent
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(basename "$wdir")

  # Resolve worktree path from status.md / dispatch / contract
  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")
  local git_dir="${target_dir:-.}"

  # Check for uncommitted changes — rescue if found
  local dirty
  dirty=$(git -C "$git_dir" status --porcelain 2>/dev/null | head -5)
  if [ -n "$dirty" ]; then
    rescue_uncommitted "$feat_id" || {
      echo "    ⚠ $slug: uncommitted changes remain after rescue attempt"
      echo "$dirty" | sed 's/^/      /'
      return 1
    }
  fi

  # Check for at least one feat() commit on the branch
  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  local parent_branch=""
  if [ -f "$wdir/contract.md" ]; then
    parent_branch=$(extract_contract_field "$wdir/contract.md" "Parent Branch" || true)
  fi
  if [ -z "$parent_branch" ] && [ -f ".claude/branch-map.yaml" ]; then
    parent_branch=$(grep 'working_parent:' .claude/branch-map.yaml | head -1 | awk '{print $2}' || true)
  fi

  if [ -n "$parent_branch" ]; then
    local feat_commits
    feat_commits=$(git -C "$git_dir" log --oneline "${parent_branch}..${branch}" 2>/dev/null | grep -c "feat($feat_id)" || true)
    if [ "$feat_commits" -eq 0 ]; then
      echo "    ⚠ $slug: no feat($feat_id) commit found on $branch (since $parent_branch)"
      return 1
    fi
  else
    # Fallback: check recent commits for feat() pattern
    local has_feat
    has_feat=$(git -C "$git_dir" log --oneline -20 2>/dev/null | grep -c "feat($feat_id)" || true)
    if [ "$has_feat" -eq 0 ]; then
      echo "    ⚠ $slug: no feat($feat_id) commit found in recent history"
      return 1
    fi
  fi

  echo "    ✓ $slug: commits verified"
  return 0
}

push_and_create_pr() {
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(basename "$wdir")

  # Resolve worktree path
  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")
  local git_dir="${target_dir:-.}"

  # Push branch
  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "    Pushing $branch..."
  if ! git -C "$git_dir" push -u origin "$branch" 2>/dev/null; then
    echo "    ⚠ $slug: push failed"
    return 1
  fi

  # Check if gh is available
  if ! command -v gh &>/dev/null; then
    echo "    ⚠ $slug: gh CLI not available — skip draft PR creation"
    return 0
  fi

  # Check if PR already exists
  local existing_pr
  existing_pr=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null || true)
  if [ -n "$existing_pr" ]; then
    echo "    ✓ $slug: PR #$existing_pr already exists"
    local pr_url
    pr_url=$(gh pr view "$existing_pr" --json url -q .url 2>/dev/null || true)
    if [ -n "$pr_url" ]; then
      sed -i "s|^\| PR \| .* |$|\| PR \| $pr_url \||" "$wdir/status.md" 2>/dev/null || true
    fi
    return 0
  fi

  # Resolve merge target from contract
  local merge_target=""
  if [ -f "$wdir/contract.md" ]; then
    merge_target=$(extract_contract_field "$wdir/contract.md" "Merge Target" || true)
  fi
  if [ -z "$merge_target" ] && [ -f ".claude/branch-map.yaml" ]; then
    merge_target=$(grep 'default_merge_target:' .claude/branch-map.yaml | head -1 | awk '{print $2}' || true)
  fi
  [ -z "$merge_target" ] && merge_target="main"

  # Read issue number from status.md
  local issue=""
  issue=$(grep -oP '^\| Issue \| #\K\d+' "$wdir/status.md" 2>/dev/null || true)

  # Read title from brief.md
  local title="$feat_id"
  if [ -f "$wdir/brief.md" ]; then
    title=$(grep -m1 '^# ' "$wdir/brief.md" | sed 's/^# //' || echo "$feat_id")
  fi

  # Build PR body
  local closes_line=""
  [ -n "$issue" ] && closes_line="Closes #$issue"

  local pr_url
  pr_url=$(gh pr create \
    --base "$merge_target" \
    --head "$branch" \
    --title "$feat_id: $title" \
    --body "$(cat <<EOF
## Work Item: $slug

$closes_line
Work item: \`work/items/$slug/\`
EOF
)" \
    --draft 2>/dev/null || true)

  if [ -n "$pr_url" ]; then
    echo "    ✓ $slug: draft PR created → $pr_url"
    sed -i "s|^\| PR \| .* |$|\| PR \| $pr_url \||" "$wdir/status.md" 2>/dev/null || true
    git -C "$git_dir" add -f "work/items/$slug/status.md" 2>/dev/null || true
    git -C "$git_dir" commit -m "chore($feat_id): record PR URL" 2>/dev/null || true
    git -C "$git_dir" push 2>/dev/null || true
  else
    echo "    ⚠ $slug: draft PR creation failed"
  fi
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
4. $wdir/review.md — latest review feedback; FIX every MUST-fix item before optional cleanup

EOF
)
  fi

  cat << EOF
You are implementing work item $slug. Read these files in order:

1. $wdir/brief.md — understand objective and scope
2. $wdir/contract.md — understand boundaries, interfaces, invariants
3. $wdir/checklist.md — understand verification requirements
${review_instructions}
Follow AGENTS.md for the full workflow.

Non-negotiables:
- Assume codex-run.sh already attempted parent-branch auto-sync before spawning you.
- Stay inside contract boundaries only.
- Update $wdir/status.md on every state change.
- Run the checklist verification commands before marking done.
- Print /work-review $feat_id as your final output.
- If git commit fails due to sandbox restrictions, leave files saved; codex-run.sh will rescue the commit.

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
        done < <(jq -r ".parallel_groups[$g].items[]" "$manifest")

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
    local target_dir=""
    target_dir=$(resolve_target_dir "$fid" "$wdir")
    local prompt
    prompt=$(build_codex_prompt "$fid")
    update_status_state "$wdir/status.md" "in-progress" "Codex"

    if command -v codex &>/dev/null; then
      # Ensure worktree has planning artifacts and latest parent-branch changes before spawning.
      if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
        sync_worktree_artifacts "$fid" "$target_dir"
        if ! sync_branch_from_parent "$fid" "$wdir" "$target_dir"; then
          echo "  Blocked: $slug → auto-sync failed; skipping Codex spawn"
          continue
        fi
      fi
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
  local -A notified_done=()
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
      # Read status from worktree (authoritative), fallback to cwd
      local wt_dir
      wt_dir=$(resolve_target_dir "$fid" "$wdir")
      local status_source="${wdir}"
      if [ -n "$wt_dir" ] && [ -f "$wt_dir/work/items/$slug/status.md" ]; then
        status_source="$wt_dir/work/items/$slug"
      fi
      local status
      status=$(get_item_status "$status_source")

      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        all_done=false
        printf "  %-40s %s (pid %s)\n" "$slug" "$status" "$pid"
      else
        if [[ "$status" == "done" ]]; then
          ((done_count++)) || true
          printf "  %-40s ✓ done\n" "$slug"
          if [ -z "${notified_done[$fid]:-}" ]; then
            notified_done["$fid"]=1
            notify_slack "✅ *$slug* done ($done_count/${#group_ids[@]})"
          fi
        else
          printf "  %-40s ✗ exited (status: %s)\n" "$slug" "$status"
          ((done_count++)) || true
          if [ -z "${notified_done[$fid]:-}" ]; then
            notified_done["$fid"]=1
            notify_slack "⚠️ *$slug* exited (status: $status)"
          fi
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

  _codex_run_dispatching=true

  notify_slack "🚀 *Codex Run Start*
• Items: ${feat_ids[*]}
• Count: ${#feat_ids[@]}
• Host: $(hostname)
• Repo: $(basename "$PWD")"

  # Step 3: Resolve groups and dispatch
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

  # Step 4: Collect results + verify commits
  echo ""
  echo "Step 3/4: Results + Verification"
  echo "──────────────────────────────────────────────"
  local success=0 failed=0 warn=0
  local review_ids=()
  local warn_ids=()
  local pr_urls=()
  for fid in "${feat_ids[@]}"; do
    local wdir
    wdir=$(resolve_work_dir "$fid")
    local slug
    slug=$(basename "$wdir")
    # Read status from worktree (authoritative) — Codex updates status.md there, not in cwd
    local wt_dir
    wt_dir=$(resolve_target_dir "$fid" "$wdir")
    local status_source="${wdir}"
    if [ -n "$wt_dir" ] && [ -f "$wt_dir/work/items/$slug/status.md" ]; then
      status_source="$wt_dir/work/items/$slug"
    fi
    local status
    status=$(get_item_status "$status_source")
    if [[ "$status" == "done" ]]; then
      # Verify commits exist before declaring success
      if verify_commits "$fid"; then
        ((success++)) || true
        review_ids+=("$fid")
      else
        ((warn++)) || true
        warn_ids+=("$fid")
        review_ids+=("$fid")  # still reviewable, but flagged
      fi
    else
      ((failed++)) || true
    fi
  done

  # Step 3.5: Push + draft PR for verified items
  if [ ${#review_ids[@]} -gt 0 ]; then
    echo ""
    echo "Pushing branches + creating draft PRs..."
    for fid in "${review_ids[@]}"; do
      local pr_result
      pr_result=$(push_and_create_pr "$fid" 2>&1) || true
      echo "$pr_result"
      # Extract PR URL if created
      local url
      url=$(echo "$pr_result" | grep -oP '→ \K.*' || true)
      [ -n "$url" ] && pr_urls+=("$fid: $url")
    done
  fi

  # Print summary + next step
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

  # Slack notification
  local slack_text="🔧 *Codex Run Complete*
• Success: $success  Failed: $failed
• Items: ${feat_ids[*]}
• Host: $(hostname)"
  if [ ${#pr_urls[@]:-0} -gt 0 ]; then
    slack_text+="
• PRs:"
    for pr_info in "${pr_urls[@]}"; do
      slack_text+="
  - $pr_info"
    done
  fi
  if [ ${#review_ids[@]} -gt 0 ]; then
    slack_text+="
• Next: \`/work-review ${review_ids[*]}\`"
  fi
  notify_slack "$slack_text"
  _codex_run_dispatching=false
}

# ─── Main ─────────────────────────────────────────────────────────────────────

# ─── Trap: notify on unexpected exit ─────────────────────────────────────────

_codex_run_dispatching=false

cleanup_trap() {
  local exit_code=$?
  if $_codex_run_dispatching && [ "$exit_code" -ne 0 ]; then
    notify_slack "❌ *Codex Run Failed*
• Exit code: $exit_code
• Host: $(hostname)
• Repo: $(basename "$PWD")"
  fi
}
trap cleanup_trap EXIT

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
