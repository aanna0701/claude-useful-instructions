#!/usr/bin/env bash
# codex-run.sh v2 — Unattended Codex runner for a work item.
#
# Assembles a prompt from the worktree's contract.md, any unresolved review
# threads on the PR (CHANGES_REQUESTED re-entry), and the current diff vs base.
# Runs `codex exec`, pushes commits, prints PR/CI summary. Writes no md files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${CODEX_LOG_DIR:-work/.dispatch-logs}"
STALL_TIMEOUT="${CODEX_STALL_TIMEOUT:-600}"   # seconds of no output → stall
OVERALL_TIMEOUT="${CODEX_OVERALL_TIMEOUT:-3600}"

usage() {
  cat <<'HELP'
Usage: codex-run.sh <ID>

  ID    Work item ID (e.g. FEAT-042). Branch must be `feature-{type}-{slug}`
        and a worktree must exist (created by /work-plan).

Flow:
  1. Resolve worktree by branch matching the ID's slug.
  2. Assemble prompt: contract.md + unresolved review threads + git diff.
  3. Run `codex exec` with stall detection.
  4. `git push` (branch already upstream).
  5. Print `gh pr view` + `gh pr checks` summary.

Requires: gh auth, codex CLI, jq, python3.
HELP
}

die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -eq 1 ] || { usage; exit 1; }
case "$1" in -h|--help) usage; exit 0 ;; esac

ID="$1"
[[ "$ID" =~ ^(FEAT|FIX|PERF|CHORE|TEST|REFAC)-[0-9]+$ ]] \
  || die "invalid ID '$ID' (expected {TYPE}-NNN)"

command -v gh  >/dev/null || die "gh CLI not installed"
command -v jq  >/dev/null || die "jq not installed"
command -v python3 >/dev/null || die "python3 not installed"
command -v codex >/dev/null || die "codex CLI not installed"
gh auth status >/dev/null 2>&1 || die "run: gh auth login"

# Resolve worktree: find branch matching slug from any worktree, else main repo
# item dir → branch convention.
WT_PATH=""
BRANCH=""
SLUG=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*)   cur_path="${line#worktree }" ;;
    "branch refs/heads/"*)
      cur_branch="${line#branch refs/heads/}"
      if [[ "$cur_branch" =~ ^feature-(feat|fix|perf|chore|test|refac)-(.+)$ ]]; then
        cand_slug="${BASH_REMATCH[2]}"
        if [ -d "$cur_path/work/items/${ID}-${cand_slug}" ]; then
          WT_PATH="$cur_path"; BRANCH="$cur_branch"; SLUG="$cand_slug"; break
        fi
      fi
      ;;
  esac
done < <(git worktree list --porcelain)

if [ -z "$WT_PATH" ]; then
  # Distinguish: branch+worktree exist but contract missing, vs nothing at all.
  ORPHAN_WT=""
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) cur_path="${line#worktree }" ;;
      "branch refs/heads/"*)
        cur_branch="${line#branch refs/heads/}"
        if [[ "$cur_branch" =~ ^feature-(feat|fix|perf|chore|test|refac)-(.+)$ ]]; then
          cand_slug="${BASH_REMATCH[2]}"
          # Branch name often encodes slug; flag worktree with matching slug but no contract dir.
          if [ ! -d "$cur_path/work/items/${ID}-${cand_slug}" ] \
             && [ -d "$cur_path" ]; then
            ORPHAN_WT="$cur_path (branch $cur_branch)"
          fi
        fi
        ;;
    esac
  done < <(git worktree list --porcelain)
  if [ -n "$ORPHAN_WT" ]; then
    die "worktree found but contract missing: $ORPHAN_WT
  Likely cause: /work-plan created worktree but skipped contract copy (work/ gitignored).
  Fix: cp work/items/${ID}-<slug>/contract.md <worktree>/work/items/${ID}-<slug>/ and re-run, or re-run /work-plan."
  fi
  die "no worktree contains work/items/${ID}-*. Run /work-plan first."
fi

ITEM_DIR="$WT_PATH/work/items/${ID}-${SLUG}"
CONTRACT="$ITEM_DIR/contract.md"
[ -f "$CONTRACT" ] || die "missing $CONTRACT"

cd "$WT_PATH"
BASE=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null | sed 's|^origin/||')
# If HEAD is origin/BRANCH, use parent from upstream tracking of PR base.
PR_JSON=$(gh pr view --json number,baseRefName,reviewDecision,headRefOid,url 2>/dev/null || true)
[ -n "$PR_JSON" ] || die "no PR found for branch $BRANCH. Run /work-plan or wait for auto-pr-commit."
PR_NUM=$(jq -r .number <<<"$PR_JSON")
PR_BASE=$(jq -r .baseRefName <<<"$PR_JSON")
REVIEW_DECISION=$(jq -r '.reviewDecision // ""' <<<"$PR_JSON")

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${ID}-${SLUG}.log"
PROMPT_FILE="$(mktemp)"
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  echo "# Work item: $ID"
  echo
  echo "## Contract"
  echo
  cat "$CONTRACT"
  echo

  if [ "$REVIEW_DECISION" = "CHANGES_REQUESTED" ]; then
    echo "## Unresolved review threads (MUST-fix)"
    echo
    OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    OWNER="${OWNER_REPO%%/*}"; REPO="${OWNER_REPO##*/}"
    gh api graphql -f query='
      query($o:String!,$r:String!,$n:Int!){
        repository(owner:$o,name:$r){
          pullRequest(number:$n){
            reviewThreads(first:100){
              nodes{ id isResolved path line
                comments(first:5){ nodes{ body author{login} } }
              }
            }
      }}}' -f o="$OWNER" -f r="$REPO" -F n="$PR_NUM" \
      | jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
          | select(.isResolved==false)
          | "- \(.path):\(.line) [thread \(.id)]\n"
            + (.comments.nodes | map("    " + .author.login + ": " + (.body | gsub("\n"; " "))) | join("\n"))'
    echo
    echo "After fixing each, resolve via:"
    echo '  gh api graphql -f query='"'"'mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id}}}'"'"' -f id=$THREAD_ID'
    echo
  fi

  echo "## Current diff vs $PR_BASE"
  echo
  echo '```diff'
  git diff "origin/$PR_BASE...HEAD" --stat
  echo
  git diff "origin/$PR_BASE...HEAD" | head -2000
  echo '```'
  echo
  echo "## Task"
  echo
  echo "Implement the contract. Honor Touch/Forbidden/Preserve globs."
  echo "Small commits. Keep tests green. Sign commits with -s."
  echo "Do not write status/relay/review md files. Only edit source + contract is immutable."
} > "$PROMPT_FILE"

# Run codex with stall detection
LAST_OUTPUT=$(date +%s)
PID=""
(
  codex exec --cd "$WT_PATH" --full-auto - < "$PROMPT_FILE" 2>&1 \
    | while IFS= read -r line; do
        printf '%s\n' "$line"
        date +%s > "$LOG_FILE.heartbeat"
      done \
    | tee "$LOG_FILE"
) &
PID=$!
echo "[codex-run] live log: $LOG_FILE (tailing to stdout)" >&2

START=$(date +%s)
date +%s > "$LOG_FILE.heartbeat"
while kill -0 "$PID" 2>/dev/null; do
  sleep 15
  NOW=$(date +%s)
  HB=$(cat "$LOG_FILE.heartbeat" 2>/dev/null || echo "$NOW")
  if (( NOW - HB > STALL_TIMEOUT )); then
    echo "[codex-run] STALL: no output for ${STALL_TIMEOUT}s, killing pid $PID" >&2
    kill "$PID" 2>/dev/null || true
    break
  fi
  if (( NOW - START > OVERALL_TIMEOUT )); then
    echo "[codex-run] TIMEOUT: exceeded ${OVERALL_TIMEOUT}s, killing pid $PID" >&2
    kill "$PID" 2>/dev/null || true
    break
  fi
done
wait "$PID" 2>/dev/null || true

# Push whatever was committed
git push 2>&1 | tail -5 || true

# Summary
echo
echo "=== PR status ==="
gh pr view "$PR_NUM" --json number,url,state,isDraft,reviewDecision,statusCheckRollup \
  | jq -r '"PR #\(.number)  \(.url)\n  state=\(.state)  draft=\(.isDraft)  review=\(.reviewDecision // "none")"'
echo
gh pr checks "$PR_NUM" 2>/dev/null | tail -20 || true
