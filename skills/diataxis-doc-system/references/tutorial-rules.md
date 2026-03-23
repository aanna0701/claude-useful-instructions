# Tutorial Writing Rules

Rules that `doc-writer-tutorial` agent must Read before writing.

---

## Identity

Tutorial = document for **Learning**.
Reader is a **beginner**. By the end, they have a **working result**.

---

## DO / DON'T

| DO | DON'T |
|----|-------|
| **Lead the reader step by step** | Offer choices ("use A or maybe B") |
| Show **every step** completely | Skip "obvious" steps |
| Provide **verifiable results** at each step | List 10 steps with no checkpoints |
| Keep explanations **minimal** | Lengthy background theory (-> Explanation) |
| Give concrete **example values** | Leave `<your-value-here>` placeholders |

---

## Document Structure Template

```markdown
# [Tutorial Title]: [What the Reader Will Build]

> After this tutorial you will have [concrete outcome].
> Estimated time: [N] minutes

## Prerequisites
- [Tool 1] — verify: `command`
- [Tool 2] — verify: `command`

## Step 1: [Start with a verb]
[Why this step is needed — one sentence]
\```bash
concrete_command --with=real_value
\```
✅ **Check**: [What you should see on success]

## Step 2: [Start with a verb]
...

## Step N: Verify the Result
[Final output example]

## Next Steps
- [How-to Guide link]: Try [advanced task] next.
- [Explanation link]: Learn why [what you just did] works this way.
```

---

## Core Rules

### 1. Golden Path
- Remove choices. Never ask the reader to decide.
- OS-specific branches: use tabs/toggles, expand only the default.
- "It depends on your situation" is forbidden in Tutorials.

### 2. Checkpoint Pattern
- End every step with a `✅ Check:` block.
- Example: "You should see `Server running on port 3000` in your terminal."

### 3. Code Blocks
- Must be copy-pasteable. Minimize placeholders.
- Unavoidable placeholders: `YOUR_API_KEY` (UPPER_SNAKE_CASE).
- Distinguish terminal input from output (`$` prompt or separate blocks).

### 4. Failure Paths
- Cover 1-2 common errors in a `⚠️ Troubleshooting:` box.
- Rare errors go in a separate Troubleshooting How-to Guide.

### 5. Length
- Target 10 steps max. Split into Part 1/2 if exceeded.
- Each step contains exactly one action.

---

## Tone & Style

- Second person, present tense: "Install X" not "The user should install X."
- Encouraging tone: "Looking good. One last step."

---

## Anti-Patterns

1. **"Lecture Tutorial"**: 3-paragraph theory inserted mid-step
2. **"Reference Tutorial"**: Lists every option and parameter
3. **"Choose-Your-Own Tutorial"**: Repeated "pick A or B"
4. **"Blind Tutorial"**: 10 steps, zero intermediate checkpoints
