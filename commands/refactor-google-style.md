# /refactor-google-style — Refactor codebase to Google Style Guide

Apply the Google C++ / Python Style Guide across the whole repository.

## Input

```
/refactor-google-style                # all C++ + Python files in the repo
/refactor-google-style src/           # restrict scope to a path
/refactor-google-style src/foo.cc     # single file
/refactor-google-style --cpp-only
/refactor-google-style --python-only
/refactor-google-style --dry-run      # report what would change; no writes
```

## Preconditions

- Clean worktree (or explicit user confirmation to proceed with uncommitted changes).
- For Python projects: `ruff` installed (or the orchestrator installs it via `uv add --dev ruff`).
- For C++ projects: `clang-format` available on PATH.

## Steps

1. **Discover scope** — glob `**/*.{cpp,cc,cxx,h,hpp,py}` filtered by `--cpp-only` / `--python-only` / path argument, excluding `.venv/`, `build/`, `dist/`, `node_modules/`, `third_party/`, `vendor/`, `.git/`.
2. **Install/verify config** — if missing:
   - Copy `.clang-format` (Google preset) from `templates/google-style/.clang-format` into the repo root.
   - Add ruff section to `pyproject.toml` (from the skill's recommended config). Skip if already configured.
   - Install `.cursor/rules/google-style-{cpp,python}.mdc` so Cursor applies the same rules.
3. **Mechanical pass** (fast, deterministic — do first so the semantic pass has clean diffs to work on):
   - C++: `clang-format -i <files>`
   - Python: `ruff check --fix --unsafe-fixes <files>` then `ruff format <files>`
4. **Semantic pass** — dispatch in parallel:
   - C++ files → `google-style-refactor-cpp` agent (batch in groups of ≤ 20 files per invocation)
   - Python files → `google-style-refactor-python` agent (same batching)
   - Each agent reads `rules/google-style-{cpp,python}.md` and rewrites per the checklist.
5. **Verify** — re-run formatters to confirm no regressions. Run project tests if a test command is discoverable (`pytest`, `ctest`, `cargo test`, etc.). Otherwise note "tests skipped — no command found".
6. **Summary** — report per-language:
   - Files scanned / changed / skipped (with reason)
   - Top 5 rule categories violated (naming, includes, docstrings, type hints, etc.)
   - Any files the agent flagged as needing human review (ambiguous renames, public API breaks, etc.)

## Dry-run

Skips writes; prints the planned changes and estimated diff size per file. Useful for gauging blast radius before committing.

## Safety

- Never rename symbols in public API files (those exported via `__all__`, published headers, or matching project-level `public_api/` globs) without an explicit follow-up commit and user confirmation. Flag instead.
- Never touch files under `third_party/`, `vendor/`, or any path listed in `.gitattributes` as `linguist-vendored`.
- On ambiguity (e.g. a class that looks like a namespace), leave the original and add a `# TODO(google-style)` comment.
- Produces one commit per language (`refactor(style): apply Google C++ style`, `refactor(style): apply Google Python style`) so PRs split cleanly.

## Output

```
Google Style Refactor — done
────────────────────────────
C++    scanned: 142   changed: 118   skipped: 24 (third_party: 18, flagged: 6)
Python scanned: 87    changed: 74    skipped: 13 (public API: 9, flagged: 4)

Commits:
  refactor(style): apply Google C++ style     (118 files)
  refactor(style): apply Google Python style  (74 files)

Needs human review (flagged by agents):
  - src/core/api.h:42 — class → namespace rename would break ABI
  - src/data/loader.py:108 — public function rename, check callers
```

## Errors

- Missing `clang-format` / `ruff`: warn, run only the language whose tooling is available.
- Tests fail after refactor: revert the problematic file, keep the rest, list the reverts in the summary.
