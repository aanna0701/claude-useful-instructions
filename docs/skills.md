# Skills Reference

Skills are auto-triggered by Claude Code based on conversation context. Each skill is a folder under `.claude/skills/` containing `SKILL.md` and optional `references/`.

---

## diataxis-doc-system

Diátaxis Framework-based technical documentation system. Classifies documents into 4 types and delegates to specialized writer agents.

**Triggers**: "Write docs", "Design doc", "API docs", "ADR", "README", "documentation", "technical writing"

### Workflow

```
[Request] → Phase 0: Gather input
          → Phase 1: Classify type (Router)
          → Phase 2: Delegate to agent
          → Phase 3: Quality review
```

### Document Types

| Type | Purpose | Reader State | Agent |
|------|---------|-------------|-------|
| Tutorial | Learning | First encounter | `doc-writer-tutorial` |
| How-to Guide | Problem solving | Knows basics, has specific problem | `doc-writer-howto` |
| Explanation | Understanding | Wants to know "why" | `doc-writer-explain` |
| Reference | Information lookup | Needs exact specs | `doc-writer-reference` |

### Explanation Subtypes

| Subtype | Use Case | Scale |
|---------|----------|-------|
| Design Doc (RFC) | Full design proposal for new system/feature | Large changes, needs review |
| ADR | Record of individual architecture decision | Small decisions, history preservation |

### Partial Execution

| Request | Scope |
|---------|-------|
| "Write a document" | Full pipeline (Phase 0-3) |
| "Classify this document" | Phase 1 only |
| "Review this document" | Phase 3 only (quality check on existing doc) |
| "Add Reference only" | Jump to Phase 2 (type already known) |
| "Set up docs structure" | Redirect to `/init-docs` command |

### Related

- **`/write-doc`** command: Entry point for document writing
- **`/init-docs`** command: Scaffold docs site structure
- **`diagram-architect`** skill: Architecture diagrams for Explanation docs
- **`diagram-pipeline`** skill: Convert Mermaid diagrams to draw.io

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

## diagram-pipeline

End-to-end pipeline for converting Mermaid diagrams in Markdown docs to draw.io, editing in Cursor, and reinserting into docs.

**Triggers**: "Convert mermaid to drawio", "Prettier diagrams", "Embed diagrams in docs", "Diagram pipeline"

**Required tool**: [hediet.vscode-drawio](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) extension for Cursor

### Workflow

```
Phase 1: extractor agent    Phase 2: generator agent   Phase 3: User edits    Phase 4: inserter agent
─────────────────────────   ─────────────────────────   ──────────────────────  ─────────────────────────
Scan docs/**/*.md           Read .mermaid files         Open .drawio in Cursor  Check .drawio.svg files
Extract mermaid blocks  →   Generate draw.io XML    →   Edit nodes/colors   →  Copy SVG to docs/assets/
Create manifest.json        Write .drawio files         Convert To SVG          Replace mermaid → ![img]
Save .mermaid files                                                             Preserve original mermaid
```

### Partial Execution

| Request | Agents Used |
|---------|-------------|
| "Extract mermaid only" | extractor only |
| "Create drawio files" | generator only |
| "Insert into docs" | inserter only |
| "Full pipeline" | Phase 1+2, then guide user for Phase 3 |

### Commit Guide

| File | Commit? | Why |
|------|---------|-----|
| `diagrams/*.drawio` | Yes | Editable source |
| `diagrams/*.drawio.svg` | Yes | Editable + SVG dual-use |
| `diagrams/*.mermaid` | Yes | Mermaid backup |
| `diagrams/manifest.json` | Yes | Line tracking |
| `docs/assets/diagrams/*.drawio.svg` | Yes | MkDocs serving artifact |

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
