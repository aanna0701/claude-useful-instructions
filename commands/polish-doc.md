# polish-doc — Polish Existing Documentation

Applies writing-style and structural fixes directly to existing documents. Counterpart to `write-doc` (creates) and `doc-reviewer` (suggests only).

Target: $ARGUMENTS (file path or glob pattern, optional depth flag)

---

## Step 0: Parse Arguments

| Pattern | Depth | Scope |
|---------|-------|-------|
| `[filepath]` | `full` (default) | Single file |
| `[filepath] --quick` | `quick` (style only) | Single file |
| `[glob-pattern]` | `full` | Multiple files |
| `[glob-pattern] --quick` | `quick` | Multiple files |

If no arguments provided, ask:
> "Which document do you want to polish? Provide a file path or glob pattern."

---

## Step 1: Pre-Polish Review

For each target file:
1. Read the file
2. Detect document type from frontmatter `type` field
3. If no frontmatter, infer type from content and path location
4. Show the user a brief assessment before polishing:

```
Target:  [file-path]
Type:    [detected type]
Depth:   [quick / full]
Issues:  [estimated count from quick scan]
```

Proceed unless user objects.

---

## Step 2: Delegate to Agent

Delegate to `doc-polisher` agent with:
- File path
- Detected type
- Polish depth

For multiple files (glob), process sequentially — one file at a time.

---

## Step 3: Completion Report

After all files processed:

```
Polish complete
─────────────────────────────────
Files polished: [N]
Total edits:    [N]
─────────────────────────────────
[per-file summary from agent]

Next steps:
  - Review changes: git diff
  - Run /write-doc review [filepath] for quality score
```
