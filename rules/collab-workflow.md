# Claude-Codex-Gemini Collaboration

## 2-Touch Workflow

```
/work-plan → codex-run.sh (TOUCH 1) → /work-review (TOUCH 2)
```

## Roles

- **Claude**: spec owner, integrator — designs work items, reviews, merges, handles doc changes
- **Codex**: implementer — per contract only, never modifies docs (records in `status.md`)
- **Gemini**: auditor (via MCP) — drafts contracts, audits implementations, never modifies code

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic(s)]` | Create work item(s) with parallel agents + boundary check |
| `/work-status [FEAT-NNN]` | Check progress |
| `/work-review [FEAT-NNN ...]` | Review → merge + branch cleanup |

## Work Items

- Location: `work/items/FEAT-NNN-slug/`
- Files: `brief.md`, `contract.md`, `checklist.md`, `status.md`, `review.md`, `review-gemini.md`
- Dispatch: `work/dispatch.json` (parallel groups + dependencies)

## Parallel Execution

- `/work-plan` auto-splits topics into parallelizable FEATs with disjoint boundaries
- Boundary overlap check runs before dispatch — overlapping items grouped sequentially
- `codex-run.sh` handles: boundary check → worktree link → parallel `codex exec` → monitor → output `/work-review`

## Worktree Convention

- Docs worktree owns `work/items/` (real directory)
- Other worktrees get `work/` as symlink (`.gitignore`d)
- `link-work.sh` manages symlinks; `post-checkout` hook auto-links

## Principles

- Contract = single source of truth for boundaries
- Claude signs contracts; Codex implements; Gemini audits
- Codex: code + `status.md` only — **never docs**; records doc needs in "Doc Changes Needed"
- Ambiguities recorded in `status.md`, never resolved by implementer
- `review.md` required before merge
- MERGE decision: ask user → `git merge` → `git branch -d` → apply doc changes → remove work item dir
- Worktree setups: commit on worktree branch, no sub-branches
- Human intervention: dispatch + review only
