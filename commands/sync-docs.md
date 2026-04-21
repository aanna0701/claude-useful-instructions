# sync-docs — Sync Documentation to Current Codebase

Analyze current codebase state and update documentation files to match code reality.
Uses specialized agents for different tasks: Sonnet for mechanical collection/editing, Opus for code-understanding-based writing.

Target: $ARGUMENTS (if empty, update all stale documentation files)

---

## Step 0: Discover & Detect `[main session]`

### 0a: Worktree discovery

```bash
git worktree list
```

**Multiple worktrees**:
- Build worktree map: `{ "<branch>": "<path>" }`
- Current directory = **docs worktree** (apply changes here only)
- Other worktrees = **code worktrees** (scan only, never modify)

**Single worktree**: scan current directory only.

### 0b: Feature detection

Detect available capabilities (no flags — all auto-detected):

| Feature | Detection method | Result variable |
|---|---|---|
| **Starlight** | `astro.config.mjs` exists AND imports `@astrojs/starlight` | `HAS_STARLIGHT` |
| **GitNexus** | MCP tool `list_repos` responds OR `.gitnexus/` directory exists | `HAS_GITNEXUS` |
| **Multi-worktree** | `git worktree list` returns >1 entry | `HAS_MULTI_WT` |

If `HAS_GITNEXUS` and index is stale (last analyze >24h), print warning:
```
GitNexus index may be stale. Run `gitnexus analyze` for best results.
```

### 0c: Scan scope determination

```
Always scanned:
  README.md, CLAUDE.md, AGENTS.md
  docs/**/*.md
  work/**/*.md

If HAS_STARLIGHT:
  src/content/docs/**/*.{md,mdx}      (wiki content)
  astro.config.mjs                     (sidebar — read only, never edit)
  public/data/*.json                   (dashboard data)
```

---

## Step 1: Scan Current State `[Sonnet agent]`

Launch Agent(model: sonnet):
> Scan the codebase and produce a structured state snapshot.

### Per-worktree scan (parallel across worktrees)
- **Source files** — Module structure (exclude `__pycache__`, `node_modules/`, `.venv/`, `dist/`, `build/`, `target/`)
- **Test count** — Count `def test_`, `it(`, `test(` in test files
- **Dependencies** — Read `pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod`
- **Recent commits** — `git log --oneline -10`
- **Branch** — `git branch --show-current`

### Docs worktree scan (current directory)
1. **File structure** — Glob source files
2. **All doc files** — Glob `**/*.md` + `**/*.mdx` (if Starlight)
3. **Dependency files** — All `requirements*.txt`, `pyproject.toml`, `package.json`, lock files
4. **Build/CI files** — `Makefile`, `docker-compose*.yml`, `Dockerfile*`, CI workflow files
5. **Test files** — Count test functions/macros across all test files
6. **CLI entry points** — Files using `argparse`, `click`, `typer`, `cobra`, `clap`

### Starlight scan (if HAS_STARLIGHT)
7. **Wiki pages** — List all `src/content/docs/**/*.{md,mdx}` with frontmatter extracted
8. **Sidebar structure** — Parse `astro.config.mjs` sidebar config → ordered page list
9. **Dashboard data** — Read `public/data/*.json` current values

Output: **State Snapshot** (structured data for subsequent steps)

---

## Step 2: Change Analysis

### 2a: Git Diff `[Sonnet agent]`

Launch Agent(model: sonnet):
> Extract file-level changes from git history.

```bash
git log --oneline -20
git diff HEAD~10..HEAD --stat
git diff HEAD~10..HEAD -- "*.toml" "*.txt" "requirements*" "package.json" "go.mod" "Cargo.toml"
git status --short
```

Extract: new/deleted files, dependency changes, config changes, feature completions, new modules.

Output: **File Change List**

### 2b: Code Understanding `[Opus agent]` — only if HAS_GITNEXUS

Launch Agent(model: opus):
> Using GitNexus MCP tools, build a deep understanding of what changed at the code level.
> This is NOT about which files changed — it's about what the code actually does now.

For each changed source file from 2a:
1. **Symbol context** — Use GitNexus symbol context tool to get 360-degree view: function signatures, parameters, return types, callers, callees, process participation
2. **Blast radius** — Use GitNexus impact analysis tool to find everything affected by this change (other symbols, modules, clusters)

For the changeset as a whole:
3. **Change detection** — Use GitNexus change detection tool to map the diff to affected processes and clusters
4. **Semantic doc search** — Use GitNexus query tool (hybrid BM25 + semantic) to find documentation sections conceptually related to the changes, even if they don't mention the exact symbol names

Output: **Code Change Report**

```yaml
changes:
  - symbol: "train()"
    file: "src/train/trainer.py"
    what_changed: "Added optimizer parameter, changed loss calculation to use label smoothing"
    current_signature: "train(model, data, optimizer='adamw', lr_schedule='cosine')"
    callers: ["run_experiment()", "cli_train()"]
    callees: ["compute_loss()", "GradScaler.step()"]
    process: "training-pipeline"
  - symbol: "InferenceAPI.predict()"
    file: "src/serving/api.py"
    # ...

affected_docs:
  - path: "modeling/training-config.md"
    confidence: HIGH
    reason: "Directly references train() signature"
    symbols: ["train()"]
  - path: "modeling/model-training.md"
    confidence: HIGH
    reason: "Step-by-step procedure describes old training flow"
    symbols: ["train()", "compute_loss()"]
  - path: "getting-started/quickstart.md"
    confidence: MEDIUM
    reason: "CLI example uses train command"
    symbols: ["cli_train()"]

new_undocumented:
  - symbol: "lr_schedule parameter"
    suggestion: "Add to training-config.md reference table"
```

If NOT HAS_GITNEXUS: skip this step, proceed with File Change List only.

---

## Step 3: Detect Discrepancies `[Sonnet agent]`

Launch Agent(model: sonnet):
> Compare State Snapshot + Change Analysis against current documentation. Produce a discrepancy list.

### File-level checks (always)
- [ ] Source files not mentioned in docs?
- [ ] Files referenced in docs that no longer exist?
- [ ] New directories/modules not documented?
- [ ] New/removed packages not reflected in docs?
- [ ] Version pins changed?
- [ ] Build targets, Docker services, env vars, CLI options changed?
- [ ] Completed tasks still marked TODO?
- [ ] New features not documented?

### Code-level checks (if Code Change Report available)
- [ ] Symbol signatures in docs don't match actual code?
- [ ] API examples use old parameter names or removed functions?
- [ ] Architecture diagrams don't reflect current process/cluster structure?
- [ ] Guide procedures describe old call flow?
- [ ] New public symbols with no documentation?

### Execution artifact consistency (work/)
- [ ] `done` Tasks/Briefs without corresponding Review?
- [ ] `done` Work Item checklists with unchecked items?
- [ ] Briefs/Tasks referencing superseded/deleted Contracts or RFC/ADR?
- [ ] Orphaned Checklists (parent Brief/Task deleted)?
- [ ] Contract boundaries violated by actual code changes?

### Starlight checks (if HAS_STARLIGHT)
- [ ] Sidebar entry points to non-existent page? (broken link)
- [ ] Page exists but not in sidebar? (orphaned page)
- [ ] `public/data/*.json` values don't match actual code metrics?
- [ ] frontmatter `description` contradicts current code behavior?

### Cross-worktree (if HAS_MULTI_WT)
- [ ] Each worktree's modules match docs?
- [ ] Test counts accurate across worktrees?

Output: **Discrepancy List** with confidence (HIGH/MEDIUM/LOW) per item

---

## Step 4: Determine Update Targets `[main session]`

- `$ARGUMENTS` empty → update all docs with detected discrepancies
- `$ARGUMENTS` specified → update only matching files/patterns
- Skip files with no detected changes

Confidence-based filtering (when Code Change Report available):
- **HIGH** → auto-update
- **MEDIUM** → auto-update + mark for review
- **LOW** → report only (no edit)

### Wiki page type classification (if HAS_STARLIGHT)

Determine update aggressiveness per wiki page. Check in order:

1. **frontmatter `type` field** — if present, use directly
2. **Directory path inference** — parent directory name or sidebar group:
   - Paths containing `reference`, `spec`, `schema`, `config`, `api`, `options` → **Reference**
   - Paths containing `guide`, `getting-started`, `how-to`, `workflow`, `setup` → **Guide**
   - Paths containing `explanation`, `architecture`, `design`, `overview`, `why-` → **Explanation**
3. **Content pattern inference** — scan first 50 lines:
   - Parameter/option tables, schema definitions → **Reference**
   - Numbered steps, "Run ...", checkpoint patterns → **Guide**
   - "Why", design rationale, trade-off discussion → **Explanation**

Update policy per type:

| Page type | Policy | What changes |
|---|---|---|
| **Reference** | Aggressive rewrite | Regenerate from actual code: signatures, parameters, types, defaults |
| **Guide** | Preserve prose, update values | Commands, config values, file paths, output examples |
| **Explanation** | Flag only | Report discrepancy, suggest changes, do NOT auto-edit |

---

## Step 5: Apply Updates (parallel agents)

Launch the following agents in parallel based on update targets:

| Sub-step | Model | Condition | Purpose |
|---|---|---|---|
| 5a | sonnet | always | Project metadata (README, CLAUDE.md, AGENTS.md, CODEMAPS, work/) |
| 5b | sonnet | always | Standard docs (plan, module, operational) |
| 5c | opus | HAS_STARLIGHT | Wiki page rewrite (Reference/Guide/Explanation per-type policy) |
| 5d | sonnet | HAS_STARLIGHT | Dashboard data (public/data/*.json) |
| 5e | — | HAS_STARLIGHT | Sidebar discrepancy report (main session, no edits) |
| 5f | opus | HAS_GITNEXUS | Architecture diagrams (mermaid from process/cluster data) |

Each sub-step below is the body-prompt passed to the agent (or the main-session action for 5e).

### 5a: Project metadata

Update project metadata files with values from State Snapshot.

**README.md, CLAUDE.md, AGENTS.md**:
- Replace only `<!-- AUTO-GENERATED -->` sections; preserve hand-written prose
- Update feature/status sections, test counts, build commands, dependencies

**CODEMAPS**:
- Full rewrite if >30% change rate; otherwise edit specific sections
- Update metadata: `<!-- Generated: YYYY-MM-DD | Files scanned: N -->`

**Execution artifacts (work/)**:
- Verify `work/items/{ID}-{slug}/contract.md` references still exist (branch, worktree, PR)
- Flag orphaned contracts whose branch/PR no longer exists
- Verify source links and ID references

### 5b: Standard docs

Update `docs/**/*.md` files conservatively.

**Plan/architecture docs**:
- Mark completed phases/tasks as done (evidence from git log)
- Update dependency lists from current lock/spec files
- Flag plan items contradicted by current code

**Module docs**:
- Update structure trees, test commands/counts

**Operational docs (RUNBOOK.md, CONTRIBUTING.md)**:
- Update CLI command tables, setup instructions

Rules:
- Replace only `<!-- AUTO-GENERATED -->` sections
- Edit changed portions only — no full rewrites
- Preserve hand-written prose

### 5c: Wiki page rewriting

Rewrite wiki pages based on actual code understanding (Code Change Report if GitNexus available, otherwise File Change List). Make the documentation accurately describe what the code actually does.

**Reference pages** (aggressive rewrite):
- If HAS_GITNEXUS: use symbol context to extract actual function signatures, parameter types, default values, return types directly from code
- Generate parameter tables from real code, not from what the doc previously said
- Include caller/callee relationships as "Related" sections
- Update code examples to match current API

**Guide pages** (preserve prose, update values):
- Keep the narrative structure and explanations intact
- Update: command invocations, config file contents, file paths, expected output
- If HAS_GITNEXUS: verify the step-by-step procedure matches actual call flow; flag if the guide describes a flow that no longer exists

**Explanation pages** (flag only — do NOT auto-edit):
- Compare against current cluster/process structure (if HAS_GITNEXUS)
- Report: "Architecture has changed — [specific change]. This page may need revision."
- Add `<!-- STALE: [reason] — [date] -->` comment at top if discrepancy found

### 5d: Dashboard & metrics

Update dashboard data files with current metrics.

**public/data/*.json**:
- Update test counts, module status, dependency counts from State Snapshot
- Preserve JSON structure — only change values
- If keys are missing for new modules, add them following existing naming patterns

### 5e: Sidebar discrepancy report

Do NOT edit `astro.config.mjs` or `content.config.ts`. Instead, print a report:

```
Sidebar sync report
─────────────────────────────────────────
Orphaned entries (in sidebar, file missing):
  - /data/old-removed-page/

Missing from sidebar (file exists, not in sidebar):
  - src/content/docs/data/vqa-template-reference.md
  
Suggested sidebar addition:
  { label: 'VQA Template Reference', link: '/data/vqa-template-reference/' }
─────────────────────────────────────────
```

### 5f: Architecture diagrams

Regenerate architecture diagrams from GitNexus process and cluster data.

- Use GitNexus cluster data to generate mermaid dependency graphs
- Use GitNexus process data to generate mermaid sequence/flow diagrams
- Compare with existing mermaid code blocks in docs
- Replace only if structure has actually changed (not just formatting)
- Preserve diagram titles and custom styling

---

## Step 6: Verify & Apply `[main session]`

Collect outputs from all parallel agents.

Apply rules:
- Use Edit tool for each target file
- Preserve UTF-8 encoding
- No emoji additions unless already present
- All changes go to docs worktree only (multi-worktree mode)
- `.mdx` files: preserve component imports and JSX blocks
- Never edit: `astro.config.mjs`, `content.config.ts`, `package.json`

---

## Step 7: Summary `[main session]`

```
Documentation sync complete
─────────────────────────────────────────
Mode: [Baseline | +Starlight | +GitNexus | +Starlight+GitNexus]
      [Single worktree | Multi-worktree (N)]

Agents used:
  Sonnet: scan, diff, metadata, standard docs, dashboard
  Opus:   code understanding, wiki rewrite, diagrams

Source analysis:
  [If GitNexus] N symbols changed, M clusters affected, K processes touched
  [Always]      Git range: HEAD~10..HEAD (N commits)

Project docs:
  Updated:  README.md (dependencies updated)
  Skipped:  CLAUDE.md (no changes)
  Flagged:  work/items/FEAT-003/contract.md (branch deleted)

[If Starlight] Wiki pages:
  Rewritten: modeling/inference-api.md (Reference — 3 signatures updated)
  Updated:   data/pipeline-config.md (Reference — 2 options added)
  Updated:   getting-started/quickstart.md (Guide — CLI example updated)
  Flagged:   explanation/data-pipeline-design.md (Explanation — cluster restructured)
  Sidebar:   1 orphaned, 1 missing (see report above)
  Dashboard: public/data/metrics.json updated

[If GitNexus] Confidence breakdown:
  HIGH: 5 docs updated
  MEDIUM: 2 docs updated + marked for review
  LOW: 1 doc reported only

─────────────────────────────────────────
Files scanned: N source, M docs
Next: review updated files and commit
```
