# Pre-commit Policy

> Loaded user-wide by the `claude-useful-instructions` marketplace plugin. Applies to any project Claude works in.

Pre-commit configuration is a **per-project file** (`.pre-commit-config.yaml` at the project root). The marketplace plugin no longer auto-installs it — instead, Claude scaffolds it on demand using the templates and the rules below.

## When to scaffold

Scaffold `.pre-commit-config.yaml` (and the supporting `.clang-format` for C++ projects) when:
- The user asks: "set up pre-commit", "pre-commit 깔아줘", "linting 붙여줘", `/setup-pre-commit`.
- A new project is initialized and lacks `.pre-commit-config.yaml`.
- An existing config is clearly outdated (pinned to retired tool versions, refers to removed mirrors, or violates the variant rule below).

Do **not** silently overwrite an existing `.pre-commit-config.yaml`. Diff against the appropriate variant and propose changes; let the user decide.

## Variant selection (one rule, no flags)

Pick exactly one variant by inspecting the target project:

| Variant            | Trigger                                                                                       | Python hook source                                          |
|--------------------|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------|
| `local-uv`         | `uv.lock` exists, **or** `pyproject.toml` contains `[tool.uv]` / `[dependency-groups]`        | `repo: local` with `entry: uv run …` — `uv.lock` is SSOT    |
| `external-mirrors` | otherwise (pip / poetry / hatch / pip-tools / no Python)                                      | pinned `rev:` on `ruff-pre-commit`, `mirrors-mypy`, `pyright-python` |

Both variants share C++ and general hooks (clang-format, trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files ≤1000 kB).

Templates live in this plugin at:

```
${CLAUDE_PLUGIN_ROOT}/templates/pre-commit/.clang-format
${CLAUDE_PLUGIN_ROOT}/templates/pre-commit/variants/local-uv.yaml
${CLAUDE_PLUGIN_ROOT}/templates/pre-commit/variants/external-mirrors.yaml
```

Resolve `${CLAUDE_PLUGIN_ROOT}` at runtime — typically `~/.claude/plugins/marketplaces/claude-useful-instructions/`. If unsure, locate the templates via `find ~/.claude -path '*templates/pre-commit/variants*' -name '*.yaml'`.

## Scaffolding procedure

1. **Detect variant** by the rule above.
2. **Copy** the chosen variant to `<project_root>/.pre-commit-config.yaml`.
3. **Copy `.clang-format`** to `<project_root>/.clang-format` only if the project has C/C++ source files (`*.c`, `*.cc`, `*.cpp`, `*.h`, `*.hpp`, or `CMakeLists.txt` / `compile_commands.json`).
4. **Run `pre-commit install`** in the project so the git hook activates.
5. **Run `pre-commit run --all-files`** once, surface remaining failures to the user, but do not auto-fix outside what the hooks themselves do.

## Per-project divergence

If a project genuinely needs a different setup (e.g., Poetry-managed Python where `local-uv` does not fit and `external-mirrors` feels too generic), **add a new variant to this plugin** (`templates/pre-commit/variants/<name>.yaml`) and extend the table above. Do not fork the config inside the target project — that turns each project into a snowflake.

## Versions

Tool versions (`ruff`, `mypy`, `pyright`, `clang-format`) are pinned in the templates. Bumping them is a marketplace-side change, not a per-project change. After a bump:

```
/plugin marketplace update claude-useful-instructions
```

then re-scaffold the project's `.pre-commit-config.yaml` from the updated template.
