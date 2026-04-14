#!/usr/bin/env bash

ensure_uv_environment() {
  local feat_id="$1"
  local wdir="$2"
  local git_dir="$3"
  local slug
  slug=$(resolve_work_item_slug "$wdir")

  [ -f "$git_dir/pyproject.toml" ] || return 0
  [ -f "$git_dir/uv.lock" ] || return 0

  if ! command -v uv >/dev/null 2>&1; then
    mark_status_blocked_everywhere "$feat_id" "$wdir" "env-tooling" "uv is required for this project but is not installed. Install uv, then rerun codex-run.sh."
    echo "    [env] uv missing; status marked blocked"
    return 1
  fi

  local -a uv_args=("--frozen")
  local group=""
  for group in $CODEX_RUN_UV_GROUPS; do
    uv_args+=("--group" "$group")
  done

  local env_log="$LOG_DIR/${slug}.env.log"
  echo "    [env] syncing uv environment (${CODEX_RUN_UV_GROUPS})"
  if uv -q sync "${uv_args[@]}" --project "$git_dir" >"$env_log" 2>&1; then
    echo "    [env] uv sync complete"
    return 0
  fi

  local blocker="uv sync failed in $git_dir. Inspect $env_log, fix the project environment or network/cache issue, then rerun codex-run.sh."
  mark_status_blocked_everywhere "$feat_id" "$wdir" "env-setup" "$blocker"
  echo "    [env] uv sync failed; status marked blocked"
  return 1
}

sync_branch_from_parent() {
  local feat_id="$1"
  local wdir="$2"
  local git_dir="$3"

  local parent_branch=""
  parent_branch=$(resolve_parent_branch "$wdir")
  if [ -z "$parent_branch" ]; then
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

  # Capture conflicting files before aborting
  local conflict_files=""
  conflict_files=$(git -C "$git_dir" diff --name-only --diff-filter=U 2>/dev/null || true)
  git -C "$git_dir" merge --abort >/dev/null 2>&1 || true

  local blocker="Runner auto-sync from parent '$parent_branch' failed."
  if [ -n "$conflict_files" ]; then
    echo "    [sync] conflicting files:"
    echo "$conflict_files" | head -20 | sed 's/^/      /'
    blocker="$blocker Conflicts in: $(echo "$conflict_files" | tr '\n' ', ' | sed 's/,$//')."
  fi
  blocker="$blocker Resolve merge conflicts, then rerun codex-run.sh."

  mark_status_blocked_everywhere "$feat_id" "$wdir" "needs-sync" "$blocker"
  echo "    [sync] merge failed; status marked blocked"
  return 1
}

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
  slug=$(resolve_work_item_slug "$wdir")
  local needs_commit=false

  local wt_feat_dir="$target_dir/work/items/$slug"
  if [ -d "$wdir" ]; then
    mkdir -p "$wt_feat_dir"
    local spec_file=""
    for spec_file in brief.md contract.md checklist.md review.md relay.md; do
      [ -f "$wdir/$spec_file" ] || continue
      if [ ! -f "$wt_feat_dir/$spec_file" ] || ! cmp -s "$wdir/$spec_file" "$wt_feat_dir/$spec_file"; then
        cp "$wdir/$spec_file" "$wt_feat_dir/$spec_file"
        git -C "$target_dir" add -f "work/items/$slug/$spec_file"
        needs_commit=true
        echo "    [sync] updated work/items/$slug/$spec_file"
      fi
    done
  fi

  if [ -f "$base_repo/AGENTS.md" ] && { [ ! -f "$target_dir/AGENTS.md" ] || ! cmp -s "$base_repo/AGENTS.md" "$target_dir/AGENTS.md"; }; then
    cp "$base_repo/AGENTS.md" "$target_dir/AGENTS.md"
    git -C "$target_dir" add AGENTS.md
    needs_commit=true
    echo "    [sync] updated AGENTS.md"
  fi

  if $needs_commit; then
    git -C "$target_dir" commit -m "chore($slug): seed work item artifacts" || true
    echo "    [sync] committed artifacts on feature branch"
  fi
}

post_impl_relay_comment() {
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(resolve_work_item_slug "$wdir")
  local git_dir
  git_dir=$(resolve_git_dir "$feat_id" "$wdir")

  command -v gh &>/dev/null || return 0

  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  local pr_number
  pr_number=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null || true)
  [ -n "$pr_number" ] || return 0

  local relay_file="$git_dir/work/items/$slug/relay.md"
  if [ ! -f "$relay_file" ]; then
    relay_file="$wdir/relay.md"
  fi

  local notes="Implementation completed by Codex."
  local result="success"
  local changed=""
  local commits=""
  if [ -f "$relay_file" ]; then
    result=$(grep -m1 '^result:' "$relay_file" | awk '{print $2}' || echo "success")
    changed=$(grep -m1 '^changed:' "$relay_file" | sed 's/^changed: *//' || true)
    commits=$(grep -m1 '^commits:' "$relay_file" | sed 's/^commits: *//' || true)
    notes=$(python3 - "$relay_file" <<'PY' 2>/dev/null || echo "Implementation completed.")
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
in_notes = False
lines = []
for line in text.splitlines():
    if line.startswith("notes:"):
        in_notes = True
        continue
    if in_notes:
        if line.startswith("  "):
            lines.append(line.strip())
        else:
            break
print(" ".join(lines) if lines else "Implementation completed.")
PY
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%S)
  local body="<!-- relay:impl:${timestamp} -->
### impl — ${result}
**agent:** codex"
  [ -n "$changed" ] && body+=$'\n'"**changed:** ${changed}"
  [ -n "$commits" ] && body+=$'\n'"**commits:** ${commits}"
  body+=$'\n\n'"> ${notes}"

  gh pr comment "$pr_number" --body "$body" || true
}

fetch_pr_relay() {
  local pr_number="$1" output_file="$2"
  command -v gh &>/dev/null || return 0
  [ -n "$pr_number" ] || return 0
  local owner_repo
  owner_repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
  [ -n "$owner_repo" ] || return 0
  local tmp
  tmp=$(mktemp)
  if gh api "repos/${owner_repo}/issues/${pr_number}/comments" \
    --jq '[.[] | select(.body | contains("<!-- relay:")) | .body] | join("\n\n---\n\n")' \
    > "$tmp" 2>/dev/null; then
    mv "$tmp" "$output_file"
  else
    rm -f "$tmp"
  fi
}

preflight_target_dir() {
  local feat_id="$1"
  local wdir="$2"
  local git_dir="$3"

  [ "$git_dir" = "." ] && return 0
  [ -d "$git_dir" ] || return 0

  sync_worktree_artifacts "$feat_id" "$git_dir"
  if ! sync_branch_from_parent "$feat_id" "$wdir" "$git_dir"; then
    return 1
  fi
  if ! ensure_uv_environment "$feat_id" "$wdir" "$git_dir"; then
    return 1
  fi

  return 0
}

rescue_uncommitted() {
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(resolve_work_item_slug "$wdir")
  local git_dir
  git_dir=$(resolve_git_dir "$feat_id" "$wdir")

  local dirty
  dirty=$(git -C "$git_dir" status --short 2>/dev/null | head -20)
  [ -z "$dirty" ] && return 0

  echo "    ⚠ $slug: uncommitted changes — performing rescue commit (Codex sandbox limitation)"

  local diff_issues
  diff_issues=$(git -C "$git_dir" diff --check 2>&1 || true)
  if [ -n "$diff_issues" ]; then
    echo "    ⚠ $slug: git diff --check warnings:"
    echo "$diff_issues" | head -10 | sed 's/^/      /'
  fi

  echo "    $slug: staged changes:"
  echo "$dirty" | sed 's/^/      /'

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

  git -C "$git_dir" add -f "work/items/$slug/" 2>/dev/null || true
  git -C "$git_dir" add -A 2>/dev/null || { echo "    ✗ $slug: rescue git add failed"; return 1; }
  git -C "$git_dir" commit -m "$commit_msg" 2>/dev/null || { echo "    ✗ $slug: rescue git commit failed"; return 1; }

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
  local feat_id="$1"
  local wdir
  wdir=$(resolve_work_dir "$feat_id") || return 1
  local slug
  slug=$(resolve_work_item_slug "$wdir")
  local git_dir
  git_dir=$(resolve_git_dir "$feat_id" "$wdir")

  local dirty
  dirty=$(git -C "$git_dir" status --porcelain 2>/dev/null | head -5)
  if [ -n "$dirty" ]; then
    rescue_uncommitted "$feat_id" || {
      echo "    ⚠ $slug: uncommitted changes remain after rescue attempt"
      echo "$dirty" | sed 's/^/      /'
      return 1
    }
  fi

  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  local parent_branch=""
  parent_branch=$(resolve_parent_branch "$wdir")

  if [ -n "$parent_branch" ]; then
    local feat_commits
    feat_commits=$(git -C "$git_dir" log --oneline "${parent_branch}..${branch}" 2>/dev/null | grep -c "feat($feat_id)" || true)
    if [ "$feat_commits" -eq 0 ]; then
      echo "    ⚠ $slug: no feat($feat_id) commit found on $branch (since $parent_branch)"
      return 1
    fi
  else
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
  slug=$(resolve_work_item_slug "$wdir")
  local git_dir
  git_dir=$(resolve_git_dir "$feat_id" "$wdir")

  local branch
  branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "    Pushing $branch..."
  if ! git -C "$git_dir" push -u origin "$branch" 2>/dev/null; then
    echo "    ⚠ $slug: push failed"
    return 1
  fi

  if ! command -v gh &>/dev/null; then
    echo "    ⚠ $slug: gh CLI not available — skip draft PR creation"
    return 0
  fi

  local existing_pr
  existing_pr=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null || true)
  if [ -n "$existing_pr" ]; then
    echo "    ✓ $slug: PR #$existing_pr already exists"
    local pr_url
    pr_url=$(gh pr view "$existing_pr" --json url -q .url 2>/dev/null || true)
    if [ -n "$pr_url" ]; then
      sed -i "s~^| PR | .* |$~| PR | $pr_url |~" "$wdir/status.md" 2>/dev/null || true
    fi
    return 0
  fi

  local merge_target=""
  merge_target=$(resolve_merge_target "$wdir")

  local title="$feat_id"
  if [ -f "$wdir/brief.md" ]; then
    title=$(grep -m1 '^# ' "$wdir/brief.md" | sed 's/^# //' || echo "$feat_id")
  fi

  local pr_url
  pr_url=$(gh pr create \
    --base "$merge_target" \
    --head "$branch" \
    --title "$feat_id: $title" \
    --body "$(cat <<EOF
## Work Item: $slug

Work item: \`work/items/$slug/\`
EOF
)" \
    --draft 2>/dev/null || true)

  if [ -n "$pr_url" ]; then
    echo "    ✓ $slug: draft PR created → $pr_url"
    sed -i "s~^| PR | .* |$~| PR | $pr_url |~" "$wdir/status.md" 2>/dev/null || true
    git -C "$git_dir" add -f "work/items/$slug/status.md" 2>/dev/null || true
    git -C "$git_dir" commit -m "chore($feat_id): record PR URL" 2>/dev/null || true
    git -C "$git_dir" push 2>/dev/null || true
  else
    echo "    ⚠ $slug: draft PR creation failed"
  fi
}
