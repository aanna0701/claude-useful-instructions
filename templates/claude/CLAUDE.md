# Project Instructions

## Claude-Codex Collaboration

This project uses a structured handoff workflow:
- **Claude**: spec owner, integrator, final authority
- **Codex**: implementer farm (reads `AGENTS.md`)

### Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic]` | Create work item for Codex delegation |
| `/work-status [FEAT-NNN]` | Check progress |
| `/work-review [FEAT-NNN]` | Review implementation against contract |

### Work Items

Located at `work/items/FEAT-NNN-slug/` with 5 files:

| File | Author | Purpose |
|------|--------|---------|
| `brief.md` | Claude | Objective, scope, dependencies |
| `contract.md` | Claude | Interfaces, boundaries, invariants |
| `checklist.md` | Claude | Yes/No verification items |
| `status.md` | Codex | Real-time progress, blockers, ambiguities |
| `review.md` | Claude | Final review, merge decision |

### Review And Refactor Policy

- Do not add a separate `work-refac` command by default.
- Review fixes stay on the same work item: Claude reviews with `/work-review`, then Codex applies required changes with `/work-revise`.
- Only create a new work item when refactoring exceeds the current contract boundary or deserves independent tracking as `REFACTOR-NNN` or `CHORE-NNN`.

### Principles

See `.claude/rules/collab-workflow.md` for the full protocol.

## Code Standards

<!-- Add project-specific standards below -->
- All code and comments in English
- Follow existing project conventions
