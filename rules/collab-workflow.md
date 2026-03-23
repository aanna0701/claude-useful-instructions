# Claude-Codex-Gemini Collaboration

## 2-Touch Workflow

Human intervention is minimized to exactly **2 points**:

```
Claude: /work-plan topic1, topic2, topic3
  → generates work items, boundary check, dispatch manifest
                                        ↓
Human: bash codex-dispatch.sh FEAT-001 FEAT-002 FEAT-003    ← TOUCH 1
  → auto: boundary check → worktree link → parallel codex exec → monitor
  → prints: /work-review FEAT-001 FEAT-002 FEAT-003
                                        ↓
Human: /work-review FEAT-001 FEAT-002 FEAT-003               ← TOUCH 2
  → Claude reviews, merges, handles doc changes
```

## Roles

- **Claude**: spec owner, integrator, final authority. Designs work items, reviews, merges, handles doc changes.
- **Codex**: implementer farm. Implements per contract. Never makes design decisions. Never modifies docs — records needed doc changes in `status.md`.
- **Gemini**: auditor, synthesizer, spec normalizer (via MCP). Never modifies code or makes final decisions.

## Commands

| Command | Action |
|---------|--------|
| `/work-plan [topic(s)]` | Create work item(s) — batch with parallel agents + boundary check |
| `/work-status [FEAT-NNN]` | Check work item progress (all or specific) |
| `/work-review [FEAT-NNN ...]` | Review implementation(s) — batch with parallel agents |

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
Claude:  /work-plan [topic(s)]         → work items + boundary check + dispatch manifest
Human:   bash codex-dispatch.sh FEAT-* → boundary check → link worktrees → parallel codex → monitor
Codex:   implements per contract        → updates status.md → marks done
Human:   /work-review FEAT-*           → paste into Claude
Claude:  reviews + handles doc changes → MERGE / REVISE / REJECT
```

## Principles

- Contract is the single source of truth for implementation boundaries
- Claude is the only agent that can sign (approve) a contract
- Codex writes code + `status.md` only — **never modifies docs**
- If Codex needs doc changes, it records them in `status.md` "Doc Changes Needed"
- Claude handles all doc changes during review phase
- Gemini writes `review-gemini.md` + contract drafts only — Claude approves
- Ambiguities are recorded in `status.md`, never resolved by the implementer
- No feature implementation without a work item when delegating
- `review.md` required before merge
- In worktree setups: Codex commits directly on the worktree branch, no sub-branches
- `work/` symlinks keep all worktrees in sync without cross-branch cherry-picks
- Human intervention limited to 2 touch points: dispatch + review
