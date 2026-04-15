# Google C++ Style Guide — Project Rules

> Canonical source: https://google.github.io/styleguide/cppguide.html
> This file is a working checklist, not a replacement for the upstream guide.

## Formatting (enforced by `.clang-format` with `BasedOnStyle: Google`)

- **Line length**: 80 columns.
- **Indentation**: 2 spaces, no tabs.
- **Braces**: K&R style; opening brace on same line for functions, classes, and control blocks.
- **Pointer/reference alignment**: `Type* ptr`, `Type& ref` (asterisk with type).
- **Includes**: group in this order, one group per block, alphabetized within each group:
  1. Related header (for `.cc` files, the matching `.h`)
  2. C system headers (`<sys/types.h>`)
  3. C++ standard library (`<vector>`, `<string>`)
  4. Other libraries' headers (`<absl/strings/str_cat.h>`)
  5. Project headers (`"project/foo/bar.h"`)

Run `clang-format -i <file>` before committing.

## Naming

| Kind | Convention | Example |
|------|------------|---------|
| Files | `snake_case` | `my_class.cc`, `my_class.h` |
| Types (class / struct / enum / typedef / alias) | `PascalCase` | `MyClass`, `UrlTable` |
| Variables (local, member, parameter) | `snake_case` | `table_name`, `num_errors` |
| Private/protected class members | `snake_case_` (trailing underscore) | `count_`, `owner_ptr_` |
| Struct data members | `snake_case` (no trailing underscore) | `x`, `y` |
| Functions (regular + accessors) | `PascalCase` | `RunLoop()`, `set_count(int)` |
| Constants (global, class, namespace, `constexpr`) | `kCamelCase` | `kMaxRetries` |
| Enumerators | `kCamelCase` | `enum class Color { kRed, kBlue };` |
| Macros | `SCREAMING_SNAKE_CASE` (avoid when possible) | `LOG_FATAL` |
| Namespaces | `snake_case`, short | `util`, `net` |

## Language Features

- Prefer `nullptr` over `NULL` or `0`.
- Prefer `auto` only when it improves readability and the type is obvious from context.
- Use `constexpr` for compile-time constants; `const` for immutability.
- Integer types: use `int` for small values that fit, `int64_t`/`uint64_t` (from `<cstdint>`) when size matters. Avoid `long`, `short`, `long long` by themselves.
- **Ownership**: prefer `std::unique_ptr` for unique ownership, `std::shared_ptr` only when shared ownership is essential. Pass raw pointers for non-owning references, or use references when non-null is guaranteed.
- **Rule of Zero / Three / Five**: default to Rule of Zero (let the compiler generate). If you need one, provide all five (destructor, copy ctor, copy assign, move ctor, move assign) consistently. Use `= default` / `= delete` explicitly.
- **No exceptions** in Google style by default (legacy rule — confirm with project policy; many modern projects allow exceptions).
- **RAII** for all resource management.
- Use `override` and `final` on virtual methods when applicable.

## Class Design

- Single public section first, then protected, then private.
- Data members at the bottom of the class body.
- Prefer composition over inheritance.
- Mark single-argument constructors `explicit`.
- Follow the rule of 3/5/0 consistently.
- Avoid default arguments on virtual functions.

## Comments & Documentation

- Every file starts with a license/copyright header (project policy).
- Every non-trivial class and function has a comment explaining **what it does** and the contract (inputs, outputs, ownership, thread-safety).
- Use `//` for comments; reserve `/* ... */` for license headers and rare long blocks.
- Document preconditions, postconditions, and invariants explicitly when non-obvious.

## Forbidden Patterns

- `using namespace std;` at namespace or global scope (`.h` files never, `.cc` files only for very narrow scopes).
- Non-`const` global variables (use constants or function-local statics).
- `goto` except for cleanup in C-style code.
- Shadowing parameters / members / locals.

## Tooling

| Tool | Purpose |
|------|---------|
| `clang-format` (Google style) | Formatting (installed by `google-style` bundle as `.clang-format`) |
| `clang-tidy` with `google-*` checks | Linting |
| `cpplint` | Naming / ordering / include-guard checks |

Include-guard convention: `<PATH>_<FILE>_H_` (uppercase, underscores). Example: `project/foo/bar.h` → `PROJECT_FOO_BAR_H_`.
