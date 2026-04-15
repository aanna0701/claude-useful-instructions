# Migration: v1 → v2

v2 removes md-based state/relay and derives everything from GitHub PR + git.

## What changes

| v1 | v2 |
|---|---|
| 7 per-item md files (status/brief/checklist/relay/pr-relay/verify-result/review) | **1** per-item md: `contract.md` |
| 6 commands (plan/scaffold/impl/verify/review/revise + status) | **5** commands (plan/impl/refactor/review/status). No flags. |
| 5-stage pipeline (plan → scaffold → impl → verify → review → merge with revise branch) | **4-stage**: plan → impl \| refactor → review → merge. Revise = re-entry. |
| Relay Protocol (md + PR comments) | Deleted. PR itself is the relay. |
| `/work-verify` writes `verify-result.md` | CI (`.github/workflows/pr-checks.yml`) produces the check run. |
| Any merge strategy | **Squash only**. |
| `_work-item.mdc` / `*-guard.mdc` / `*-forbidden.mdc` auto-generated | Deleted. |

## Steps

1. **Back up** (the toolkit tags `v1-final` before release):
   ```bash
   git tag my-pre-v2-backup
   ```

2. **Dry-run the migration**:
   ```bash
   bash <toolkit>/scripts/migrate-v1-to-v2.sh
   ```
   Review the deletion list.

3. **Apply**:
   ```bash
   bash <toolkit>/scripts/migrate-v1-to-v2.sh --apply
   ```

4. **Reinstall the v2 bundle**:
   ```bash
   <toolkit>/install.sh <your-repo>
   ```

5. **In-flight items**: any PR still in flight at migration time keeps working — only `contract.md` is needed. If a v1 item lacks `contract.md`, recreate via `/work-plan` or write one by hand from the v1 `brief.md`/`checklist.md` before deleting them.

## Rollback

```bash
git reset --hard v1-final
```
(at the toolkit repo) and use the old bundle.

## FAQ

**Q. My repo has no CI. Can I skip it?**
No. v2 requires at least one `pull_request`-triggered check run. `install.sh` copies `pr-checks.yml` (Python: ruff + mypy + pytest). Adapt for other stacks.

**Q. Where are `status:*` labels?**
Removed. State is derived from PR fields, not labels. `/work-status` computes state on each call.

**Q. How do I handle CHANGES_REQUESTED?**
Re-run `/work-impl {ID}` or `/work-refactor {ID}`. The command fetches unresolved review threads via GraphQL and treats each as a MUST-fix. After fixing, resolve each thread with `resolveReviewThread`.

**Q. What about Cursor `.mdc` rules?**
v2 does not auto-generate per-item mdc files. If you use Cursor, maintain repo-level `.cursor/rules/` yourself. `contract.md` is the authoritative boundary document read by all three AIs (Claude, Cursor, Codex).
