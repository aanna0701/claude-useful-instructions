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

# 3. Scaffold with Cursor (NEW — optional)
/work-scaffold FEAT-001
# → Copy the printed prompt → Cursor Composer (Cmd+I)
# → Open worktree: cursor ../project-FEAT-001-payment/

# 4. Dispatch to Codex as usual
bash codex-run.sh FEAT-001

# 5. Verify with Cursor (NEW — optional)
/work-verify FEAT-001
# → Copy the printed prompt → Cursor Chat

# 6. Review and merge as usual
/work-review FEAT-001
```

---

## Scenario-Specific Workflows

### FEAT — New Feature

```
/work-plan → /work-scaffold → codex-run.sh → /work-verify → /work-review
  (계약)     (구조 전파)      (로직 채우기)   (정합성 검증)   (머지)
```

**Scaffold output**: File structure + type/interface definitions + function stubs with `TODO` bodies.

**Verify output**: Interface compliance, boundary violations, dependency conflicts, type safety, invariant compliance.

### REFACTOR — Code Restructuring

```
/work-plan → /work-scaffold → codex-run.sh → /work-verify → /work-review
  (계약)     (이동 맵)        (코드 이동)    (회귀 검증)     (머지)
```

**Scaffold output**: Before→after migration map + rename list + affected import references.

**Verify output**: Dead imports (old paths), broken calls, re-export coverage, test path references, config references.

### AUDIT — Code Audit / Consistency Check

```
/work-plan → /work-verify → (create issues or fix)
  (감사 범위)  (감사 실행)
```

**No scaffold or Codex needed.** AUDIT items go directly from planning to verification.

**Verify output**: @Codebase audit prompt with criteria from contract — naming conventions, security patterns, dead code, consistency violations.

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
4. Generates `.cursorrules` in the worktree root
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

## .cursorrules

`/work-scaffold` generates a `.cursorrules` file in the worktree root containing:

- **Forbidden Zones** from contract → "Never modify these files"
- **Allowed Modifications** → explicit file list
- **Coding conventions** from AGENTS.md
- **Tech stack** inferred from contract dependencies

This ensures Cursor follows the same contract boundaries as Codex.

---

## State Machine

The Cursor integration adds two optional states:

```
planned → [scaffolded] → implementing → ready-for-review → reviewing → merged
             ↑ optional

planned → auditing → audited   ← AUDIT only
```

- `scaffolded`: Set by `/work-scaffold`. `codex-run.sh` accepts both `planned` and `scaffolded`.
- `auditing`: Set by `/work-verify` for AUDIT items. No implementation phase.
- `audited`: Terminal state for AUDIT items.

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
| `cursorrules.md` | All | `/work-scaffold` |

---

## Without Cursor

Every workflow works without Cursor:

| Phase | With Cursor | Without Cursor |
|-------|-------------|----------------|
| Scaffold | Cursor Composer scaffolds structure | Codex creates files from scratch |
| Verify | Cursor @Codebase checks full project | Claude Code reviews in `/work-review` |
| Diff review | Cursor Side-by-Side diff | `git diff` in terminal |

Skip `/work-scaffold` and `/work-verify` — go directly from `/work-plan` to `codex-run.sh` to `/work-review`.
