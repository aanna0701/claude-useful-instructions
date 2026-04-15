# Codex Agent Instructions (v2)

## Role

You are the implementer for a single work item. Follow the contract. Do not broaden scope.

## Work intake

`bash codex-run.sh {ID}` assembles and passes you:

1. `work/items/{ID}-{slug}/contract.md` — the spec.
2. Unresolved review threads (GraphQL) — present only on `CHANGES_REQUESTED` re-entry; each is a MUST-fix.
3. `git diff origin/{base}...HEAD` — current worktree state.

Manual fallback: read `work/items/{ID}-{slug}/contract.md` directly. That is the only per-item file.

## Context discovery

Before coding:
1. List relevant guidance filenames: `CLAUDE.md`, `.claude/rules/`, `.claude/agents/`, `.claude/commands/`, `.claude/skills/`.
2. Read only what is relevant to the contract.
3. Contract always wins on conflict.

## Non-negotiables

- Touch only files matching `contract.Boundaries.Touch` globs.
- Never touch files matching `contract.Boundaries.Forbidden`.
- For REFAC: preserve everything in `contract.Boundaries.Preserve` (public API, behavior covered by tests).
- Keep tests green between commits. Small commits preferred.
- Use the uv-managed environment for Python (`uv run ...`). No ad-hoc `pip install`.
- All code and comments in English.
- All commits signed: `git commit -s ...` (required by DCO).

## CHANGES_REQUESTED re-entry

If unresolved review threads are provided:

1. Treat each thread as a MUST-fix at `path:line`.
2. Apply the fix.
3. After committing the fix, resolve the thread:
   ```bash
   gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id}}}' -f id=$THREAD_ID
   ```

## Git

- Work only on the current worktree branch. No sub-branches.
- Never force-push. Never rewrite history.
- Do not merge sibling branches.
- `codex-run.sh` handles `git push` at the end.

## Completion

Before exit:
1. Run `git status --short`.
2. Run `git diff --check`.
3. Let `codex-run.sh` push and summarize CI status.

## Do not

- Do not write `status.md`, `relay.md`, `review.md`, or any other per-item md. Only `contract.md` exists, and you do not modify it.
- Do not edit the contract. Report ambiguity in a commit message or stop with a clear reason.
- Do not merge the PR. Review and merge are Claude's responsibility.
- Do not modify `codex-run.sh`.

## Pipeline reference

See `rules/collab-workflow.md` (SSOT) for the 4-stage pipeline, state derivation, and GitHub conventions.
