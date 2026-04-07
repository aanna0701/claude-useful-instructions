---
description: Full Claude → Cursor → Codex collab pipeline with human gates (plan, scaffold, implement, verify, review).
---

# Collab workflow

You were invoked with **`/collab-workflow`**. The user’s goal is in the rest of their message (treat that text as `{USER_INSTRUCTION}`).

## What to do

1. **Read the full pipeline** from `.cursor/rules/collab-pipeline.mdc` (the body below the YAML frontmatter). Ignore `globs` / `alwaysApply` in that file — you must follow the pipeline **now** because this slash command explicitly requests it.
2. Everywhere the pipeline uses `{USER_INSTRUCTION}`, substitute the user’s instruction from this chat turn (the part after `/collab-workflow`).

## If the rule file is missing

Tell the user to run `./install.sh --collab .` from their **claude-useful-instructions** checkout at the project root so `.cursor/rules/collab-pipeline.mdc` exists.

## Do not

- Replace the pipeline with ad-hoc steps.
- Skip terminal delegation for plan (Claude) and implement (Codex) when those tools are available.

The authoritative step-by-step content lives only in `.cursor/rules/collab-pipeline.mdc` to avoid drift; this command exists so **Cursor lists `/collab-workflow` in the slash menu**.
