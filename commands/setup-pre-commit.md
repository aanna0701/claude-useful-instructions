---
description: Scaffold .pre-commit-config.yaml (+ .clang-format if C++) for the current project using claude-useful-instructions templates.
---

# /setup-pre-commit

Install pre-commit configuration in the current project, picking a variant per `rules/pre-commit-policy.md`.

## Steps

1. **Resolve plugin root.** Use `${CLAUDE_PLUGIN_ROOT}` if set; otherwise locate it:
   ```bash
   find ~/.claude -maxdepth 6 -path '*claude-useful-instructions/templates/pre-commit/variants' -type d 2>/dev/null | head -1
   ```
   Call this `$TPL_DIR`.

2. **Detect target project root.** Use `git rev-parse --show-toplevel` from the user's current working directory. If not a git repo, prompt the user for the project root.

3. **Pick variant.**
   - If `<project>/uv.lock` exists → `local-uv`
   - Else if `<project>/pyproject.toml` contains `[tool.uv]` or `[dependency-groups]` → `local-uv`
   - Else → `external-mirrors`

4. **Pre-flight existing config.** If `<project>/.pre-commit-config.yaml` exists:
   - Diff against the selected variant.
   - If identical → report "already up to date" and skip writing.
   - If different → show the diff and ask the user before overwriting. Do not overwrite silently.

5. **Copy template.**
   ```bash
   cp "$TPL_DIR/<variant>.yaml" "<project>/.pre-commit-config.yaml"
   ```

6. **Copy `.clang-format`** only if the project has C/C++ sources:
   ```bash
   has_cpp=$(find "<project>" -maxdepth 4 \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name 'CMakeLists.txt' \) -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null | head -1)
   if [ -n "$has_cpp" ]; then
     cp "$TPL_DIR/../.clang-format" "<project>/.clang-format"
   fi
   ```

7. **Install the git hook.**
   ```bash
   cd "<project>" && pre-commit install
   ```
   If `pre-commit` is not on PATH, report and ask the user to install it (`uv tool install pre-commit` for uv users, `pipx install pre-commit` otherwise).

8. **First run.**
   ```bash
   cd "<project>" && pre-commit run --all-files
   ```
   Report failures verbatim. Do not auto-fix anything that pre-commit itself did not fix.

9. **Summarize**: variant chosen, files written, hook activation status, first-run outcome.

## Don'ts

- Do not edit the template in place inside the project. If a project needs a different setup, add a variant to the marketplace plugin (`templates/pre-commit/variants/<name>.yaml`) and extend `rules/pre-commit-policy.md`.
- Do not silently overwrite an existing `.pre-commit-config.yaml`.
- Do not commit the new files unless the user asks.
