# work-plan — Create a Work Item (Local-Only)

Create one work item: contract + branch + worktree. **No GitHub PR.**

## Input

```
/work-plan                  # interactive: type, title, scope, acceptance
/work-plan "<title>"        # title hint, rest interactive
```

## Steps

1. **Clarify contract** with the user (one round of questions): goal, scope in/out, touchable globs, forbidden globs, acceptance criteria, risks. For REFAC also preserve list (public API, behavior invariants).
2. **Assign ID** `{TYPE}-{NNN}` from `.work/contracts/` counter (`TYPE ∈ {FEAT,FIX,PERF,CHORE,TEST,REFAC}`). Counter = max existing `{TYPE}-NNN` + 1.
3. **Derive slug** kebab-case ≤ 40 chars from title.
4. **Set branch** `feature-{type}-{slug}` (lowercase type, so `REFAC → refac`).
5. **Acquire lock** `.work/locks/planning.lock` via `flock`.
6. **Write contract** to `.work/contracts/{ID}-{slug}/contract.md` using `templates/work-item/contract.md`. The `.work/` tree is gitignored — contracts are local-only and disappear when the work item closes.
7. **Create branch + worktree + materialize contract**:
   ```bash
   PARENT="$(git rev-parse --abbrev-ref HEAD)"
   # Refuse to base a work item off the repo default branch when an integration
   # branch convention is in use locally. Override by checking out the
   # integration branch before running /work-plan.
   case "$PARENT" in
     main|master|HEAD)
       echo "ERROR: current branch '$PARENT' should not be a work-item parent."
       echo "       Checkout your integration branch first, e.g.:"
       echo "         git checkout feature-init-dev"
       exit 1
       ;;
   esac
   git branch "$BRANCH" "$PARENT"
   WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
   git worktree add "$WT_PATH" "$BRANCH"
   # MANDATORY: copy contract into the worktree so /work-impl + /work-review can see it.
   mkdir -p "$WT_PATH/.work/contracts/{ID}-{slug}"
   cp ".work/contracts/{ID}-{slug}/contract.md" "$WT_PATH/.work/contracts/{ID}-{slug}/contract.md"
   test -f "$WT_PATH/.work/contracts/{ID}-{slug}/contract.md" \
     || { echo "ERROR: contract not materialized in worktree"; exit 1; }
   ```
8. **First commit** in worktree (no push needed — contract lives in `.gitignore`d `.work/`):
   ```bash
   cd "$WT_PATH"
   # Empty marker commit so the branch has a divergence point. Contract is local-only
   # under .work/ and intentionally not committed.
   git commit -s --allow-empty -m "chore(plan): {ID} {title}"
   ```
9. **Optional push** — if `origin` exists and you want sync across machines:
   ```bash
   git push -u origin "$BRANCH" 2>/dev/null || true
   ```
   No PR is created. No CI runs.
10. **Release lock**.

## Output

Print:
- `ID`: FEAT-042
- `Branch`: feature-feat-user-auth
- `Worktree`: /abs/path (absolute)
- `Contract`: .work/contracts/FEAT-042-user-auth/contract.md (local-only)

Next step:
```
/work-impl {ID}          # FEAT/FIX/PERF/CHORE/TEST
/work-refactor {ID}      # REFAC
```

## Errors

- Branch exists: `ERROR: branch {BRANCH} already exists`
- Worktree exists: `ERROR: worktree {WT_PATH} already exists`
- Lock held: `ERROR: another /work-plan in progress`
