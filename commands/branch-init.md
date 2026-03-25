# branch-init — Initialize Branch Map for This Repository

Detect or configure the branch hierarchy so Claude knows where to create and merge branches.

Works standalone (single agent) or with the collab workflow.

---

## Input

**$ARGUMENTS**: Optional branch name to use as working parent (e.g., `develop`, `research`).

If no arguments provided, auto-detect from the repository.

---

## Execution Steps

### Step 1: Check Existing Config

```bash
cat .claude/branch-map.yaml 2>/dev/null
```

If it exists, print current config and ask: "Branch map already exists. Update it? [y/N]"
If user declines, stop.

### Step 2: Detect Branch Hierarchy

If no `$ARGUMENTS` provided:

1. List local and remote branches:
   ```bash
   git branch -a --format='%(refname:short)'
   ```
2. Identify known integration branches in order: `main`, `master`, `develop`, `development`, `research`, `staging`, `release`.
3. Build `trunk_chain` from the branches that actually exist.
4. Set `working_parent` to the deepest integration branch found.

If `$ARGUMENTS` provided:
- Verify the branch exists.
- Build `trunk_chain` from `main`/`master` up to the given branch.
- Set `working_parent` to `$ARGUMENTS`.

### Step 3: Confirm with User

Print the detected configuration:

```
Branch Map
──────────────────────────
Trunk chain:     main → develop → research
Working parent:  research
Merge target:    research
Feature prefix:  feat
──────────────────────────
```

Ask: "Correct? [Y/n/edit]"
- If "edit", ask which field to change.
- If "n", ask for the correct working parent.

### Step 4: Write Config

```bash
mkdir -p .claude
```

Write `.claude/branch-map.yaml` using the template from `.claude/templates/branch-map/branch-map.yaml`, filling in detected values.

If roles are detectable from the repo structure (e.g., `docs/` exists, `src/` exists), uncomment and fill relevant role entries.

### Step 5: Auto-Audit CI (if applicable)

```bash
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```

If workflows exist, automatically run `/gha-branch-sync` to check alignment with the new branch map. Report issues inline — do not ask for separate confirmation to run the audit.

If no workflows exist, skip silently.

### Step 6: Summary

Print:
- Config file path
- Trunk chain
- Working parent
- Whether roles were auto-detected
- CI audit result summary (if workflows were scanned)
- Reminder: "Edit `.claude/branch-map.yaml` to customize roles, merge policy, or branch naming."
