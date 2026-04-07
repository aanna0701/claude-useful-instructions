# Cursor Integration Guide

> **Doc type**: How-to | **Audience**: Developers using the Claude-Codex collab workflow

The Cursor integration adds two optional phases to the collab workflow: **structure scaffolding** (Cursor Composer) and **codebase verification** (Cursor Chat @Codebase).

---

## Why Cursor?

Cursor fills three gaps in the Claude Code + Codex workflow:

| Gap | Cursor Feature | How It Helps |
|-----|---------------|--------------|
| Multi-file structure creation | **Composer** (Cmd+I) | Scaffolds directories, types, and stubs across many files at once |
| Full codebase context | **@Codebase** in Chat | Verifies implementation against the entire project, not just changed files |
| Visual diff review | **Side-by-Side Diff** | See AI-proposed changes before accepting — final approval desk |

**Cursor is optional.** All workflows work without it. The commands gracefully skip or redirect when Cursor isn't in use.

---

## Quick Start

```bash
# 1. Install collab bundle (includes Cursor templates)
./install.sh --collab /path/to/project

# 2. Plan work items as usual
/work-plan "Add payment module"

# 3. Scaffold with Cursor (optional)
/work-scaffold FEAT-001
# → Copy the printed prompt → Cursor Composer (Cmd+I)
# → Open worktree: cursor ../project-FEAT-001-payment/
# → .cursor/rules/*.mdc auto-enforces contract boundaries

# 4. Dispatch to Codex as usual
bash codex-run.sh FEAT-001

# 5. Verify with Cursor (optional)
/work-verify FEAT-001
# → Copy the printed prompt → Cursor Chat
# → After Cursor responds:
/work-verify FEAT-001 --ingest
# → Paste Cursor output → auto-parsed → PASS/FAIL verdict

# 6. Review and merge as usual
/work-review FEAT-001
```

---

## Scenario-Specific Workflows

### FEAT — New Feature

```
/work-plan → /work-scaffold → codex-run.sh → /work-verify [--ingest] → /work-review
  (계약)     (구조+룰 전파)   (로직 채우기)   (검증 + 결과 파싱)         (머지)
```

**Scaffold**: File structure + type stubs + `.cursor/rules/*.mdc` (contract auto-enforcement).

**Verify**: Prompt generation → Cursor Chat → `--ingest` parses results → PASS/FAIL → auto-route.

### REFACTOR — Code Restructuring

```
/work-plan → /work-scaffold → codex-run.sh → /work-verify [--ingest] → /work-review
  (계약)     (이동 맵+룰)     (코드 이동)    (검증 + 결과 파싱)         (머지)
```

**Scaffold**: Migration map + rename list + `.cursor/rules/*.mdc`.

**Verify**: Regression check → `--ingest` parses findings → auto-route.

### AUDIT — Code Audit / Consistency Check

```
/work-plan → /work-verify [--ingest] → (create issues or fix)
  (감사 범위)  (감사 실행 + 결과 파싱)
```

**No scaffold or Codex needed.** AUDIT items go directly from planning to verification.

**Verify**: @Codebase audit → `--ingest` parses findings → `audited` status.

---

## Commands

### `/work-scaffold`

Generates a Cursor Composer prompt from work item contracts.

```
/work-scaffold FEAT-001              # New feature scaffold
/work-scaffold REFAC-002             # Refactoring migration map
/work-scaffold FEAT-001 REFAC-002    # Multiple items
/work-scaffold AUDIT-003             # → prints "skip, use /work-verify"
```

**What it does**:
1. Reads `brief.md` and `contract.md` from the work item
2. Auto-detects type from ID prefix (FEAT/REFAC/AUDIT)
3. Fills the type-specific template with contract data
4. Generates `.cursor/rules/*.mdc` in the worktree
5. Updates `status.md` → `scaffolded`
6. Prints the prompt for clipboard copy

### `/work-verify`

Generates a Cursor Chat `@Codebase` verification prompt.

```
/work-verify FEAT-001               # Implementation verification
/work-verify REFAC-002              # Regression verification
/work-verify AUDIT-003              # Standalone codebase audit
```

**What it does**:
1. Reads `status.md`, `brief.md`, and `contract.md`
2. Auto-detects type from ID prefix
3. Fills the type-specific verification template
4. Prints the prompt for clipboard copy

---

## Cursor Rules

`/work-scaffold` generates `.cursor/rules/*.mdc` in the worktree — glob-based rules that Cursor applies automatically:

| File | Trigger | Purpose |
|------|---------|---------|
| `{SLUG}-guard.mdc` | Editing files matching allowed modifications | Shows contract boundaries, interfaces, invariants |
| `{SLUG}-forbidden.mdc` | Opening files in forbidden zones | Warns that the file is outside contract scope |

**How it works**: Cursor reads `.cursor/rules/*.mdc` files and matches the `globs` frontmatter against the file being edited. When a match is found, the rule content is injected into Cursor's context automatically — no manual prompt copy needed.

Example generated `FEAT-001-guard.mdc`:
```
---
description: "FEAT-001 contract boundary enforcement — Add JWT authentication"
globs: ["src/auth/**", "tests/auth/**"]
---

# FEAT-001 — Contract boundaries
## Allowed Modifications
- src/auth/
- tests/auth/

## Forbidden Zones — DO NOT MODIFY
- src/core/database.py — shared infrastructure
- src/models/base.py — base model definitions
...
```

Cursor reads these files and matches the `globs` frontmatter against the file being edited — no manual prompt copy needed.

---

## State Machine

The Cursor integration adds optional states and transitions:

```
planned → [scaffolded] → implementing → [verified] → ready-for-review → reviewing → merged
             ↑ optional                    ↑ optional
             (.cursor/rules/ generated)    (/work-verify --ingest PASS)

planned → auditing → audited   ← AUDIT only (/work-verify --ingest PASS)
```

- `scaffolded`: Set by `/work-scaffold`. Generates `.cursor/rules/*.mdc`. `codex-run.sh` accepts both `planned` and `scaffolded`.
- `verified`: Set by `/work-verify --ingest` on PASS verdict. Optional — can go directly to `ready-for-review`.
- `auditing`: Set by `/work-verify` for AUDIT items. No implementation phase.
- `audited`: Set by `/work-verify --ingest` for AUDIT items on PASS verdict.

---

## Verify Result Ingestion

After running `/work-verify` and getting Cursor's output, run `/work-verify --ingest` to parse the results:

```
/work-verify FEAT-001
# → Copy prompt → Cursor Chat → get results

/work-verify FEAT-001 --ingest
# → Paste Cursor output → auto-parsed → verdict + routing
```

The `--ingest` mode:
1. Parses structured findings (table format from verify templates)
2. Saves to `work/items/{ID}-*/verify-result.md`
3. Auto-determines verdict: PASS / PASS_WITH_WARNINGS / FAIL
4. Routes to next action:
   - **PASS**: status → `ready-for-review`, suggests `/work-review`
   - **PASS_WITH_WARNINGS**: user chooses proceed or revise
   - **FAIL**: suggests `/work-revise` (CRITICAL findings must be resolved)

For AUDIT items, PASS routes to `audited` status with options to create issues or plan fixes.

---

## Templates

Located in `.claude/templates/cursor/`:

| Template | Type | Used By |
|----------|------|---------|
| `scaffold-feat.md` | FEAT | `/work-scaffold` |
| `scaffold-refactor.md` | REFAC | `/work-scaffold` |
| `verify-feat.md` | FEAT | `/work-verify` |
| `verify-refactor.md` | REFAC | `/work-verify` |
| `verify-audit.md` | AUDIT | `/work-verify` |
| `contract-guard.mdc.md` | All | `/work-scaffold` |
| `boundary-alert.mdc.md` | All | `/work-scaffold` |
| `cursorrules.md` | _(reference only)_ | _(not generated by default)_ |

---

## Without Cursor

Every workflow works without Cursor:

| Phase | With Cursor | Without Cursor |
|-------|-------------|----------------|
| Scaffold | Cursor Composer scaffolds structure | Codex creates files from scratch |
| Rules | `.cursor/rules/*.mdc` auto-enforces contract | Codex relies on AGENTS.md boundaries |
| Verify | Cursor @Codebase checks + `--ingest` parses | Claude Code reviews in `/work-review` |
| Diff review | Cursor Side-by-Side diff | `git diff` in terminal |

Skip `/work-scaffold` and `/work-verify` — go directly from `/work-plan` to `codex-run.sh` to `/work-review`.
