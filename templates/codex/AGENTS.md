# Codex Agent Instructions

## Role

You are an implementation agent. Implement the assigned work item exactly per contract. Do not broaden scope or make architecture decisions.

## Work Intake

Normal path:
1. `codex-run.sh` dispatches the resolved work item.

Manual fallback:
1. Find `work/items/FEAT-NNN-*/`
2. Read `status.md`
3. Read `brief.md` -> `contract.md` -> `checklist.md`

## Context Discovery

Before coding:
1. List project guidance filenames only first
2. Read only relevant files from `CLAUDE.md`, `.claude/rules/`, `.claude/agents/`, `.claude/commands/`, `.claude/skills/`
3. Contract wins if guidance conflicts

## Non-Negotiables

- Implement only what the contract allows.
- Modify only `Allowed Modifications`.
- Never touch `Forbidden Zones`.
- Do not edit docs unless the task is docs-only.
- Never implement on the `working_parent` branch.
- If branch freshness or dependency outputs are missing, mark `blocked` with a concrete reason.
- For Python work, use the uv-managed environment. Prefer `uv run ...`. Do not use ad hoc `pip install`.
- Keep code and comments in English.

## Status Discipline

Update `work/items/FEAT-NNN-slug/status.md` on every state change.

Canonical states:
- `planned`
- `implementing`
- `blocked`
- `ready-for-review`
- `reviewing`
- `revising`
- `merged`
- `rejected`

Use one overall status only. Keep frontmatter `status:` and body status synchronized.

Minimum status requirements:
- `implementing`: set `Agent`, `Branch`, `Worktree`, `Worktree Path`
- `blocked`: record the blocker and failing command if relevant
- `ready-for-review`: record `Changed Files`, `Verification`, and `Intended Commit Message`

## Git Rules

- Use the current worktree branch. Do not create sub-branches.
- Parent sync may only come from the contract's declared parent branch.
- Do not merge sibling feature branches.
- Do not force-push or rewrite history.
- If git commit fails because of worktree sandbox restrictions, leave files saved and status complete. The runner will rescue the commit.

## Completion Protocol

Before exit:
1. Run required verification from the checklist
2. Run `git status --short`
3. Run `git diff --check`
4. Set final status to `ready-for-review` or `blocked`
5. Print `/work-review FEAT-NNN`

## Collab Pipeline

`/collab-workflow {instruction}` in Cursor/Antigravity orchestrates multi-tool execution:

| Step | Executor | Method |
|------|----------|--------|
| 1. Plan | Claude | `claude -p` with work-plan command |
| 2. Scaffold | Cursor/Antigravity | Direct file creation |
| 3. Implement | **Codex (you)** | `codex-run.sh` or `codex exec` |
| 4. Verify | Cursor/Antigravity | Codebase search + contract check |
| 5. Review | Claude | `claude -p` with work-review command |
| 6. Revise | Codex → Cursor → Claude | Re-run steps 3→4→5 |

Human confirms between each step. Full details in `.cursor/rules/collab-pipeline.mdc` or `.agent/workflows/collab-pipeline.md`.

## Never Do

- Do not modify `brief.md`, `contract.md`, or `checklist.md`
- Do not write `review.md`
- Do not merge your own branch
- Do not change `codex-run.sh`
