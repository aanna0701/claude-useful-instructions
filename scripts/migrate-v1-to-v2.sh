#!/usr/bin/env bash
# migrate-v1-to-v2.sh — Remove v1 artifacts from a consumer repo.
#
# Deletes from each worktree/main repo:
#   work/items/*/{status,brief,checklist,relay,pr-relay,verify-result,review}.md
#   .cursor/rules/{slug}-guard.mdc  .cursor/rules/{slug}-forbidden.mdc
#   .cursor/rules/_work-item.mdc
#   work/batches/, work/locks/
#   CLAUDE.md.backup.*, AGENTS.md.backup.*, .cursorrules
#
# Preserves: work/items/*/contract.md, .git/, .worktrees/, source files.
#
# Usage: migrate-v1-to-v2.sh [--apply]
#   default is dry-run; pass --apply to actually delete.

set -euo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

run() {
  if [ "$APPLY" -eq 1 ]; then
    "$@"
  else
    echo "DRY-RUN: $*"
  fi
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Collect all worktree roots (main + worktrees)
ROOTS=()
while IFS= read -r line; do
  case "$line" in
    "worktree "*) ROOTS+=("${line#worktree }") ;;
  esac
done < <(git worktree list --porcelain)

for root in "${ROOTS[@]}"; do
  echo "── scanning: $root"

  # per-item md files (keep contract.md only)
  while IFS= read -r -d '' f; do
    run rm -f "$f"
  done < <(find "$root/work/items" -type f \
    \( -name status.md -o -name brief.md -o -name checklist.md \
       -o -name relay.md -o -name pr-relay.md \
       -o -name verify-result.md -o -name review.md \) \
    -print0 2>/dev/null)

  # cursor per-item mdcs
  while IFS= read -r -d '' f; do
    run rm -f "$f"
  done < <(find "$root/.cursor/rules" -maxdepth 1 -type f \
    \( -name '*-guard.mdc' -o -name '*-forbidden.mdc' -o -name '_work-item.mdc' \) \
    -print0 2>/dev/null)

  # batches + locks (if present and empty of unmerged work)
  [ -d "$root/work/batches" ] && run rm -rf "$root/work/batches"
  [ -d "$root/work/locks" ]   && run rm -rf "$root/work/locks"

  # backup AGENTS.md / CLAUDE.md
  while IFS= read -r -d '' f; do
    run rm -f "$f"
  done < <(find "$root" -maxdepth 1 -type f \
    \( -name 'AGENTS.md.backup.*' -o -name 'CLAUDE.md.backup.*' \) \
    -print0 2>/dev/null)

  # legacy cursorrules
  [ -f "$root/.cursorrules" ] && run rm -f "$root/.cursorrules"
done

if [ "$APPLY" -eq 0 ]; then
  echo
  echo "Dry-run complete. Re-run with --apply to delete."
else
  echo
  echo "Migration complete. Next: ./install.sh $REPO_ROOT  (re-install v2 bundle)"
fi
