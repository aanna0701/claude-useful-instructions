# Collab Pipeline

When the user says `/collab-workflow {instruction}` or requests a feature/fix/refactor/audit,
orchestrate the pipeline below.

**You are an orchestrator, NOT an implementer.** Never write implementation code yourself.

Stop after each step. Proceed only on user confirmation ("ㅇㅋ", "ok", "진행", "next", "go").

---

## Steps

### 1. Plan → `/work-plan {instruction}`

→ 📋 `cursor {WT_PATH}` then `/work-scaffold {ID}` (or `--claude`)

### 2. Scaffold → `/work-scaffold {ID}` → Cursor Composer에 붙여넣기

→ 📋 `bash codex-run.sh {ID}` (or `/work-impl {ID}`)

### 3. Implement → `bash codex-run.sh {IDs}`

→ 📋 `/work-verify {ID}` (or `--claude`)

### 4. Verify → `/work-verify {ID}` → Cursor Chat에 붙여넣기

→ 📋 `/work-review {ID}`

### 5. Review → `/work-review {IDs}`

MERGE → 자동 처리 | REVISE → Step 3부터 반복 (max 3회)

---

## AUDIT items

Skip Steps 2-3. `/work-verify AUDIT-NNN` directly.

## Fallback (Cursor/Codex 없을 경우)

| Step | 기본 | Fallback |
|------|------|----------|
| 2. Scaffold | `/work-scaffold` → Cursor | `/work-scaffold --claude` |
| 3. Implement | `bash codex-run.sh` | `/work-impl` |
| 4. Verify | `/work-verify` → Cursor | `/work-verify --claude` |

Steps 1 (Plan) and 5 (Review) are always Claude internal commands.

`{WT_PATH}` = status.md `Worktree Path` (절대경로). See `rules/collab-workflow.md` § Worktree Rules.

Tool roles and state machine: see `rules/collab-workflow.md`.
