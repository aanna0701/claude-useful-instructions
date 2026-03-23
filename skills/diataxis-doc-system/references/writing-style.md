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

### Chunking: Break Content into Scannable Blocks

The brain processes information in **chunks**. Dense paragraphs force linear reading; chunked content enables skimming.

- **Paragraph limit:** Max 3-4 sentences per paragraph. If longer, split at the next topic shift.
- **3-line rule:** If a sentence list exceeds 3 items, convert to bullet points or numbered list.
- **Breathing room:** Always insert a blank line between paragraphs, before/after code blocks, and before/after headings.
- **One concept per section:** Each H3 section should cover exactly one idea. If you need "also" or "additionally", it's a new section.

### Heading Hierarchy and Spacing

Headings are the skeleton of the document — they must work standalone.

- **Self-contained headings:** A reader scanning only H2/H3 headings should understand the document's structure. Avoid generic headings like "Overview", "Details", "Notes".
- **Heading depth:** Use H2 for major sections, H3 for subsections. Avoid H4+ — restructure into separate H2 sections instead.
- **Heading icons by level:** Use distinct icon styles per heading level for instant visual differentiation:

  | Level | Format | Icon rule | Example |
  |-------|--------|-----------|---------|
  | H1 | `# {type-emoji} Title` | Doc-type icon (fixed per type) | `# 🔧 카메라 캡처 설정하는 방법` |
  | H2 | `## {role-emoji}{N} Title` | Section-role icon + number (no §) | `## 🎯1 사전 조건` |
  | H3 | `### 🔹 Title` | Always 🔹 (uniform, no variation) | `### 🔹 Key Decisions` |

  **H1 doc-type icons** (determined by frontmatter `type` field):

  | `type` | Icon |
  |--------|------|
  | tutorial | 🎓 |
  | howto | 🔧 |
  | explanation | 💡 |
  | reference | 📖 |
  | plan | 📋 |

  **H2 section-role icons** (assigned by section content — emoji replaces `§`):

  | Role | Icon | Keywords |
  |------|------|----------|
  | Goal / Prerequisites | 🎯 | 개요, 사전 조건, 목적, 범위 |
  | Setup / Config | ⚙️ | 설정, 환경, 구성, 설치 |
  | Step / Procedure | 📍 | N단계, 절차, 실행, 방법 |
  | Architecture / Structure | 🏗️ | 아키텍처, 구조, 설계, 계층 |
  | Analysis / Background | 🔍 | 배경, 이유, 비교, 한계 |
  | Troubleshooting | 🔥 | 트러블슈팅, FAQ, 에러, 문제 |
  | Wrap-up / Summary | ✅ | 요약, 다음 단계, 정리 |
  | Data / Schema | 🗂️ | 스키마, 테이블, 데이터 구조 |
  | CLI / Commands | 💻 | CLI, 명령어, 옵션 |
  | Comparison | ⚖️ | 대안 비교, 트레이드오프 |
  | General (catch-all) | 📌 | use sparingly |

  **H3 rule:** Always `🔹` — no semantic variation at H3 level. Semantic signals belong in body text (admonitions, inline icons), not in headings.

- **Section separators:** Use `---` between H2 sections to create clear visual breaks. Do not use `---` between H3 subsections.

### Bullet Points and Indentation

- **7 +/- 2 rule:** Keep 5-9 items per list. Beyond 9 items, split into sub-lists or use a table.
- **Parallel structure:** Unify grammatical form within each list.
  - Bad: "Download file, Click install button, Reboot completed"
  - Good: "Download file, Install program, Reboot system" (consistent verb-noun pattern)
- **Indentation limit:** Maximum **3 levels** of nesting. If deeper nesting is needed, restructure as a separate section or use a table.

### Emoji Protocol: Icons, Not Decoration

Emojis serve as **functional icons** — visual anchors that let readers identify content type at a glance.

**Two contexts for emoji usage:**

1. **Headings** — follow the heading icon rules in "Heading Hierarchy" above (H1 type-icon, H2 role-icon+number, H3 always 🔹).
2. **Body text** — use the semantic icon mapping below for inline emphasis and admonition blocks.

**Body text icon mapping** (use consistently across all documents):

| Signal | Icon | Usage |
|--------|------|-------|
| Danger / Warning | ⚠️ | Breaking changes, data loss risk, security |
| Caution | ⚡ | Performance impact, deprecation |
| Tip / Best practice | 💡 | Helpful hints, recommendations |
| Success / Verified | ✅ | Confirmed steps, passing checks |
| Key point / Anchor | 📌 | Important callouts |
| Prerequisite | 📋 | Required setup, dependencies |

**Placement rules:**

- **Position:** Place the icon **before** the text, not after. The icon acts as a visual anchor for scanning.
  - Good: `⚠️ Never commit secrets to source code.`
  - Bad: `Never commit secrets to source code. ⚠️`
- **Density limit:** Max **2 icons per paragraph**. If everything has an icon, nothing stands out.
- **Consistency:** Once you assign an icon to a meaning (e.g., ⚠️ = warning), use it the same way throughout the entire document. Never reuse the same icon for different meanings.
- **Do NOT use semantic emojis in H3 headings.** H3 is always `🔹`. Use admonition blocks (`!!! warning`, `!!! tip`) or inline icons for semantic signals.

### Color and Highlighting

Use color as a **functional signal**, not decoration:

- **Accessibility rule:** Never rely on color alone. Always pair with an icon or bold text so color-blind readers receive the same signal.
- **Color limit:** Restrict highlight colors to **1-2** per document. More colors create visual noise.
- **Blockquotes for emphasis:** Use `>` callout blocks for supplementary notes, tips, or warnings — not for regular content.

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

- **Bold budget:** Max 2-3 bold terms per paragraph. If everything is bold, nothing stands out.
- Do not combine bold and italic together (`***text***`) — choose one.
- Always use `code font` for anything the reader types, copies, or references in code.
- **First-mention rule:** Bold a key term on first use only. Subsequent mentions use normal weight.

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
- [ ] Are headings self-contained and descriptive (not "Overview", "Details", "Notes")?
- [ ] Is there a clear visual hierarchy (H2 → H3 → content, no H4+)?
- [ ] Are H2 sections separated by `---`?

### Chunking Test
- [ ] Are paragraphs 4 sentences or fewer?
- [ ] Are inline lists of 3+ items converted to bullet points?
- [ ] Is there a blank line before/after code blocks and headings?
- [ ] Does each H3 section cover exactly one concept?

### Objectivity Test
- [ ] Are vague qualifiers ("fairly", "quite", "somewhat") replaced with specifics?
- [ ] Are claims backed by numbers, examples, or references?

### Simplicity Test
- [ ] Does each sentence contain only one idea?
- [ ] Are sentences under 30 words?
- [ ] Are lists under 9 items?
- [ ] Is nesting within 3 levels?

### Emphasis Test
- [ ] Is bold limited to 2-3 terms per paragraph?
- [ ] Are key terms bolded only on first mention?
- [ ] Is code font used for all commands, variables, and file names?
- [ ] Do callout blocks have an appropriate icon/signal?
