# gha-branch-sync — Audit GitHub Actions Against Branch Map

Check whether CI/CD workflows align with the project's branch hierarchy and merge policy.

---

## Input

**$ARGUMENTS**: Optional flags.
- No arguments: audit only (report issues)
- `--fix`: apply recommended fixes after confirmation
- `--generate`: generate missing workflows based on branch-map roles and CI scope

---

## Execution Steps

### Step 1: Read Branch Map

Read `.claude/branch-map.yaml`. If missing, auto-initialize by running `/branch-init` logic inline (detect branches, confirm with user, write config), then continue.

### Step 2: Inventory Workflows

```bash
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```

If no workflows found and `--generate` not given, report: "No GitHub Actions workflows found. Run with `--generate` to create them." and stop.

### Step 3: Run Audit

Spawn `ci-audit-agent` with:
- branch-map.yaml contents
- list of workflow files to audit

### Step 4: Display Report

Print the agent's audit results (issue count, severity breakdown, recommended fixes).

### Step 5: Apply Fixes (if --fix)

If `--fix` flag was given:
1. Show each recommended diff
2. Ask: "Apply this fix? [y/N]" for each
3. Apply confirmed changes
4. Print summary of applied changes

### Step 6: Generate Workflows (if --generate)

If `--generate` flag was given:

1. Read `branch-map.yaml` roles and their path mappings.
2. Scan open work item contracts for `CI Scope` fields.
3. For each role with paths defined, generate a path-aware workflow:
   - Trigger on push/PR to `working_parent` and feature branches
   - Path filter scoped to the role's paths
   - Jobs matching the CI scope (lint, test, typecheck, build, etc.)
   - Parent freshness check step (compare against `working_parent`)
4. Show generated workflow files and ask: "Create these workflows? [y/N]"
5. Write confirmed files to `.github/workflows/`.

Generated workflows follow these conventions:
- Filename: `ci-{role}.yml` (e.g., `ci-backend.yml`, `ci-docs.yml`)
- Reusable where possible (composite actions for shared steps)
- Include branch-map merge target as configurable input, not hardcoded
