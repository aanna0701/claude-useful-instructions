# Claude-Codex-Gemini Collaboration

## Roles

- **Claude**: spec owner, integrator, final authority. Designs work items, reviews, merges.
- **Codex**: implementer farm. Implements per contract. Never makes design decisions.
- **Gemini**: auditor, synthesizer, spec normalizer (via MCP). Never modifies code or makes final decisions.

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic]` | Create work item (brief + contract + checklist + status) |
| `/work-status [FEAT-NNN]` | Check work item progress (all or specific) |
| `/work-review [FEAT-NNN]` | Review implementation against contract |

## Gemini MCP Tools

| Tool | Use When |
|------|----------|
| `gemini_summarize_design_pack` | Many RFC/ADR to compress before planning |
| `gemini_derive_contract` | Generate contract draft from design summary |
| `gemini_audit_implementation` | Neutral pre-review before Claude's /work-review |
| `gemini_compare_diffs` | Parallel tasks need cross-branch analysis |
| `gemini_draft_release_notes` | Document finalization after merge |

## Work Items

- Location: `work/items/FEAT-NNN-slug/`
- Files: `brief.md`, `contract.md`, `checklist.md`, `status.md`, `review.md`, `review-gemini.md`
- ID format: `FEAT-NNN` (3-digit, zero-padded, monotonic)

## Principles

- Contract is the single source of truth for implementation boundaries
- Claude is the only agent that can sign (approve) a contract
- Codex writes code + `status.md` only
- Gemini writes `review-gemini.md` + contract drafts only — Claude approves
- Ambiguities are recorded in `status.md`, never resolved by the implementer
- No feature implementation without a work item when delegating
- `review.md` required before merge
