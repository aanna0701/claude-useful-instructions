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
7. **Create branch + worktree**:
   ```bash
   PARENT="$(git rev-parse --abbrev-ref HEAD)"
   git branch "$BRANCH" "$PARENT"
   WT_PATH="$(dirname "$REPO_ROOT")/${PROJECT}-${BRANCH}"
   git worktree add "$WT_PATH" "$BRANCH"
   mkdir -p "$WT_PATH/work/items/{ID}-{slug}"
   cp "work/items/{ID}-{slug}/contract.md" "$WT_PATH/work/items/{ID}-{slug}/contract.md"
   ```
8. **First commit + push** in worktree:
   ```bash
   cd "$WT_PATH"
   git add work/items/{ID}-{slug}/contract.md
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
