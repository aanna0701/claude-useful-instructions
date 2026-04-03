# debug-guide — Analyze recent commits and generate a verification/debug checklist

Analyze recent git commits to identify what needs checking, testing, and debugging. Produces a prioritized checklist of verification steps.

Arguments: $ARGUMENTS
- If empty: analyze last 5 commits (`HEAD~5..HEAD`)
- If a number (e.g., `10`): analyze last N commits (`HEAD~N..HEAD`)
- If a branch name (e.g., `main`): analyze diff from that branch (`main..HEAD`)
- If a commit range (e.g., `abc123..def456`): use as-is
- If `--focus=<area>`: filter analysis toward a specific area (can combine with above)

---

## Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- **COMMIT_RANGE**: the revision range to analyze
- **FOCUS**: optional area filter (from `--focus=`)

Default: `HEAD~5..HEAD` if no range argument given.

Validate the range exists: `git rev-parse --verify {range endpoints}`. If invalid, show available branches/tags and ask user.

---

## Step 2: Quick overview (parallel)

Run in parallel:

1. `git log --oneline --no-decorate {COMMIT_RANGE}` — list commits
2. `git diff {COMMIT_RANGE} --stat` — change summary

Print the overview table to the user:

```
Analyzing {N} commits ({short_range})
──────────────────────────────────────
abc1234  feat: add user auth endpoint
def5678  fix: correct timezone handling
ghi9012  refactor: extract validation utils
──────────────────────────────────────
{M} files changed, {A} insertions(+), {D} deletions(-)
```

---

## Step 3: Delegate to debug-guide agent

Launch the **debug-guide** agent (`subagent_type: "general-purpose"` with the debug-guide agent prompt) with:
- COMMIT_RANGE
- FOCUS (if provided)

The agent will:
1. Read the full diffs
2. Classify changes by risk
3. Detect risk patterns
4. Trace impact via callers and tests
5. Generate the prioritized verification checklist

---

## Step 4: Present results

Show the agent's checklist output to the user. If CRITICAL items are found, highlight them prominently.

If the project has a test runner configured, suggest the specific test commands to run.
