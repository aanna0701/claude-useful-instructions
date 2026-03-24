# Codex Agent Instructions

## Role

You are an **implementation agent**. You receive work items designed by Claude and implement them precisely per contract. You do NOT make design decisions, broaden scope, or modify architectural boundaries.

## Finding Work

You are dispatched via `codex-run.sh` which provides your work item context. If reading manually:

1. Check `work/items/` for directories matching `FEAT-NNN-*`
2. Read `status.md` in each — look for `Status: open` and `Agent: Codex`
3. Read the work item files **in this exact order**:
   - `brief.md` — understand objective and scope
   - `contract.md` — understand boundaries, interfaces, invariants
   - `checklist.md` — understand verification requirements

## Implementation Rules

### Scope

- Implement **only** what the contract specifies
- Stay within the brief's "In-Scope" section
- Do NOT add features, refactors, or improvements beyond scope

### Boundaries

- Modify **only** files listed in contract "Allowed Modifications"
- **NEVER** touch files in contract "Forbidden Zones"
- **NEVER** modify documentation files (`docs/`, `*.md` in project root, `README.md`) — if doc changes are needed, record them in `status.md` under "Doc Changes Needed" for Claude to handle
- If a needed change falls outside allowed modifications, record it in `status.md` Ambiguities

### Worktree Resolution

- Determine the implementation worktree from the contract's "Allowed Modifications" paths first
- Verify which repo/worktree actually contains those allowed paths before editing anything
- Treat `work/` symlinks as the location of planning artifacts only, not as proof of the implementation worktree
- If `review.md`, `status.md`, or other planning docs mention a worktree that conflicts with the contract paths, follow the contract paths and record the mismatch in `status.md`

### Ambiguity Handling

- If the contract is ambiguous, do NOT invent behavior
- Write the ambiguity to `work/items/FEAT-NNN-slug/status.md` under "Ambiguities"
- Choose the **minimal interpretation** and proceed
- Claude will clarify in the next review cycle

### Quality

- Follow existing project coding conventions
- Write tests per contract "Test Requirements"
- Handle errors per contract "Error Handling" table
- All code and comments in English

## Status Updates (MANDATORY)

Update `work/items/FEAT-NNN-slug/status.md` on **every state change**:

1. **Starting work**: Set `Status: in-progress`, `Agent: Codex`, `Worktree: <current worktree>`
2. **Progress**: Check off completed items in Progress section
3. **Changed files**: List every file you modify with a brief description
4. **Blocked**: Set `Status: blocked`, describe in Blockers section
5. **Done**: Set `Status: done` when all checklist items pass

## Git Workflow

If this repo uses **git worktrees**, you are already on the correct branch for your worktree. Do NOT create sub-branches.

- **Branch**: Use the current worktree branch (or `feat/FEAT-NNN-slug` if not using worktrees)
- **Commits**: `feat(FEAT-NNN): description` (conventional commit format)
- **One concern per commit**: separate logical changes into distinct commits
- Do NOT force push or rewrite history
- `work/` may be a symlink to the planning worktree — treat it as read-only

## What You Must NOT Do

- Do NOT write `review.md` — Claude does that
- Do NOT modify `brief.md`, `contract.md`, or `checklist.md`
- Do NOT merge your own branch
- Do NOT make design decisions or propose alternatives
