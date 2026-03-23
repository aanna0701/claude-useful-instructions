# Explanation Writing Rules

Rules that `doc-writer-explain` agent must Read before writing.

## Identity

Explanation = document for **Understanding** (Design Docs/RFCs, ADRs).
Reader wants to understand **"why is it built this way?"**

## DO / DON'T

| DO | DON'T |
|----|-------|
| Provide sufficient **context** | State conclusions without reasoning |
| Compare **alternatives** | Justify only the chosen approach |
| State **trade-offs** explicitly | Claim "this is the best" without evidence |
| Include **historical background** | Describe only the current state |
| Explain from multiple **viewpoints** | Present only one perspective |

---

## Subtype A: Design Doc (RFC) Template

```markdown
# [RFC/Design Doc Title]

| Field | Value |
|-------|-------|
| Status | Draft / In Review / Approved / Superseded |
| Author | [Name] |
| Reviewers | [Names] |
| Last Updated | [Date] |

## 1. Context & Goals

### Background
[Why this design is needed. Current system limitations.]

### Goals
- [Goal 1]
- [Goal 2]

### Non-Goals
- [Out of scope item 1] — Reason: [...]
- [Out of scope item 2] — Reason: [...]

## 2. Proposed Design

### 2.1 System Overview
\```mermaid
[Architecture diagram]
\```

### 2.2 Data Model
[Entities, relationships, schema]

### 2.3 Interfaces
[API endpoint summary — detailed specs go in Reference]

### 2.4 Key Flows
\```mermaid
sequenceDiagram
    [Primary use case sequence]
\```

## 3. Alternatives Considered

### Alternative A: [Name]
- **Pros**: [...]  **Cons**: [...]  **Rejection reason**: [...]

### Comparison Summary
| Criterion | Proposed | Alt A | Alt B |
|-----------|----------|-------|-------|
| Performance | ... | ... | ... |
| Complexity | ... | ... | ... |
| Cost | ... | ... | ... |

## 4. Cross-cutting Concerns
Security / Performance & Scalability / Operational Cost / Monitoring & Alerting

## 5. Migration Plan
[Transition strategy from existing system]

## 6. Open Questions
- [ ] [Unresolved item 1]
- [ ] [Unresolved item 2]
```

## Subtype B: ADR Template

```markdown
# ADR-[Number]: [Decision Title]

| Field | Value |
|-------|-------|
| Status | Proposed / Accepted / Deprecated / Superseded by ADR-[N] |
| Date | [YYYY-MM-DD] |

## Context
[Situation requiring this decision. Constraints.]

## Decision
[What was decided. Keep it concise.]

## Rationale
[Why this decision was made. Alternatives considered and trade-offs.]

## Consequences
### Positive
### Negative
### Risks
```

## Core Rules

### 1. 4+1 View Model (ISO 42010)

| View | Shows | Tools |
|------|-------|-------|
| Logical | Functional structure (domain, modules, classes) | Class diagrams, ERD |
| Process | Runtime flows (concurrency, communication) | Sequence, activity diagrams |
| Development | Code structure (packages, layers, build) | Package diagrams, module deps |
| Physical | Deployment (servers, network, cloud) | Deployment diagrams, infra topology |
| +1 Scenarios | Key use cases spanning all 4 views | Use case diagrams |

Choose views based on audience and purpose. Delegate diagrams to diagram-architect skill.

### 2. Always Include "Why"
- "What" only = Reference. Explanation's core value is **Why** and **Trade-offs**.

### 3. Alternatives Comparison Required
- Include at least 1 rejected alternative. "Why not X" matters as much as "why Y."

### 4. Non-Goals Section
- State what is out of scope -> prevents scope creep.
- Distinguish "deferred" from "intentionally excluded."

### 5. Open Questions
- Never hide unresolved questions. Track as checklist; record conclusions when resolved.

### 6. Diagrams as Code
- Mermaid or PlantUML only. Legend/caption required.

## Tone & Style

- Analytical, neutral. No emotional advocacy. Distinguish speculation from fact.

## Anti-Patterns

1. **"Justification Doc"**: Post-hoc rationalization; perfunctory alternatives
2. **"Encyclopedia"**: Lists technologies without connecting to design decisions
3. **"How-to in Disguise"**: Code-level procedures > design philosophy (-> split)
4. **"Diagrams Only"**: Rich visuals, no explanation of why
