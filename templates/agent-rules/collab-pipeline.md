---
description: Guide for handling feature/fix/refactor/audit requests (Collab Pipeline)
---

# Collab Pipeline

User requests a feature/fix/refactor/audit → follow these steps.
Stop after each step. Proceed on user confirmation ("ㅇㅋ", "ok", "진행", "next").

## Steps

1. **Plan** — `claude -p "Read .claude/commands/work-plan.md and follow it. Topic: {TOPIC}" --output-format json`
   → Report: ID, scope, estimated files. **"계획 확인해주세요"**

2. **Scaffold** — Read `work/items/{ID}-*/contract.md` → create dirs + stubs per Allowed Modifications
   → Report: created files. **"구조 확인해주세요"**

3. **Implement** — `bash codex-run.sh {IDs}` (or implement directly if codex unavailable)
   → Report: status, checklist pass/fail, changed files. **"구현 결과 확인해주세요"**

4. **Verify** — Full codebase search: check contract boundaries, interfaces, invariants, test requirements
   → Report: violations found. **"검증 결과 확인해주세요"**

5. **Review** — `claude -p "Read .claude/commands/work-review.md and follow it. Target: {IDs}" --output-format json`
   → MERGE: **"머지할까요?"** / REVISE: **"수정 진행할까요?"**

6. **Revise** (REVISE only) — Re-run steps 3→4→5 with review.md fixes injected.
   - Max 3 rounds. Same MUST-fix unresolved 2x → stop, request manual intervention.

## AUDIT items

Skip steps 2-3. Step 4 becomes the audit execution per contract criteria.
Report findings with severity (CRITICAL/HIGH/MEDIUM/LOW). **"감사 결과 확인해주세요"**
