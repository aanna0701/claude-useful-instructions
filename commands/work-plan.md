# work-plan — Create a Work Item

Create one work item: contract + branch + worktree + draft PR.

## Input

```
/work-plan                  # interactive: type, title, scope, acceptance
/work-plan "<title>"        # title hint, rest interactive
```

## Steps

1. **Clarify contract** with the user (one round of questions): goal, scope in/out, touchable globs, forbidden globs, acceptance criteria, risks. For REFAC also preserve list (public API, behavior invariants).
2. **Assign ID** `{TYPE}-{NNN}` from `work/items/` counter (`TYPE ∈ {FEAT,FIX,PERF,CHORE,TEST,REFAC}`).
3. **Derive slug** kebab-case ≤ 40 chars from title.
4. **Set branch** `feature-{type}-{slug}` (lowercase type, so `REFAC → refac`).
5. **Acquire lock** `work/locks/planning.lock` via `flock`.
6. **Write contract** to `work/items/{ID}-{slug}/contract.md` using the schema in `templates/work-item/contract.md`.
7. **Create branch + worktree + materialize contract**:
   ```bash
   PARENT="$(git rev-parse --abbrev-ref HEAD)"
   # Guard: refuse to base a work item off the repo default branch. Some repos
   # keep `main` intentionally empty and integrate on a branch like
   # `feature-init-dev`; basing a PR on main there ships to the wrong target
   # and has to be reverted. Override by checking out the integration branch
   # before running /work-plan.
   DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null || echo main)"
   case "$PARENT" in
     "$DEFAULT_BRANCH"|HEAD)
       echo "ERROR: current branch '$PARENT' is the repo default; cannot be a work-item parent."
       echo "       Checkout the integration branch first, e.g.:"
       echo "         git checkout feature-init-dev && git pull"
       exit 1
       ;;
   esac
   git branch "$BRANCH" "$PARENT"
   WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
   git worktree add "$WT_PATH" "$BRANCH"
   # MANDATORY: copy contract into the worktree. codex-run.sh resolves the worktree
   # by probing `work/items/{ID}-{slug}/` existence, so skipping this breaks
   # /work-impl. Verify before proceeding.
   mkdir -p "$WT_PATH/work/items/{ID}-{slug}"
   cp "work/items/{ID}-{slug}/contract.md" "$WT_PATH/work/items/{ID}-{slug}/contract.md"
   test -f "$WT_PATH/work/items/{ID}-{slug}/contract.md" \
     || { echo "ERROR: contract not materialized in worktree"; exit 1; }
   ```
8. **First commit + push** in worktree:
   ```bash
   cd "$WT_PATH"
   # -f forces add even if work/ is gitignored; contract.md belongs on the branch
   # so the PR has context. NEVER fall back to `git commit --allow-empty` — an
   # empty plan commit means contract.md is absent from the branch and
   # codex-run.sh / /work-review cannot see it.
   git add -f work/items/{ID}-{slug}/contract.md
   git diff --cached --quiet \
     && { echo "ERROR: nothing staged; contract missing or add -f skipped"; exit 1; }
   git commit -s -m "chore(plan): {ID} contract"
   git push -u origin "$BRANCH"
   ```
9. **Create draft PR** with standard body (per `templates/collab-pipeline-body.md`):
   ```bash
   gh pr create --draft --title "{ID} {title}" --body-file /tmp/pr-body.md --base "$PARENT"
   ```
10. **Release lock**.

## Output

Print:
- `ID`: FEAT-042
- `Branch`: feature-feat-user-auth
- `Worktree`: /abs/path (absolute)
- `PR`: https://github.com/.../pull/N

Next step:
```
/work-impl {ID}          # FEAT/FIX/PERF/CHORE/TEST
/work-refactor {ID}      # REFAC
bash codex-run.sh {ID}   # unattended Codex
```

## Errors

- Branch exists: `ERROR: branch {BRANCH} already exists`
- Worktree exists: `ERROR: worktree {WT_PATH} already exists`
- Lock held: `ERROR: another /work-plan in progress`
- `gh` unauthenticated: `ERROR: run 'gh auth login'`
