# Claude-Codex-Gemini Collaboration Workflow

> **Doc type**: Explanation + Tutorial | **Audience**: Developers setting up multi-agent workflows

The `collab` bundle enables structured handoff between **Claude** (design/review), **Codex** (implementation), and **Gemini** (audit/synthesis via MCP).

---

## Roles

| Agent | Role | Writes |
|-------|------|--------|
| **Claude** | spec owner, integrator, final authority | brief, contract (signed), review.md |
| **Codex** | implementer farm | code, status.md |
| **Gemini** | auditor, synthesizer, spec normalizer | review-gemini.md, contract (draft) |

## 2-Touch Workflow

Human intervention is minimized to exactly **2 points**:

```
Claude: /work-plan topic1, topic2, topic3
  → parallel agent generation + boundary check + dispatch manifest
                                          ↓
TOUCH 1 — Human: bash codex-run.sh FEAT-001 FEAT-002 FEAT-003
  → auto: boundary check → link worktrees → parallel codex exec → monitor
  → Codex implements per contract, records doc changes in status.md
  → prints: /work-review FEAT-001 FEAT-002 FEAT-003
                                          ↓
TOUCH 2 — Human: /work-review FEAT-001 FEAT-002 FEAT-003
  → Claude reviews in parallel, handles doc changes, merges
```

## Architecture

```mermaid
graph LR
    subgraph "1 Claude — Design"
        A["/work-plan\n(parallel agents)"] --> G1["Gemini MCP\nsummarize + derive"]
        G1 --> B["work items +\nboundary check"]
        A -.->|no Gemini| B
    end

    subgraph "2 codex-run.sh"
        B --> BC["boundary check\n+ worktree link"]
        BC --> D["codex exec ×N\n(parallel)"]
        D --> E["code +\nstatus.md"]
    end

    subgraph "3 Claude — Review"
        E --> G2["Gemini MCP\naudit"]
        G2 --> F["/work-review\n(parallel agents)"]
        E -.->|no Gemini| F
        F --> H["review.md\nMERGE / REVISE / REJECT"]
        F --> DOC["doc changes\n(from status.md)"]
    end

    H -.->|REVISE| D
```

---

## Setup

### Step 1: Install collab bundle

```bash
./install.sh --collab /path/to/project
```

This installs everything: `.claude/` artifacts, `AGENTS.md`, `CLAUDE.md`, scripts (`codex-run.sh`, `link-work.sh`), and the Gemini MCP server. Creates `work/items/` directory.

### Step 2: Set up Gemini MCP (optional)

```bash
# 1. Get a Gemini API key → https://aistudio.google.com/apikey
# 2. Set environment variable (add to ~/.bashrc or ~/.zshrc)
export GEMINI_API_KEY='your-api-key-here'

# 3. Run setup (installs deps, auto-registers MCP config)
bash gemini-setup.sh /path/to/project
```

The script automatically registers the MCP server and permissions in `.claude/settings.local.json`. If `gemini-review` is already registered, the step is skipped.

Override the model with `GEMINI_MODEL` (default: `gemini-2.5-pro`):
```bash
export GEMINI_MODEL='gemini-2.5-flash'  # cheaper, faster
```

### Step 4: Set up worktree links (if using git worktrees)

If the project uses git worktrees to isolate feature branches:

```bash
# From any worktree in the repo:
bash link-work.sh              # Link work/ to all worktrees
bash link-work.sh training     # Link to specific worktree (partial match)
bash link-work.sh --status     # Show symlink status
```

Optionally install as a git alias:
```bash
bash link-work.sh --self-install   # Registers: git work-link
git work-link --status             # Use from anywhere
```

Create a new worktree with work/ pre-linked:
```bash
bash link-work.sh --init VasIntelli-Eval feature-eval
```

### Installed Layout

```
project/
├── AGENTS.md                          # Codex reads this
├── CLAUDE.md                          # Claude reads this
├── codex-run.sh                       # Codex runner (single + parallel + boundary check)
├── gemini-setup.sh                    # Gemini MCP setup script
├── link-work.sh                       # Worktree symlink manager
├── mcp/gemini-review/                 # Gemini MCP server
│   ├── server.py                      #   5 tools wrapping Gemini API
│   ├── prompts.py                     #   System prompts per tool
│   └── pyproject.toml                 #   Dependencies (mcp, google-generativeai)
├── work/items/                        # Shared workspace (created by install.sh)
├── work/dispatch.json                 # Parallel dispatch manifest (created by /work-plan)
└── .claude/
    ├── rules/collab-workflow.md       # Auto-loaded 3-agent rules
    ├── commands/work-{plan,review,status}.md
    ├── skills/collab-workflow/
    └── templates/work-item/*.md       # Brief, contract, checklist, status, review, review-gemini
```

The `post-checkout` hook is also installed to `.git/hooks/`, auto-linking `work/` when switching branches in new worktrees.

---

## Worktree Support

When a repo uses **git worktrees** for feature isolation, each worktree maps to a collaboration role:

```
workspace/
├── Project-Docs       (feature-docs)          ← Claude plans here
│   └── work/items/FEAT-NNN-slug/              ← source of truth (real directory)
├── Project-Training   (feature-training)       ← Codex implements here
│   └── work/ → ../Project-Docs/work (symlink) ← reads plans via symlink
├── Project-Inference  (feature-inference)
└── Project-UI         (feature-ui)
```

### How it works

- The **docs worktree** owns `work/items/` as a real, git-tracked directory
- All other worktrees get `work/` as a **symlink** pointing to the docs worktree
- Symlinks are auto-added to `.gitignore` — never committed to feature branches
- When Claude updates a plan in Docs, Codex sees the change immediately in Training
- Codex commits directly on its worktree branch — no sub-branches needed

### Commands

| Command | Description |
|---------|-------------|
| `link-work.sh` | Link `work/` to all worktrees |
| `link-work.sh <filter>` | Link to matching worktree (partial match) |
| `link-work.sh --status` | Show link status across all worktrees |
| `link-work.sh --clean` | Remove all `work/` symlinks |
| `link-work.sh --init <name> <branch>` | Create new worktree + link + gitignore |
| `link-work.sh --self-install` | Install as `git work-link` alias |

### End-to-end flow with worktrees

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

> Step 4 is only needed once per worktree. The `post-checkout` hook auto-links on subsequent branch switches.

---

## Parallel Codex Execution

`/work-plan` natively supports multiple topics — they are planned in parallel using concurrent agents, and the system automatically validates that their boundaries don't conflict.

### How it works

1. **Batch planning**: Pass multiple topics to `/work-plan` → each gets its own FEAT item, generated in parallel
2. **Boundary check**: After contracts are generated, the system checks that "Allowed Modifications" paths don't overlap between any pair of items
3. **Dispatch grouping**: Items with no boundary overlap are grouped for parallel execution; conflicting items are placed in sequential groups
4. **Dispatch manifest**: `work/dispatch.json` records parallel groups, dependencies, and conflicts

### Dispatch commands

```bash
# Check boundaries + print parallel dispatch commands
bash codex-run.sh FEAT-001 FEAT-002 FEAT-003

# Boundary check only (dry run)
bash codex-run.sh --check FEAT-001 FEAT-002

# Dispatch from manifest (respects parallel groups)
bash codex-run.sh --from-manifest

# Show all open work items
bash codex-run.sh --status
```

### Boundary matrix example

```
Boundary Check
──────────────────────────────────────────────
          FEAT-001    FEAT-002    FEAT-003
FEAT-001     —           ✓           ✓
FEAT-002     ✓           —           ⚠ OVERLAP
FEAT-003     ✓           ⚠ OVERLAP   —

⚠ FEAT-002 × FEAT-003: both modify src/utils/logger.py
```

Items with overlaps must run sequentially. The dispatch script enforces this automatically.

### Parallel execution with worktrees

Each Codex instance runs in its own terminal. With worktrees, each can also use its own worktree branch:

```bash
# Terminal 1 (VasIntelli-Training):
bash codex-run.sh FEAT-001

# Terminal 2 (VasIntelli-Inference):
bash codex-run.sh FEAT-002

# Terminal 3 (after 1 & 2 complete — boundary overlap):
bash codex-run.sh FEAT-003
```

---

## Gemini MCP Tools

| Tool | Insertion Point | Purpose |
|------|----------------|---------|
| `gemini_summarize_design_pack` | Before /work-plan | Compress RFC/ADR bundle into implementation-ready summary |
| `gemini_derive_contract` | During /work-plan | Generate contract.md draft from design summary |
| `gemini_audit_implementation` | Before /work-review | Neutral third-party compliance audit |
| `gemini_compare_diffs` | Before integration | Cross-compare parallel branch diffs |
| `gemini_draft_release_notes` | After merge | Generate release notes with migration steps |
| `gemini_polish_career_doc` | After career-docs-writer refinement | Polish career docs for natural, authentic tone |

---

## Walkthrough: JWT Authentication Middleware

> Follow this end-to-end example to understand the full workflow.

### Phase 1 — Design (Claude + Gemini)

```
[Claude] /work-plan "Add JWT authentication middleware"
```

Claude gathers RFC/ADR, optionally calls Gemini to summarize and derive contract draft:

```
Gemini: summarize_design_pack(["docs/rfc/RFC-012.md", "docs/adr/ADR-005.md"])
  → Implementation-ready summary (valid decisions, invariants, open questions)

Gemini: derive_contract(summary, scope, boundaries)
  → contract.md draft (status: draft)

Claude: reviews + signs contract (status: draft → signed)

Created work/items/FEAT-001-jwt-auth-middleware/
  brief.md       — objective, scope, dependencies
  contract.md    — interfaces, allowed/forbidden files, invariants (signed by Claude)
  checklist.md   — 5 verification items (Yes/No)
  status.md      — status: open

Codex Command:
  bash codex-run.sh FEAT-001
```

### Phase 2 — Implement (Codex)

```
[Codex] bash codex-run.sh FEAT-001
```

The script auto-reads brief, contract, checklist and initializes status:

```mermaid
sequenceDiagram
    participant U as User
    participant X as Codex
    participant W as work/items/FEAT-001/

    U->>X: bash codex-run.sh FEAT-001
    X->>W: Read brief.md → contract.md → checklist.md
    X->>W: Update status.md (in-progress, Agent: Codex)
    X->>X: git checkout -b feat/FEAT-001-jwt-auth-middleware

    loop For each contract requirement
        X->>X: Implement + write tests
        X->>W: Update status.md (progress, changed files)
        X->>X: git commit -m "feat(FEAT-001): ..."
    end

    X->>W: Update status.md (done)
```

Codex implements strictly within contract boundaries:

```
[Codex] Reading contract... Allowed: src/middleware/, tests/middleware/
[Codex] Reading contract... Forbidden: src/database/
[Codex] feat(FEAT-001): add JWT validation middleware
[Codex] feat(FEAT-001): add middleware unit tests
[Codex] Updated status.md → done (5/5 checklist items)
```

### Phase 3 — Monitor (Claude)

```
[Claude] /work-status FEAT-001

FEAT-001: JWT Auth Middleware
Status:     done
Agent:      Codex
Branch:     feat/FEAT-001-jwt-auth-middleware
Progress:   5/5 checklist items
```

### Phase 4 — Review (Gemini + Claude)

```
[Claude] /work-review FEAT-001
```

Gemini audits first (neutral third-party), then Claude makes the final decision:

```
Gemini: audit_implementation(contract, changed_files, checklist)
  → review-gemini.md:
    Contract Compliance: 5/5 Pass
    Boundary Violations: None
    Edge Cases: Token expiry race condition (LOW)
    Written: work/items/FEAT-001-jwt-auth-middleware/review-gemini.md

Claude (informed by Gemini audit):
  Contract Compliance: 5/5 Pass
  Additional finding: Token expiry race condition noted, acceptable for v1

Decision: MERGE
Written: work/items/FEAT-001-jwt-auth-middleware/review.md
```

### Phase 5 — Merge or Revise

```mermaid
flowchart TD
    R{"/work-review\nDecision"}
    M["git merge\nfeat/FEAT-001-*"]
    V["Generate revision\nprompt for Codex"]
    X["Close work item\nwith reason"]
    C["Codex fixes\nrevision items"]

    R -->|MERGE| M
    R -->|REVISE| V
    R -->|REJECT| X
    V --> C
    C --> R
```

If **REVISE**, Claude outputs specific fix items and a new Codex prompt. Codex addresses them and the review cycle repeats.

---

## Work Item Files

| File | Author | Purpose |
|------|--------|---------|
| `brief.md` | Claude | Objective, scope, dependencies |
| `contract.md` | Gemini (draft) → Claude (signed) | Interfaces, boundaries, invariants, test requirements |
| `checklist.md` | Claude | Yes/No verification items |
| `status.md` | Codex | Real-time progress, blockers, ambiguities, changed files |
| `review-gemini.md` | Gemini | Neutral compliance audit (pre-review) |
| `review.md` | Claude | Final review, deviations, lessons, merge decision |

## Commands & Tools

| Command/Tool | Actor | Description |
|-------------|-------|-------------|
| `/work-plan [topic(s)]` | Claude | Create work item(s) — single or batch with boundary check |
| `/work-status [FEAT-NNN]` | Claude | Check progress (summary table or detail view) |
| `/work-review [FEAT-NNN]` | Claude | Review implementation against contract |
| `bash codex-run.sh FEAT-IDs` | User | Boundary check + parallel dispatch (single or multi) |
| `bash codex-run.sh --check` | User | Boundary overlap check only (dry run) |
| `bash link-work.sh [filter]` | User | Manage work/ symlinks across worktrees |
| `git work-link` | User | Same as link-work.sh (after --self-install) |
| `gemini_summarize_design_pack` | Gemini (MCP) | Compress design docs into summary |
| `gemini_derive_contract` | Gemini (MCP) | Generate contract draft |
| `gemini_audit_implementation` | Gemini (MCP) | Neutral pre-review audit |
| `gemini_compare_diffs` | Gemini (MCP) | Cross-compare parallel branches |
| `gemini_draft_release_notes` | Gemini (MCP) | Generate release notes |
