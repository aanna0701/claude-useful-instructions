# Review Output Format

Shared output contract for `doc-reviewer` and `doc-reviewer-execution`. Both agents produce reviews in this format.

## Output Format

```markdown
## Review: [document-title]

**Score:** [A/B/C/D]

### Issues Found

#### CRITICAL (must fix before publish)
- [ ] Issue → Suggested fix

#### IMPROVEMENT (recommended)
- [ ] Issue → Suggested fix

#### MINOR (nice to have)
- [ ] Issue → Suggested fix

### Summary
[1-2 sentence assessment]
```

## Scoring

| Grade | Criteria |
|-------|----------|
| **A** | No CRITICAL, 2 or fewer IMPROVEMENT |
| **B** | No CRITICAL, 3+ IMPROVEMENT |
| **C** | 1-2 CRITICAL |
| **D** | 3+ CRITICAL or wrong document type |

## Rules

- Always provide at least 1 improvement suggestion.
- For `full` depth reviews, include concrete rewrite examples per issue.
- Do not rewrite the document — provide suggestions only.
- Prioritize the agent's dimension of focus (comprehension for `doc-reviewer`, structural compliance for `doc-reviewer-execution`) over cosmetic issues.
