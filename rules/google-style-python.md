# Google Python Style Guide — Project Rules

> Canonical source: https://google.github.io/styleguide/pyguide.html
> This file is a working checklist, not a replacement for the upstream guide.

## Formatting

- **Line length**: 80 columns (Google default). Some projects relax to 100; project `pyproject.toml` wins if configured.
- **Indentation**: 4 spaces, no tabs.
- **String quotes**: be consistent within a file. Google examples use `'single'` for identifiers and `"""docstrings"""`; many modern projects use `"double"`. Configure ruff/black once and don't mix.
- **Blank lines**: 2 between top-level defs, 1 between methods.
- Trailing commas on multi-line literals, arguments, and imports.

## Imports

Three groups, separated by a blank line, each alphabetized:

1. Standard library (`import os`, `import sys`)
2. Third-party (`import numpy as np`, `from absl import flags`)
3. Project-local (`from my_project.util import helpers`)

- One import per line: `import os`, not `import os, sys`.
- Prefer absolute imports (`from my_project.util import x`) over relative imports.
- `from module import *` is forbidden.

## Naming

| Kind | Convention | Example |
|------|------------|---------|
| Modules / packages | `snake_case` | `data_loader.py` |
| Classes / exceptions / type vars | `PascalCase` | `DataLoader`, `ValueError`, `T = TypeVar('T')` |
| Functions / methods / variables | `snake_case` | `load_data`, `row_count` |
| Constants (module-level) | `SCREAMING_SNAKE_CASE` | `MAX_RETRIES = 3` |
| "Private" module/class members | `_leading_underscore` | `_internal_helper`, `_count` |
| Name-mangled ("really private") | `__double_leading_underscore` | `__cache` |
| Dunder (magic) methods / attrs | `__double_underscores__` | `__init__`, `__repr__` |

Single-letter names only for counters/iterators (`i`, `j`, `n`). Never `l`, `O`, `I` as standalone names.

## Type Hints

- All public functions must have type annotations (parameters + return).
- Use `from __future__ import annotations` at the top of new files to get PEP 604 style (`X | Y`) on Python 3.9.
- Prefer built-in generics on 3.9+: `list[int]`, `dict[str, int]`, `tuple[int, ...]`.
- Use `Optional[X]` → `X | None` in annotations (3.10+).
- `typing.Protocol` for duck-typed interfaces.

## Docstrings

Google-style docstrings, not NumPy/reStructuredText. Triple double quotes.

```python
def fetch_rows(table_name: str, limit: int = 10) -> list[dict]:
    """Fetches rows from a table.

    Retrieves rows pertaining to the given keys from the given table.

    Args:
        table_name: Fully qualified table name.
        limit: Maximum number of rows to return.

    Returns:
        A list of row dictionaries, one per matching row.

    Raises:
        IOError: If the table cannot be read.
    """
```

- First line: one-sentence summary in imperative mood, ending with a period.
- One blank line, then the extended description (optional).
- Sections (`Args:`, `Returns:`, `Yields:`, `Raises:`, `Attributes:`) with their contents indented.
- Every public module, class, and function has a docstring.

## Language Features

- Prefer f-strings (`f"{x}"`) over `.format()` or `%` formatting.
- Use `@dataclass(frozen=True)` or `typing.NamedTuple` for small value objects; prefer immutability.
- Use comprehensions over `map`/`filter` with lambdas.
- Context managers (`with ...`) for any resource that needs cleanup.
- Generators (`yield`) over eagerly-constructed lists when the caller iterates once.
- Avoid mutable default arguments (`def f(x=[])` — use `None` and build inside).
- `is` / `is not` only for `None`, `True`, `False`, and sentinels.

## Forbidden / Discouraged

- `from x import *` at module scope.
- `eval`, `exec`, or `__import__` unless unavoidable (justify with a comment).
- Bare `except:` — always catch specific exceptions.
- Catching and silently swallowing exceptions.
- Module-level side effects (non-trivial work during import).
- Global mutable state.

## Tooling

| Tool | Purpose |
|------|---------|
| `ruff` (+ `ruff format`) | Formatting + most lint rules (PEP 8, pyflakes, import sort) |
| `mypy` / `pyright` | Static type checking |
| `pydocstyle` (or ruff `D` rules) | Docstring style (enable Google convention) |
| `pylint` with google config (optional) | Stricter checks — only when team wants them |

### Recommended `ruff` config (`pyproject.toml`)

```toml
[tool.ruff]
line-length = 80
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "D", "ANN"]
ignore = ["D100", "D104", "D107"]  # module/package/init docstring — adjust per project

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```
