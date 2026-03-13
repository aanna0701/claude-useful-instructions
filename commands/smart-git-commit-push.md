# smart-git-commit-push — Analyze changes, commit by feature, and push

Analyze all staged and unstaged changes, group them by independent feature/concern, create separate commits for each group, then push to remote.

Target branch: $ARGUMENTS (if empty, push to current branch's upstream)

---

## Step 1: Gather current state (parallel)

Run all of the following in parallel:

1. `git status` — check working tree status (never use `-uall`)
2. `git diff` — unstaged changes
3. `git diff --cached` — staged changes
4. `git log --oneline -10` — recent commit style reference
5. `git branch --show-current` — current branch name

---

## Step 2: Analyze and group changes by feature

From the diff output, identify **independent logical units of change**. A logical unit is a set of changes that together implement one coherent feature, fix, or concern.

Grouping criteria:
- **Same feature/module**: Files that work together for one feature (e.g., handler + test + migration)
- **Same type of change**: Pure refactors, dependency updates, config changes, documentation updates
- **Dependency order**: If change B depends on change A, commit A first

For each group, determine:
- Which files belong to it
- A commit type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
- A concise commit message describing the "why"

Print the proposed grouping as a table:

```
Proposed commits
──────────────────────────────────────────────
#1  feat: add user authentication endpoint
    - src/auth/handler.go
    - src/auth/handler_test.go
    - migrations/003_add_users.sql

#2  fix: correct timezone handling in scheduler
    - src/scheduler/cron.py

#3  chore: update dependencies
    - requirements.txt
    - package-lock.json
──────────────────────────────────────────────
```

**Ask the user for confirmation before proceeding.** The user may:
- Approve as-is
- Request re-grouping (merge or split groups)
- Exclude certain files
- Edit commit messages

---

## Step 3: Stage and commit each group sequentially

For each approved group, in dependency order:

1. `git add <file1> <file2> ...` — stage only files in this group
2. `git commit -m "<type>: <message>"` — commit with the agreed message
3. Verify with `git status` that no unintended files were included

Rules:
- NEVER use `git add -A` or `git add .`
- NEVER use `--no-verify`
- Stage files by explicit path only
- If a commit fails (e.g., pre-commit hook), fix the issue and retry as a NEW commit
- Skip files that contain secrets (.env, credentials, tokens) — warn the user

---

## Step 4: Push to remote

After all commits are created:

1. Determine push target:
   - If `$ARGUMENTS` is provided, use it as the target branch
   - Otherwise, push to the current branch's upstream
2. If the branch has no upstream, use `git push -u origin <branch>`
3. Otherwise, use `git push`

**Ask the user for confirmation before pushing.**

---

## Step 5: Print summary

```
Smart commit complete
──────────────────────────────────────────────
Commits created: N
  #1  abc1234  feat: add user authentication endpoint (3 files)
  #2  def5678  fix: correct timezone handling (1 file)
  #3  ghi9012  chore: update dependencies (2 files)

Pushed to: origin/feature-branch
──────────────────────────────────────────────
Skipped files: .env (contains secrets)
```
