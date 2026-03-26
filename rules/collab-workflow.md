# Claude-Codex Collaboration

## 2-Touch Workflow

```
/work-plan → codex-run.sh (TOUCH 1: impl + push + draft PR) → /work-review (TOUCH 2: review existing PR)
```

## Roles

- **Claude**: spec owner, integrator — designs work items, reviews, merges, handles doc changes
- **Codex**: implementer — per contract only, never modifies docs (records in `status.md`)

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic(s)]` | Create work item(s) with parallel agents + boundary check |
| `/work-status [FEAT-NNN]` | Check progress |
| `/work-review [FEAT-NNN ...]` | Review existing PR → merge or revise |

## Work Items

- Location: `work/items/FEAT-NNN-slug/`
- Files: `brief.md`, `contract.md`, `checklist.md`, `status.md`, `review.md`
- Dispatch: `work/dispatch.json` (parallel groups + dependencies)

## Parallel Execution

- `/work-plan` auto-splits topics into parallelizable FEATs with disjoint boundaries
- Boundary overlap check runs before dispatch — overlapping items grouped sequentially
- `codex-run.sh` handles: boundary check → seed artifacts → parallel `codex exec` → monitor → verify commits → push + draft PR → output `/work-review`

## Worktree Convention

- `/work-plan` auto-creates a worktree per FEAT: `../${PROJECT}-${SLUG}`
- Implementation location is resolved from `status.md` Worktree Path (contract paths win over planning docs)
- `/work-review` reads files and runs tests from `Worktree Path` in `status.md`, not cwd
- On MERGE, worktree is removed via `git worktree remove`

## Worktree Routing

- Resolve implementation location from contract "Allowed Modifications" paths first.
- Fall back to `roles[].paths` in `branch-map.yaml` for worktree selection.
- If paths conflict between planning docs and contract, contract wins.
- Cross-cutting tasks that span multiple roles: split into separate work items or mark sequential.

## CI Scope Verification

- If a work item contract has a `CI Scope` field, `/work-review` verifies that matching CI workflows exist and their checks are green before merge.

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
- Draft PR creation happens at implementation stage (`/work-impl` or `codex-run.sh`), not at review stage
- MERGE decision: ask user → review existing draft PR → `gh pr merge` → apply doc changes → cleanup worktree + work item dir
- Worktree setups: commit on worktree branch, no sub-branches
- Human intervention: dispatch + review only
