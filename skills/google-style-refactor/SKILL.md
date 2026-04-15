---
name: google-style-refactor
description: >
  Refactor an entire C++/Python codebase to the Google Style Guide.
  Runs automated formatters first (clang-format, ruff), then applies semantic
  changes (naming, docstrings, imports, type hints) via language-specific
  subagents. Triggers on: "google style", "google style guide", "Google C++
  style", "Google Python style", "refactor to google", "/refactor-google-style".
---

# Google Style Refactor

Brings a repository into conformance with the Google Style Guide — both formatting and semantic rules.

## Rules (auto-loaded)

- `rules/google-style-cpp.md` — C++ formatting, naming, includes, language features
- `rules/google-style-python.md` — Python formatting, naming, docstrings, type hints, imports

## Command

`/refactor-google-style` orchestrates the full pipeline:

1. **Scope discovery** — glob for `**/*.{cpp,cc,h,hpp,py}` excluding `.venv/`, `node_modules/`, `build/`, `dist/`, `third_party/`, `vendor/`.
2. **Baseline tooling** — ensure `.clang-format` (Google preset) and `ruff` config exist; install defaults if missing.
3. **Mechanical pass (fast)**:
   - C++: `clang-format -i` on every touched file.
   - Python: `ruff check --fix` + `ruff format`.
4. **Semantic pass (agents, in parallel)**:
   - `google-style-refactor-cpp` on batches of C++ files (naming, include order, ownership, docstrings).
   - `google-style-refactor-python` on batches of Python files (docstrings, type hints, naming, import groups).
5. **Verify** — re-run formatters + project tests. Report files changed, rules violated, files skipped.

## Agents

| Agent | Scope | Model | Effort |
|-------|-------|-------|--------|
| `google-style-refactor-cpp` | `*.{cpp,cc,h,hpp}` semantic rewrite | sonnet | medium |
| `google-style-refactor-python` | `*.py` semantic rewrite | sonnet | medium |

## Cursor / Antigravity Parity

Installing the `google-style` bundle also writes `.cursor/rules/google-style-cpp.mdc` and `.cursor/rules/google-style-python.mdc` with glob-matched triggers. Cursor's inline AI applies the same rules whenever those file types are edited — no separate Cursor configuration needed.

## Tooling Installed

| File | Purpose |
|------|---------|
| `.clang-format` | `BasedOnStyle: Google`, column limit 80, 2-space indent |
| `pyproject.toml` additions (ruff section) | PEP 8 + Google docstring convention + import sort |
| `.cursor/rules/google-style-cpp.mdc` | Cursor glob-triggered rule for C++ files |
| `.cursor/rules/google-style-python.mdc` | Cursor glob-triggered rule for Python files |

## References

- Upstream: https://google.github.io/styleguide/
- clang-format: https://clang.llvm.org/docs/ClangFormat.html
- ruff: https://docs.astral.sh/ruff/
