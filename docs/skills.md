# Skills Reference

Skills are auto-triggered by Claude Code based on conversation context. Each skill is a folder under `.claude/skills/` containing `SKILL.md` and optional `references/`.

**Install location**: always `.claude/skills/<name>/` only (project or `~/.claude/skills/` globally). The installer does not create `.cursor/skills/` or `.agent/skills/` trees—those were redundant with Claude Code’s layout. Re-running a project install removes legacy copies or symlinks there from older releases.

---

## diataxis-doc-system

Dual-axis documentation system. Classifies documents into **Diataxis** (reader-oriented) or **Delivery** (execution-oriented) axis, then delegates to specialized agents.

**Triggers**: "Write docs", "Design doc", "API docs", "ADR", "work item", "task", "contract", "checklist", "review", "documentation"

### Workflow

```
[Request] → Phase 0.5: Axis (Diataxis or Delivery?)
          → Phase 1/1-D: Classify type
          → Phase 2: Delegate to agent
          → Phase 3: Quality review
```

### Diataxis Axis (reader-oriented)

| Type | Purpose | Reader State | Agent |
|------|---------|-------------|-------|
| Guide | Step-by-step procedures | Wants to accomplish a task (beginner or practitioner) | `doc-writer-guide` |
| Explanation | Understanding | Wants to know "why" | `doc-writer-explain` |
| Reference | Information lookup | Needs exact specs | `doc-writer-reference` |

### Delivery Axis (execution-oriented)

| Type | Purpose | Agent |
|------|---------|-------|
| Work Item | Multi-agent coordination (bundle) | `doc-writer-task` → `-contract` → `-checklist` |
| Task | Standalone work assignment | `doc-writer-task` |
| Contract | Interface agreement | `doc-writer-contract` |
| Checklist | Completion verification | `doc-writer-checklist` |
| Review | Result assessment | `doc-writer-review` |

### Quality Review Routing

| File Location | Reviewer |
|---------------|----------|
| `docs/` | `doc-reviewer` (readability, type purity, style) |
| `work/` | `doc-reviewer-execution` (structural integrity, contract compliance) |

### Partial Execution

| Request | Scope |
|---------|-------|
| "Write a document" | Full pipeline (Phase 0-3) |
| "Create work item" | Phase 2 direct (Delivery, Work Item bundle) |
| "Review this document" | Phase 3 only (routed by location) |
| "Add Reference only" | Jump to Phase 2 (type already known) |
| "Set up docs structure" | Redirect to `/init-docs` command |

### Related

- **`/write-doc`** command: Entry point for document writing
- **`/init-docs`** command: Scaffold docs site structure
- **`diagram-architect`** skill: Architecture diagrams for Explanation docs
---

## diagram-architect

Mermaid-based architecture diagram design skill. Decomposes complex systems using C4 model layers (Context/Container/Component) with minimal text + numbering + legend.

**Triggers**: "Draw diagram", "Architecture visualization", "System structure", "Flowchart", "Sequence diagram", "ERD", "Component diagram"

### Core Principles

1. **C4 Layering** — Never put everything in one diagram. Separate by level.
2. **Line Semantics** — Solid (sync), dashed (async), consistent arrow direction.
3. **Abstraction Consistency** — Never mix infra and business logic.
4. **Color/Shape Consistency** — 3-4 colors max + mandatory legend.
5. **Minimal Text** — Abbreviate inside shapes, use numbering, explain in body text.

### Workflow

```
[Input] → Phase 1: Analyze    → Phase 2: Decompose   → Phase 3: Generate   → Phase 4: Verify
          (structure analysis)   (layers/views split)    (Mermaid code)        (checklist)
```

Phase 3 delegates to the **`diagram-writer`** agent for Mermaid code generation.

### Decomposition Strategies

| Strategy | When |
|----------|------|
| C4 Layer Split | L1: external relations, L2: internal containers, L3: components |
| View Split | Data flow vs deployment vs sequence — separate diagrams per view |
| Domain Split | MSA: one diagram per bounded context |

### Output Format

Each diagram includes: Mermaid code block + legend table + numbered flow description.

**Hard limit**: 15+ shapes → must split. No exceptions.

---

## data-pipeline-architect

Data pipeline structure design and subagent auto-generation skill. Takes a rough data structure, diagnoses with 8 immutable principles, and generates subagent definitions + Claude Code instruction sets.

**Triggers**: "Design data pipeline", "Review data structure", "Create pipeline agents", "ETL architecture", "Data collection-transform-load design"

### Workflow

```
[User Input] → Phase 1: Diagnose    → Phase 2: Identify stages → Phase 3: Design agents → Phase 4: Generate instructions → Phase 5: Self-verify
               (8 principles check)    (find boundaries)           (common + conditional)    (order + dependencies)           (checklist)
```

### Phase 1 — 8 Principles Diagnosis

Evaluates against 8 immutable data principles. Each principle gets: Pass / Violation / N/A, with location + reason + remedy for violations.

### Phase 2 — Stage Identification

Detects natural stage boundaries using 3 signals:
1. **Format transform**: Data format changes (image→CSV, CSV→DB)
2. **Ownership transfer**: Execution environment changes (hardware→software)
3. **Irreversible point**: High rollback cost (raw deletion, aggregation)

### Phase 3 — Subagent Design

| Common Agents (always) | Conditional Agents (if needed) |
|------------------------|-------------------------------|
| Schema Validator | Integrity Guard (raw data exists) |
| Quality Gate | Lineage Tracker (origin mapping breaks) |
| Orchestrator | Migration Manager (schema evolution) |
| | Deduplicator (multi-source merge) |
| | Anonymizer (PII/sensitive data) |

### Phase 5 — Self-verification Checklist

All 8 principles reflected, schema contracts at boundaries, raw immutability, recovery paths, traceability, idempotency, no circular dependencies, 3+ tests per instruction.

### Final Output

Single markdown file (`{project}_pipeline_instructions.md`) containing: diagnosis table, stage definitions, agent structure, instruction set, verification checklist, usage guide.

---

## html-presentation

HTML presentation formatting skill. Converts existing HTML slides into a standard 16:9 dark-theme slide deck using `base-template.html` CSS/JS system.

**Triggers**: "PPT 포맷 맞춰줘", "슬라이드 변환해줘", "format-presentation", "HTML 슬라이드 변환", "템플릿에 맞춰줘"

### Workflow

```
[Input HTML] → Phase 1: Parse    → Phase 2: Map           → Phase 3: Regenerate      → Phase 4: Verify
               (slide extraction)   (component selection)     (base-template based)      (rule check)
```

### Core Rules

1. Use `base-template.html` CSS/JS as-is — no custom styles
2. All slides use `.slide-dark` class
3. Only the first slide gets `.active`
4. All slides include `.slide-label` for header label updates
5. 16:9 aspect ratio maintained
6. Content taken from source HTML verbatim — no text modifications

### Component Catalog

| Content Pattern | Component |
|----------------|-----------|
| Title + presenter info | `title` |
| 3 items listed | `cards-3` |
| 6 items listed | `grid-2x3` |
| Linear steps | `pipeline` |
| A → B → C data flow | `flow` |
| Two-way comparison | `brain-split` |
| Key numbers highlight | `stats` |
| Item status (done/in-progress/planned) | `table` |
| Chronological steps | `timeline` |
| Short/mid/long-term plan | `roadmap` |
| 4 differentiators | `advantages` |
| Paragraph + callout box | `section + callout` |
| Final summary | `summary` |

### Related

- **`/create-presentation`** command: Generate new presentation from content
- **`/format-presentation`** command: Convert existing HTML to standard format
- **`/edit-presentation`** command: Modify content in formatted presentations
- **`/export-pdf`** command: Convert to PDF

---

## career-docs

Korean career document generation & refinement skill. NotebookLM drafts; AI refines through a 6-step checklist and iterative Writer-Reviewer loop.

**Triggers**: "자소서 써줘", "경력기술서 작성", "커버레터", "포트폴리오 정리", "커버레터 작성", "cover letter", "career description", "portfolio"

### Supported Document Types

| Type | Korean | Key Structure |
|------|--------|---------------|
| `cover-letter` | 자소서 (자기소개서) | 기승전결, competency framing |
| `career-desc` | 경력기술서 | Chronological, per-company chapters |
| `portfolio` | 포트폴리오 | Per-project, challenge→solution→impact |
| `cover-letter-en` | 커버레터 (영문/국문) | Hook → Value Prop → Fit → Close |
| `hr-essay` | 인사관점 에세이 | Soft-skill claims backed by cases |

### Workflow

```
User Input (doc type + JD/context + constraints)
  → [Optional] Context Update (new CV/info → NLM merge)
  → NLM Draft Request (type-specific prompt)
  → Writer: 6-Step Refinement (career-docs-writer)
  → Reviewer: 6-Dimension Evaluation (career-docs-reviewer)
  → Reviser: Targeted Fixes (career-docs-reviser)
  → Final Output
```

### 3-Stage Pipeline

| Stage | Agent | Role |
|-------|-------|------|
| Writer | `career-docs-writer` | 6-step checklist refinement of NLM draft |
| Reviewer | `career-docs-reviewer` | 6-dimension scoring (0-100) + specific fix instructions |
| Reviser | `career-docs-reviser` | Apply Reviewer fixes in single pass (score <90 only) |

### Prerequisites

- NotebookLM MCP connected
- "자소서" notebook with CV, portfolio, project descriptions uploaded
- Context documents (컨텍스트 정리, 경력 기술서, 인사관점 에세이) already in NLM

### Related

- **`career-docs-writer`** agent: 6-step refinement
- **`career-docs-reviewer`** agent: Evaluation scoring
- **`career-docs-reviser`** agent: Targeted fix application

---

## collab-workflow

PR-native collaboration workflow for structured plan → implement → review cycles between Claude and Codex. State is derived from the GitHub PR + git — no per-item status md files.

**Triggers**: "work item", "work plan", "work review", "work status", "codex", "hand off", "delegate", "FEAT-", "FIX-", "REFAC-", "multi-agent", "worktree", "branch map", "collab-workflow"

### Routing

| User Intent | Route To |
|-------------|----------|
| Plan work items | `/work-plan` |
| Implement (FEAT / FIX / PERF / CHORE / TEST) | `/work-impl` |
| Refactor (REFAC) | `/work-refactor` |
| Review + merge | `/work-review` |
| Check status | `/work-status` |
| Audit CI workflows | `/gha-branch-sync` |

### Pipeline

```
/work-plan → /work-impl | /work-refactor → /work-review → merge
```

Revise loop: if `reviewDecision=CHANGES_REQUESTED`, re-run `/work-impl {ID}` (or `/work-refactor`) — it fetches unresolved review threads via GraphQL and treats each as a MUST-fix.

### Related

- **[Collab Workflow](collab-workflow.md)**: Architecture, setup, walkthrough
- **[Migration v1 → v2](MIGRATION-v2.md)**: What changed in v2
- **Commands**: `/work-plan`, `/work-impl`, `/work-refactor`, `/work-review`, `/work-status`

---

## google-style-refactor

Refactor an entire C++/Python codebase to the Google Style Guide. Runs mechanical formatters first, then dispatches language-specific semantic agents in parallel.

**Triggers**: "google style", "google style guide", "Google C++ style", "Google Python style", "refactor to google", "/refactor-google-style"

### Rules (auto-loaded)

| File | Covers |
|------|--------|
| `rules/google-style-cpp.md` | C++ formatting, naming, includes, ownership, language features |
| `rules/google-style-python.md` | Python formatting, naming, docstrings, type hints, imports |

### Pipeline

```
[Scope] → Mechanical pass → Semantic pass (parallel agents) → Verify
          (clang-format, ruff)  (google-style-refactor-{cpp,python})  (re-format + tests)
```

### Agents

| Agent | Scope | Model | Effort |
|-------|-------|-------|--------|
| `google-style-refactor-cpp` | `*.{cpp,cc,h,hpp}` semantic rewrite | sonnet | medium |
| `google-style-refactor-python` | `*.py` semantic rewrite | sonnet | medium |

### Cursor Parity

Installing the `google-style` bundle also writes `.cursor/rules/google-style-{cpp,python}.mdc` with glob triggers so Cursor's inline AI applies the same rules.

### Related

- **`/refactor-google-style`** command: Entry point
- **Tooling installed**: `.clang-format` (Google preset), `pyproject.toml` ruff section, Cursor mdc rules

---

## ppt-generation

Fill a pre-formatted PowerPoint template (`.potx` or `.pptx`) with content from source material. Treats the base template as an **immutable design system** — inserts content only, never modifies fonts, layouts, colors, or shapes.

**Triggers**: "fill template", "populate slides", "use this template", "base PPT", ".potx", "템플릿에 내용 넣어줘", "베이스 PPT에 채워줘", "템플릿 기반으로 발표자료 만들어줘"

### Non-Negotiable Rules

1. Never change fonts, font sizes, bullet styles, colors, spacing, or positions
2. Never move, resize, or delete shapes/text boxes/images
3. Only replace placeholder text or insert into designated slots
4. Inherit all `<a:rPr>` and `<a:pPr>` from the template
5. Content is concise, technical, one core message per slide
6. No decorative elements, animations, or new shapes

### 8-Step Pipeline

| Step | Action |
|------|--------|
| 1 | Template analysis (guard) — slideLayout XML, placeholders, fixed elements |
| 2 | Slot extraction — idx, position, size, bullet hierarchy |
| 3 | Source compression — extract key facts from source docs |
| 4 | Slide message design — one core message per slide |
| 5 | Content generation — phrase-first, presentation-ready |
| 6 | XML insertion — into designated placeholders only |
| 7 | Density check — `ppt-density-checker` agent |
| 8 | Format compliance review — `ppt-format-reviewer` agent |

### Related

- **`/generate-ppt`** command: Entry point
- **`ppt-density-checker`** agent: Detect over-dense slides
- **`ppt-format-reviewer`** agent: Enforce template design contract
