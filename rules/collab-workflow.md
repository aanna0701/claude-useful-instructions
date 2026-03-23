# Claude-Codex-Gemini Collaboration

## Roles

- **Claude**: spec owner, integrator, final authority. Designs work items, reviews, merges.
- **Codex**: implementer farm. Implements per contract. Never makes design decisions.
- **Gemini**: auditor, synthesizer, spec normalizer (via MCP). Never modifies code or makes final decisions.

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic(s)]` | Create work item(s) — single or batch with parallel agent generation |
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
- Dispatch manifest: `work/dispatch.json` (parallel groups, dependencies, conflicts)
- ID format: `FEAT-NNN` (3-digit, zero-padded, monotonic)

## Parallel Execution

Multiple Codex instances can implement different FEAT items concurrently when their contract boundaries don't overlap.

### Boundary Overlap Check

Before parallel dispatch, `/work-plan` automatically checks that "Allowed Modifications" paths across contracts don't intersect. If they do, conflicting items are placed in sequential groups.

### Dispatch

```bash
codex-dispatch.sh FEAT-001 FEAT-002 FEAT-003   # Check + dispatch
codex-dispatch.sh --check FEAT-001 FEAT-002     # Boundary check only
codex-dispatch.sh --status                       # Show open items
codex-dispatch.sh --from-manifest                # Use work/dispatch.json groups
```

### Rules

- Items in the same parallel group: independent boundaries, safe to run simultaneously
- Items in different groups: must run sequentially (boundary overlap or explicit dependency)
- `work/dispatch.json` is the source of truth for dispatch ordering
- Each Codex instance runs in its own terminal / worktree

## Worktree Layout (optional)

When the project uses **git worktrees** for feature isolation, each worktree maps to a collaboration role.

```
workspace/
├── <Project>-Docs       (feature-docs)          ← Claude plans here
│   └── work/items/FEAT-NNN-slug/                ← source of truth
├── <Project>-Training   (feature-training)       ← Codex implements here
│   └── work/ -> ../<Project>-Docs/work (symlink) ← reads plans via symlink
├── <Project>-Inference  (feature-inference)
└── <Project>-UI         (feature-ui)
```

### work/ Symlink Convention

- The **docs worktree** owns `work/items/` (real directory, committed to git)
- All other worktrees get `work/` as a **symlink** pointing to the docs worktree's `work/`
- Symlinks are `.gitignore`d — they never get committed to feature branches
- Codex can read `work/items/FEAT-NNN/contract.md` from any worktree

### Managing Links

```bash
link-work.sh                            # Link all worktrees
link-work.sh training                   # Link specific worktree
link-work.sh --status                   # Show link status
link-work.sh --init <name> <branch>     # Create worktree + link + gitignore
link-work.sh --self-install             # Install as: git work-link
```

### End-to-End Handoff Flow

```
1. Claude (Docs)       /work-plan [topic]         → creates work/items/FEAT-NNN/
2. Gemini (MCP)        gemini_derive_contract      → drafts contract.md
3. Claude (Docs)       signs contract.md           → work item ready
4. User                link-work.sh                → symlinks work/ to impl worktrees
5. Codex (Training)    reads work/items/FEAT-NNN/  → implements on worktree branch
6. Codex (Training)    updates status.md           → marks done
7. Gemini (MCP)        gemini_audit_implementation → writes review-gemini.md
8. Claude (Docs)       /work-review FEAT-NNN       → writes review.md, merge decision
```

## Principles

- Contract is the single source of truth for implementation boundaries
- Claude is the only agent that can sign (approve) a contract
- Codex writes code + `status.md` only
- Gemini writes `review-gemini.md` + contract drafts only — Claude approves
- Ambiguities are recorded in `status.md`, never resolved by the implementer
- No feature implementation without a work item when delegating
- `review.md` required before merge
- In worktree setups: Codex commits directly on the worktree branch, no sub-branches
- `work/` symlinks keep all worktrees in sync without cross-branch cherry-picks
