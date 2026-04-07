#!/usr/bin/env bash

resolve_work_dir() {
  local feat_id="$1"
  for dir in work/items/${feat_id}*/; do
    [ -d "$dir" ] && echo "${dir%/}" && return 0
  done
  return 1
}

resolve_work_item_slug() {
  local wdir="$1"
  basename "$wdir"
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
    target_dir=$(
      python3 - "$wdir/status.md" <<'PY' 2>/dev/null || true
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")

patterns = [
    r'^\|\s*Worktree Path\s*\|\s*([^|]+?)\s*\|$',
    r'^- \*\*Worktree Path\*\*:\s*(.+?)\s*$',
    r'^\*\*Worktree Path\*\*:\s*(.+?)\s*$',
]

for line in text.splitlines():
    for pattern in patterns:
        match = re.match(pattern, line)
        if not match:
            continue
        value = match.group(1).strip().strip("`")
        if value and value != "—":
            print(value)
            raise SystemExit(0)

lines = text.splitlines()
for index, line in enumerate(lines):
    if re.match(r'^##\s*Worktree Path\s*$', line.strip()):
        for follow in lines[index + 1:]:
            stripped = follow.strip()
            if not stripped:
                continue
            if stripped.startswith("## "):
                break
            value = stripped.strip("`")
            if value and value != "—":
                print(value)
                raise SystemExit(0)
            break
PY
    )
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

resolve_status_files() {
  local feat_id="$1"
  local wdir="$2"
  local slug
  slug=$(resolve_work_item_slug "$wdir")

  echo "$wdir/status.md"

  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")
  if [ -n "$target_dir" ] && [ -f "$target_dir/work/items/$slug/status.md" ]; then
    local wt_status="$target_dir/work/items/$slug/status.md"
    if [ "$wt_status" != "$wdir/status.md" ]; then
      echo "$wt_status"
    fi
  fi
}

resolve_status_source_dir() {
  local feat_id="$1"
  local wdir="$2"
  local slug
  slug=$(resolve_work_item_slug "$wdir")

  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")

  if [ -n "$target_dir" ] && [ -f "$target_dir/work/items/$slug/status.md" ]; then
    echo "$target_dir/work/items/$slug"
    return 0
  fi

  echo "$wdir"
}

resolve_git_dir() {
  local feat_id="$1"
  local wdir="$2"
  local target_dir=""
  target_dir=$(resolve_target_dir "$feat_id" "$wdir")

  if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
    echo "$target_dir"
    return 0
  fi

  echo "."
}

resolve_parent_branch() {
  local wdir="$1"
  local parent_branch=""

  if [ -f "$wdir/contract.md" ]; then
    parent_branch=$(extract_contract_field "$wdir/contract.md" "Parent Branch" || true)
  fi
  if [ -z "$parent_branch" ] && [ -f ".claude/branch-map.yaml" ]; then
    parent_branch=$(grep 'working_parent:' .claude/branch-map.yaml | head -1 | awk '{print $2}' || true)
  fi
  if [ "$parent_branch" = "—" ] || [[ "$parent_branch" == \[* ]]; then
    parent_branch=""
  fi

  echo "$parent_branch"
}

resolve_merge_target() {
  local wdir="$1"
  local merge_target=""

  if [ -f "$wdir/contract.md" ]; then
    merge_target=$(extract_contract_field "$wdir/contract.md" "Merge Target" || true)
  fi
  [ "$merge_target" = "—" ] && merge_target=""
  if [ -z "$merge_target" ] && [ -f ".claude/branch-map.yaml" ]; then
    merge_target=$(grep 'default_merge_target:' .claude/branch-map.yaml | head -1 | awk '{print $2}' || true)
  fi
  [ -z "$merge_target" ] && merge_target="main"

  echo "$merge_target"
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
text = re.sub(r'^status: .*$', f'status: {status_value}', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Status\s*\|\s*[^|]+?\s*\|$', f'| Status | {status_value} |', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Agent\s*\|\s*[^|]+?\s*\|$', f'| Agent | {agent_value} |', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Status:\s*\S+.*$', f'## Status: {status_value}', text, flags=re.MULTILINE)
text = re.sub(r'^\*\*Current\*\*:\s*\S+.*$', f'**Current**: {status_value}', text, flags=re.MULTILINE)
text = re.sub(r'^- \*\*Assignee\*\*:\s*.*$', f'- **Assignee**: {agent_value}', text, flags=re.MULTILINE)
text = re.sub(r'^- \*\*Agent\*\*:\s*.*$', f'- **Agent**: {agent_value}', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Current\s+Status:\s*\S+.*$', f'## Current Status: {status_value}', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Agent:\s*.*$', f'## Agent: {agent_value}', text, flags=re.MULTILINE)
text = re.sub(
    r'^(\|\s*Implementation\s*\|\s*)([^|]+?)(\s*\|)$',
    rf'\1{status_value}\3',
    text,
    flags=re.MULTILINE,
)

path.write_text(text, encoding="utf-8")
PY
}

update_status_state_everywhere() {
  local feat_id="$1"
  local wdir="$2"
  local status_value="$3"
  local agent_value="$4"

  while IFS= read -r status_file; do
    [ -n "$status_file" ] || continue
    [ -f "$status_file" ] || continue
    update_status_state "$status_file" "$status_value" "$agent_value"
  done < <(resolve_status_files "$feat_id" "$wdir")
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
text = re.sub(r'^status: .*$', 'status: blocked', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Status\s*\|\s*[^|]+?\s*\|$', '| Status | blocked |', text, flags=re.MULTILINE)
text = re.sub(r'^\|\s*Issue\s*\|\s*[^|]+?\s*\|$', f'| Issue | {issue_value} |', text, flags=re.MULTILINE)
text = re.sub(r'^##\s*Status:\s*\S+.*$', '## Status: blocked', text, flags=re.MULTILINE)
text = re.sub(r'^\*\*Current\*\*:\s*\S+.*$', '**Current**: blocked', text, flags=re.MULTILINE)
text = re.sub(
    r'^(\|\s*Implementation\s*\|\s*)([^|]+?)(\s*\|)$',
    r'\1blocked\3',
    text,
    flags=re.MULTILINE,
)

pattern = re.compile(r'(^## Blockers\n)(.*?)(?=\n## |\Z)', re.MULTILINE | re.DOTALL)
match = pattern.search(text)
replacement_body = f"- {blocker_text}"
if match:
    text = text[:match.start()] + match.group(1) + replacement_body + text[match.end():]

path.write_text(text, encoding="utf-8")
PY
}

mark_status_blocked_everywhere() {
  local feat_id="$1"
  local wdir="$2"
  local issue_value="$3"
  local blocker_text="$4"

  while IFS= read -r status_file; do
    [ -n "$status_file" ] || continue
    [ -f "$status_file" ] || continue
    mark_status_blocked "$status_file" "$issue_value" "$blocker_text"
  done < <(resolve_status_files "$feat_id" "$wdir")
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
    match = re.match(r'^status:\s*(\S+)\s*$', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)
    match = re.match(r'^\|\s*Status\s*\|\s*([^|]+?)\s*\|$', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)
    match = re.match(r'^##\s*Status:\s*(\S+)', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)
    match = re.match(r'^##\s*Current\s+Status:\s*(\S+)', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)
    match = re.match(r'^\*\*Current\*\*:\s*(\S+)', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)

lines = text.splitlines()
for index, line in enumerate(lines):
    if re.match(r'^##\s*Status\s*$', line.strip()):
        for follow in lines[index + 1:]:
            stripped = follow.strip()
            if not stripped:
                continue
            if stripped.startswith("## "):
                break
            match = re.match(r'^\*\*Current\*\*:\s*(\S+)', stripped)
            if match:
                print(match.group(1).strip())
                raise SystemExit(0)
            break

for line in lines:
    match = re.match(r'^\|\s*Implementation\s*\|\s*([^|]+?)\s*\|$', line)
    if match:
        print(match.group(1).strip())
        raise SystemExit(0)

print("unknown")
PY
}

cmd_status() {
  echo "Work Items"
  echo "──────────────────────────────────────────────"
  local count=0
  for dir in work/items/FEAT-*/; do
    [ -d "$dir" ] || continue
    local slug status
    slug=$(resolve_work_item_slug "$dir")
    status=$(get_item_status "$dir")
    printf "  %-40s %s\n" "$slug" "$status"
    ((count++)) || true
  done
  [ "$count" -eq 0 ] && echo "  (no work items found)"
  echo "──────────────────────────────────────────────"
}

build_codex_prompt() {
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id")
  local slug
  slug=$(resolve_work_item_slug "$wdir")
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
- Use the project uv environment for Python commands: prefer \`uv run ...\` and never \`pip install\` ad hoc.
- Stay inside contract boundaries only.
- Update $wdir/status.md on every state change.
- Run the checklist verification commands before marking done.
- Before starting, read $wdir/relay.md (if it exists) for context from prior stages.
- On completion, append an impl block to $wdir/relay.md:
  ## impl @ {timestamp}
  result: {success|partial|blocked}
  changed: [{list of changed files}]
  commits: [{commit hashes}]
  notes: |
    {1-3 line summary}
- Print /work-review $feat_id as your final output.
- If git commit fails due to sandbox restrictions, leave files saved; codex-run.sh will rescue the commit.

Begin implementation.
EOF
}
