# How-to Guide Writing Rules

Rules that `doc-writer-howto` agent must Read before writing.

---

## Identity

How-to Guide = document for **Problem-solving**.
Reader already knows the basics and wants to **solve a specific problem**.
Not hand-holding like a Tutorial, not exhaustive like a Reference.

---

## DO / DON'T

| DO | DON'T |
|----|-------|
| **Problem-focused** title ("How to ~") | Feature-focused title ("Introducing X") |
| Allow **flexibility** (reader's env may vary) | Force a single fixed path like a Tutorial |
| State **prerequisites** explicitly | Teach from scratch (-> Tutorial) |
| Keep procedures **concise** | Explain "why" at length (-> Explanation) |
| Production-ready examples | Toy/educational examples |

---

## Document Structure Template

```markdown
# How to [solve specific problem]

> [One-sentence summary of the problem this guide solves]

## Prerequisites
- [Prior knowledge / completed Tutorial link]
- [Required tools + minimum versions]
- [Required permissions / environment]

## Procedure

### 1. [Start with a verb]
\```bash
command or code
\```
> 💡 [Environment-specific variation note]

### 2. [Start with a verb]
...

## Verification
[How to confirm the result is correct]

## See Also
- [Related Reference link]
- [Related Explanation link]
```

---

## Core Rules

### 1. Title Pattern: "How to ~"
- "How to refresh authentication tokens"
- "How to rollback a production migration"
- Reader must judge from the title alone whether this solves their problem.

### 2. Prerequisite Gate
- Redirect unqualified readers to the Tutorial.
- "This guide assumes you have completed [Tutorial title]."

### 3. Flexibility (Key Difference from Tutorials)
- Tutorials remove choices. How-to Guides **acknowledge choices**.
- "For PostgreSQL use `pg_dump`; for MySQL use `mysqldump`."
- More than 3 options: use a table.

### 4. Minimal Explanation
- "Why" in 1 sentence max. Deep background -> link to Explanation.
- Most common mistake: inserting architecture discussion mid-procedure.

### 5. Production-Oriented
- Examples must be production-ready. Include error handling.
- Use realistic values, not `foo` / `bar`.

### 6. Scope
- One How-to = one problem.
- "Set up auth and configure monitoring" -> split into 2 guides.
- Ideal: 5-8 steps. Consider splitting above 12 steps.

---

## Tone & Style

- Direct and practical: "Run X", "Set Y to Z."
- Trust the reader's competence. No re-explaining basics.

---

## Anti-Patterns

1. **"Textbook"**: More theory than procedure
2. **"Swiss Army Guide"**: Solves 3+ problems in one doc
3. **"Tutorial in Disguise"**: Starts with "First, install Python"
4. **"Reference in Disguise"**: Lists every option exhaustively
