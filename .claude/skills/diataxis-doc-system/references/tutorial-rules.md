# Tutorial Writing Rules

Rules that `doc-writer-tutorial` agent must Read before writing.

## Identity

Tutorial = document for **Learning**.
Reader is a **beginner**. By the end, they have a **working result**.

## DO / DON'T

| DO | DON'T |
|----|-------|
| **Lead the reader step by step** | Offer choices ("use A or maybe B") |
| Show **every step** completely | Skip "obvious" steps |
| Provide **verifiable results** at each step | List 10 steps with no checkpoints |
| Keep explanations **minimal** | Lengthy background theory (-> Explanation) |
| Give concrete **example values** | Leave `<your-value-here>` placeholders |

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

## Core Rules

1. **Golden Path** — Remove choices. Never ask the reader to decide. OS branches: tabs/toggles, one default expanded. "It depends" is forbidden.
2. **Checkpoint Pattern** — End every step with `✅ Check:`. E.g., "You should see `Server running on port 3000`."
3. **Code Blocks** — Must be copy-pasteable. Unavoidable placeholders: `YOUR_API_KEY` (UPPER_SNAKE_CASE). Separate input from output.
4. **Failure Paths** — 1-2 common errors in `⚠️ Troubleshooting:` box. Rare errors -> separate How-to Guide.
5. **Length** — 10 steps max (split into parts if exceeded). One action per step.

## Tone & Style

- Second person, present tense. Encouraging: "Looking good. One last step."

## Anti-Patterns

1. **"Lecture Tutorial"**: 3-paragraph theory inserted mid-step
2. **"Reference Tutorial"**: Lists every option and parameter
3. **"Choose-Your-Own Tutorial"**: Repeated "pick A or B"
4. **"Blind Tutorial"**: 10 steps, zero intermediate checkpoints
