# Codex Auto-Generation Policy

This repository now treats Claude-format instruction files as the only source of truth. Codex assets are generated from those sources and should not be hand-authored in normal workflows.

## Current policy

- Mode: `auto-only`
- Build strategy: `clear-and-rebuild`
- Source of truth: `skills/*/SKILL.md`
- Generated outputs:
  - `.agents/skills/*/SKILL.md`
  - `.agents/skills/*/agents/openai.yaml`
  - `.codex/generated/skills-manifest.json`
- Manual overrides: not supported in this version

## Why this policy exists

- It keeps Claude and Codex content from drifting apart.
- It reduces copy-paste maintenance when a new skill is added.
- It removes stale generated files automatically when skills are renamed, deleted, or reorganized.
- It avoids unsafe “best guess” conversions for commands, hooks, and other Claude-only concepts.

## Supported and unsupported mappings

### Supported today

- Skill discovery from `skills/<name>/SKILL.md`
- Frontmatter extraction for `name` and `description`
- Reference inventory from `skills/<name>/references/`
- Codex metadata generation under `.agents/skills/`
- Full rebuild of generated Codex outputs on each build

### Explicitly unsupported today

- Automatic conversion of slash commands in `commands/`
- Hook conversion from `hooks/`
- Rule conversion from `rules/`
- Manual override files for special Codex behavior

If a mapping is not clearly safe, the generator must leave it unsupported instead of inventing behavior.

## New skill workflow

1. Add a new skill under `skills/<name>/SKILL.md`.
2. Make sure the file has valid frontmatter:
   - `name`
   - `description`
3. Add any optional support files under `skills/<name>/references/`.
4. Run `npm run validate:codex`.
5. Run `npm run build:codex`.
6. Review generated files under `.agents/skills/<name>/`.

## Safety rules for future evolution

- Keep generation additive and deterministic at the source layer.
- Clear generated outputs completely before each rebuild.
- Do not introduce partial manual patches unless the repo adopts an explicit override design later.
- Prefer “unsupported” over lossy conversion.
- Upgrade the generator before introducing human-maintained Codex copies.
