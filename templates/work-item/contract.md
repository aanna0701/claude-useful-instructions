# {ID}: {Title}

**Type**: FEAT | FIX | PERF | CHORE | TEST | REFAC

## Goal

One to two sentences. What does this item deliver?

## Scope

- **In**: what this item covers.
- **Out**: what is explicitly excluded.

## Boundaries

- **Touch** (globs the implementer may modify):
  - `src/path/**`
- **Forbidden** (must not be touched):
  - `src/other/**`
- **Preserve** (REFAC only — invariants that must not change):
  - Public exports of `src/path/index.ts`
  - Behavior covered by `tests/path/**`

## Acceptance

- [ ] Criterion 1
- [ ] Criterion 2

## Risks / Unknowns

- Risk or open question.
