# Writing Style: Readability and Clarity

This document defines visual formatting and sentence-level writing rules
that apply to **all document types** (Tutorial / How-to / Explanation / Reference).
Agents must Read this file alongside `common-rules.md` before writing any document.

---

## Foundation: Authoritative Style Guides

This document is based on two industry-standard developer documentation style guides.
When this document does not cover a specific case, defer to these references in order:

1. **[Google Developer Documentation Style Guide](https://developers.google.com/style)**
   — Voice and tone, word list, formatting, API documentation conventions.
2. **[Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/)**
   — Accessibility, global-ready writing, bias-free language, UI text patterns.

Key principles adopted from both guides:

| Principle | Google | Microsoft |
|-----------|--------|-----------|
| Use second person ("you") | ✅ | ✅ |
| Use active voice | ✅ | ✅ |
| Use present tense | ✅ | ✅ |
| Write short sentences | ✅ | ✅ |
| Use inclusive language | ✅ (word list) | ✅ (bias-free) |
| Avoid jargon and slang | ✅ | ✅ (global-ready) |

---

## 1. Structure and Visual Hierarchy

### Bullet Points and Indentation

- **7 +/- 2 rule:** Keep 5-9 items per list. Beyond 9 items, split into sub-lists or use a table.
- **Parallel structure:** Unify grammatical form within each list.
  - Bad: "Download file, Click install button, Reboot completed"
  - Good: "Download file, Install program, Reboot system" (consistent verb-noun pattern)
- **Indentation limit:** Maximum **3 levels** of nesting. If deeper nesting is needed, restructure as a separate section or use a table.

### Color and Icon Usage

Use color and icons as **functional signals**, not decoration:

| Signal | Color | Icon | Usage |
|--------|-------|------|-------|
| Danger / Warning | Red | `⚠️` | Breaking changes, data loss risk, security |
| Caution | Yellow/Orange | `⚡` | Performance impact, deprecation |
| Tip / Note | Blue/Green | `💡` `✅` | Best practices, helpful hints, success |

**Accessibility rule:** Never rely on color alone. Always pair with an icon or bold text
so color-blind readers receive the same signal.

### Callout Blocks

Use admonition/callout blocks for content that must stand out from the main flow:

```markdown
> **Warning:** This operation is irreversible. Back up your data first.

> **Tip:** Use `--dry-run` flag to preview changes without applying them.
```

---

## 2. Typography and Emphasis

Apply emphasis **functionally**, not for decoration:

| Element | Format | Example |
|---------|--------|---------|
| Key terms, UI labels | **Bold** | Click **Save** |
| Term definitions, file paths | *Italic* | The *manifest file* controls... |
| Commands, code, variables | `Code` | Run `npm install` |
| Warnings, critical rules | **Bold** + icon | **⚠️ Never commit secrets** |

### Rules

- Use **bold** sparingly — if everything is bold, nothing stands out.
- Do not combine bold and italic together (`***text***`) — choose one.
- Always use `code font` for anything the reader types, copies, or references in code.

---

## 3. Sentence Composition

### Active Voice First

Passive voice hides the actor and adds cognitive load.

- Bad: "The configuration file must be updated by the administrator."
- Good: "The administrator updates the configuration file."
- Best: "Update the configuration file." (imperative for instructions)

### Positive Phrasing

Tell the reader what to DO, not what to avoid.

- Bad: "Do not use the old API endpoint."
- Good: "Use the v2 API endpoint."
- Exception: Safety warnings should use negative phrasing — "**Never** store secrets in source code."

### One Sentence, One Idea

- Break compound sentences with "and", "but", "however" into separate sentences.
- Target: 15-25 words per sentence. Over 30 words signals a split is needed.

### DRY (Don't Repeat Yourself)

- If the same explanation appears in multiple places, extract it to a single location and link.
- Use cross-references: "See [Section X](../path/to/section.md)" instead of repeating content.

---

## 4. Tables vs Prose

### When to Use Tables

Use tables when comparing 2+ items across the same dimensions:

- Feature comparisons
- Parameter lists (name, type, default, description)
- Decision matrices
- Configuration options

### When NOT to Use Tables

- Narrative explanations (use prose)
- Sequential steps (use numbered lists)
- Single-dimension lists (use bullet points)

### Table Formatting Rules

- Always include a header row.
- Left-align text columns, right-align numeric columns.
- Keep cell content concise — if a cell exceeds 2 lines, consider restructuring.

---

## 5. Code Blocks

- Always specify the language for syntax highlighting: ` ```python `, ` ```bash `, etc.
- Include only the relevant snippet, not entire files.
- Add brief comments for non-obvious lines.
- Ensure all code is **copy-pasteable** and runnable as-is.
- Use placeholder values that are obviously fake: `YOUR_API_KEY`, `example.com`, `192.0.2.1`.

---

## 6. Readability Checklist

Apply this checklist during Phase 3 (quality review) alongside the common-rules checklist:

### Scanning Test
- [ ] Can a reader grasp the main points by reading only headings and bold text?
- [ ] Are headings descriptive (not generic like "Overview" or "Details")?
- [ ] Is there a clear visual hierarchy (H2 → H3 → content)?

### Objectivity Test
- [ ] Are vague qualifiers ("fairly", "quite", "somewhat", "appropriately") replaced with specifics?
- [ ] Are claims backed by numbers, examples, or references?

### Simplicity Test
- [ ] Does each sentence contain only one idea?
- [ ] Are sentences under 30 words?
- [ ] Are lists under 9 items?
- [ ] Is nesting within 3 levels?

### Emphasis Test
- [ ] Is bold used for key terms only (not entire paragraphs)?
- [ ] Is code font used for all commands, variables, and file names?
- [ ] Do callout blocks have an appropriate icon/signal?
