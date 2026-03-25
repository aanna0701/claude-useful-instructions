# Claude-Codex Collaboration

## 2-Touch Workflow

```
/work-plan → codex-run.sh (TOUCH 1) → /work-review (TOUCH 2)
```

## Roles

- **Claude**: spec owner, integrator — designs work items, reviews, merges, handles doc changes
- **Codex**: implementer — per contract only, never modifies docs (records in `status.md`)

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic(s)]` | Create work item(s) with parallel agents + boundary check |
| `/work-status [FEAT-NNN]` | Check progress |
| `/work-review [FEAT-NNN ...]` | Review → merge + branch cleanup |

## Work Items

- Location: `work/items/FEAT-NNN-slug/`
- Files: `brief.md`, `contract.md`, `checklist.md`, `status.md`, `review.md`
- Dispatch: `work/dispatch.json` (parallel groups + dependencies)

## Parallel Execution

- `/work-plan` auto-splits topics into parallelizable FEATs with disjoint boundaries
- Boundary overlap check runs before dispatch — overlapping items grouped sequentially
- `codex-run.sh` handles: boundary check → worktree link → parallel `codex exec` → monitor → output `/work-review`

## Worktree Convention

- Docs worktree owns `work/items/` (real directory)
- Other worktrees get `work/` as symlink (`.gitignore`d)
- `link-work.sh` manages symlinks; `post-checkout` hook auto-links
- Implementation worktree is resolved from contract "Allowed Modifications" paths, not from the location of `work/`
- `work/` symlinks are planning-artifact links only; they do not redefine where Codex must implement
- If planning docs mention a worktree that conflicts with the contract paths, the contract paths win
- **Review worktree rule**: `/work-review` MUST read files and run tests from the `Worktree Path` in `status.md`, not from the current cwd

## Branch Map Integration

- Read `.claude/branch-map.yaml` before creating branches or merging
- If missing during `/work-plan` or `/work-review`, auto-initialize via `/branch-init` logic
- Contracts carry branch metadata: role, parent branch, merge target, CI scope
- Merge target comes from contract's Branch Map section, never hardcoded
- See `rules/branch-map-policy.md` for full branch selection rules

## Principles

- Contract = single source of truth for boundaries
- Claude signs contracts; Codex implements
- Codex: code + `status.md` only — **never docs**; records doc needs in "Doc Changes Needed"
- Ambiguities recorded in `status.md`, never resolved by implementer
- `review.md` required before merge
- On `REVISE`, the latest `review.md` becomes the mandatory delta for the next Codex run; every `MUST-fix` item must be injected into the re-dispatch prompt and resolved before optional work
- MERGE decision: ask user → merge into declared `merge_target` → `git branch -d` → apply doc changes → remove work item dir
- Worktree setups: commit on worktree branch, no sub-branches
- Human intervention: dispatch + review only
