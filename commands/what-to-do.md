# what-to-do — Review recent work and generate an action plan

Analyze recent git commits to summarize what was done and guide next steps: verification, debugging, and implementation.

Arguments: $ARGUMENTS
- If empty: analyze today's commits (commits from today's date)
- If a number (e.g., `10`): analyze last N commits (`HEAD~N..HEAD`)
- If a date (e.g., `2026-04-01`): analyze commits since that date
- If a branch name (e.g., `main`): analyze diff from that branch (`main..HEAD`)
- If a commit range (e.g., `abc123..def456`): use as-is
- If `--focus=<area>`: filter analysis toward a specific area (can combine with above)

---

## Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- **COMMIT_RANGE**: the revision range to analyze
- **DATE_FILTER**: date cutoff if date-based argument given
- **FOCUS**: optional area filter (from `--focus=`)

Default behavior (no arguments):
1. Get today's date: `date +%Y-%m-%d`
2. Use `--since={today}` with git log to find today's commits
3. If no commits today, fall back to last 5 commits

If a date is given (matches `YYYY-MM-DD`):
- Set DATE_FILTER to that date
- COMMIT_RANGE derived from `git log --since={date} --format=%H | tail -1`

Validate the range exists. If invalid, show available branches/tags and ask user.

---

## Step 2: Quick overview (parallel)

Run in parallel:

1. `git log --oneline --no-decorate {COMMIT_RANGE}` — list commits
2. `git diff {COMMIT_RANGE} --stat` — change summary

Print the overview to the user:

```
What To Do — {date or range description}
══════════════════════════════════════════
{commit list}
──────────────────────────────────────────
{M} files changed, {A} insertions(+), {D} deletions(-)
```

---

## Step 3: Delegate to what-to-do agent

Launch the **what-to-do** agent with:
- COMMIT_RANGE
- DATE_FILTER (if provided)
- FOCUS (if provided)

The agent will:
1. Read the full diffs
2. Summarize completed work
3. Identify verification needs and risk patterns
4. Find incomplete work and TODOs
5. Generate the prioritized action plan

---

## Step 4: Present results

Show the agent's action plan to the user with clear section headers.

If CRITICAL verification items are found, highlight them prominently at the top.

If the project has a test runner or build command configured, include those in the Quick Commands section.
