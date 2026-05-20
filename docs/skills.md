# Skills Reference

Skills are auto-triggered by Claude Code based on conversation context. Each skill is a folder under `skills/<name>/` in this repo containing `SKILL.md` and optional `references/`.

**Install location**: shipped via the `claude-useful-instructions` marketplace plugin. After `/plugin install`, Claude Code loads every skill in this repo's `skills/` directory user-wide. No per-project install step.

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

### Related (sibling skill)

- **`dpipe-copilot`** — once the pipeline is built, switch to this sibling skill for run / verify / regenerate / troubleshoot.

---

## dpipe-copilot

Data-pipeline **operations** skill. Covers run / verify / regenerate / troubleshoot for an already-built pipeline (Docker + DuckDB/Parquet + video encoding stack). Catalogs common pitfalls: schema drift, image not rebuilt after dep change, in-memory stale code in long-lived containers, derived-artifact regen order.

**Triggers**: "파이프라인 다시 돌려줘", "스테이지 검증", "파생물 재생성", "DB/스키마 확인", "산출물 재생성", "장수명 컨테이너 갱신", "pipeline operations", "rerun stage", "verify pipeline outputs", "regenerate derived artifacts", "schema drift"

### When to use vs `data-pipeline-architect`

| Phase | Skill |
|-------|-------|
| Design / architecture (pre-build) | `data-pipeline-architect` |
| Run / verify / regenerate / troubleshoot (post-build) | `dpipe-copilot` |

### Related

- **`dpipe-runner`** agent: executes pipeline stages, verifies outputs, regenerates derived artifacts

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

## codebase-qa

GitNexus-backed codebase Q&A skill. Answers questions about symbols, impact, call flow, and architecture using the GitNexus knowledge graph. Read-only — never edits code. All evidence cited as `file:line`.

**Triggers**: "이 함수 바꾸면 뭐가 깨져?", "이 API 어떻게 흘러가?", "인증 처리하는 코드 찾아줘", "이 심볼 누가 쓰냐?", "where is X defined", "impact of removing Y", "who calls", "who depends on", "blast radius", "call graph", "codebase question"

### Workflow

```
[질문] → Phase 1: 전처리 → Phase 2: 분류 → Phase 3: 실행 → Phase 4: 답변
         (repo/index 확인)   (intent 맵핑)   (직접 or 위임)   (file:line + 요약)
```

### Intent Classification

| Intent | GitNexus tools |
|---|---|
| symbol-lookup | `context`, `shape_check` |
| impact | `impact`, `api_impact` |
| flow-trace | `route_map`, `context`, `cypher` |
| semantic | `query`, `group_query` |
| structure | `group_list`, `group_contracts`, `cypher` |
| change-impact | `detect_changes`, `impact` |
| api-surface | `route_map`, `tool_map` |
| rename-safety | `rename` (dry-run), `context` |

### Routing

| Complexity | Route |
|---|---|
| Single intent + single symbol | **Direct** — 1–2 parallel GitNexus calls in-skill |
| 2+ intents OR cross-symbol impact OR semantic search | **Delegate** to `codebase-researcher` agent |

### Preconditions

GitNexus indexed for the repo (`gitnexus analyze`). Stale index (>24h) triggers a warning in the answer header. Without GitNexus the skill stops and prints install instructions — no fallback.

### Related

- **`/codebase-ask`** command: Entry point
- **`codebase-researcher`** agent: Multi-hop delegation target
- **References**: `skills/codebase-qa/references/gitnexus-tools.md` (tool cheatsheet)

---

## collab-workflow

Local-only work-item workflow for structured plan → implement → review cycles inside a single Claude Code session. State is derived from `.work/contracts/` + `git worktree list` + branch ancestry — **no GitHub PRs, no Actions, no `gh` calls**.

**Triggers**: "work item", "work plan", "work review", "work status", "FEAT-", "FIX-", "REFAC-", "worktree", "collab-workflow", "/work-plan", "/work-impl", "/work-refactor", "/work-review", "/work-status"

### Routing

| User Intent | Route To |
|-------------|----------|
| Plan work items | `/work-plan` |
| Implement (FEAT / FIX / PERF / CHORE / TEST) | `/work-impl` |
| Refactor (REFAC) | `/work-refactor` |
| Review + merge | `/work-review` |
| Check status | `/work-status` |

### Pipeline

```
/work-plan → /work-impl | /work-refactor → /work-review → (APPROVE → squash-merge + archive contract)
```

Revise loop: if the latest `review-{shortSHA}.md` says `Status: CHANGES_REQUESTED`, re-run `/work-impl {ID}` (or `/work-refactor`) — it reads the latest review file and treats each MUST-fix item as the punch list.

### Related

- **[Collab Workflow](collab-workflow.md)**: Architecture, setup, walkthrough
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

### Related

- **`/refactor-google-style`** command: Entry point
- **Per-project setup**: drop `.clang-format` (Google preset, ships under `templates/google-style/`) and add a `[tool.ruff]` section to `pyproject.toml`. Do this once per repo — the skill does not auto-install into target projects.

