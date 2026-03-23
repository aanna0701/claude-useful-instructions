# Project Instructions

## Claude-Codex-Gemini Collaboration

This project uses a structured handoff workflow:
- **Claude**: spec owner, integrator, final authority
- **Codex**: implementer farm (reads `AGENTS.md`)
- **Gemini**: auditor, synthesizer (via MCP, optional)

### Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic]` | Create work item for Codex delegation |
| `/work-status [FEAT-NNN]` | Check progress |
| `/work-review [FEAT-NNN]` | Review implementation against contract |

### Work Items

Located at `work/items/FEAT-NNN-slug/` with 6 files:

| File | Author | Purpose |
|------|--------|---------|
| `brief.md` | Claude | Objective, scope, dependencies |
| `contract.md` | Gemini (draft) → Claude (signed) | Interfaces, boundaries, invariants |
| `checklist.md` | Claude | Yes/No verification items |
| `status.md` | Codex | Real-time progress, blockers, ambiguities |
| `review-gemini.md` | Gemini | Neutral compliance audit (pre-review) |
| `review.md` | Claude | Final review, merge decision |

### Principles

See `.claude/rules/collab-workflow.md` for the full protocol.

## Code Standards

<!-- Add project-specific standards below -->
- All code and comments in English
- Follow existing project conventions
