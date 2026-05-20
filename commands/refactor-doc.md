---
description: Restructure existing documentation against the actual repo/wiki. Default mode is full restructure per architect principles; --quick limits to style fixes.
---

# refactor-doc — Restructure / Polish Existing Documentation

Primary use case: **given a target document, read the referenced repo code (and optional wiki), then reconstruct the document** per the architect principles in `skills/diataxis-doc-system/references/architect-principles.md`. Output is shorter, structurally truer, and verified against code — not a copy-edit.

Counterparts: `/write-doc` (creates new docs), `doc-reviewer` agent (suggests only, no edits).

Target: $ARGUMENTS — `<doc-path> [--repo <path>] [--docs <path>] [--wiki <url>] [--quick] [--dry-run]`

Terminology:
- **doc site** (`--docs`) — in-repo static doc site (Starlight `src/content/docs/`, MkDocs `docs/`, Docusaurus `docs/`).
- **wiki** (`--wiki`) — external hosted wiki (Confluence, Notion, GitHub Wiki). Pass URL or local export path.
- **repo** (`--repo`) — the source code repo. The authoritative source. Code wins on any conflict with doc site or wiki.

---

## Step 0: Parse Arguments

| Pattern | Mode | Behavior |
|---------|------|----------|
| `<doc-path>` (default) | **restructure** | Re-classify, rebuild spine, verify against repo, rewrite |
| `<doc-path> --quick` | **polish** | Style/structure fixes only — no content rewrite |
| `<doc-path> --repo <path>` | restructure | Use given repo path as source of truth (default: cwd) |
| `<doc-path> --docs <path>` | restructure | Treat in-repo doc site (Starlight / MkDocs / Docusaurus) as secondary source |
| `<doc-path> --wiki <url>` | restructure | Treat external wiki (Confluence / Notion / GH Wiki) as tertiary source |
| `<glob>` | restructure / polish | Process files sequentially |
| `--dry-run` | any | Produce restructure plan only, no writes |

If no doc path provided, ask:
> "정리할 대상 문서 경로를 알려주세요. 참조할 레포 (`--repo`), 기존 doc site (`--docs`, Starlight/MkDocs/Docusaurus), 외부 wiki (`--wiki`, Confluence/Notion) 가 있다면 함께 주세요."

---

## Step 1: Read the Architect Principles

Before anything else, Read `skills/diataxis-doc-system/references/architect-principles.md`. The 13 sections there are the operating contract for this command — they are the spine, not a reference.

Only **after** classifying the type (Step 2.2), optionally consult one of the Diátaxis sub-templates (`guide-rules.md` / `explain-rules.md` / `reference-rules.md`) if its template fits cleanly. The 12-type spine in `architect-principles.md` §3–§7 takes precedence over those templates whenever they conflict.

---

## Step 2: Pre-Restructure Audit

For each target file:

1. **Read the doc** in full.
2. **Classify the type** per `architect-principles.md` §3. If the doc mixes types, mark a **split** is required.
3. **Identify code anchors** — every module / function / config / endpoint the doc references. List them as concrete paths.
4. **Read the code** at those anchors. Verify each claim. Flag stale / incorrect / missing claims.
5. **Extract runtime flow** from code (§6), independent of what the doc says.
6. **Show the user a brief audit** before rewriting:

```
Target:        <file-path>
Detected type: <Architecture | Implementation Spec | Runtime Flow | API Reference | How-To | Tutorial | Runbook | ADR | Design Doc | Experiment Note | Troubleshooting | Deployment>
Mode:          <restructure | polish>
Mixed types?:  <none | needs split into: …>
Code anchors:  <N modules / configs verified>
Stale claims:  <N> (listed below if any)
Spine plan:    <4-7 section names that will form the new document>
Volume:        <input lines> → <est. output lines>  (reduction is normal)
Filing (opt):  <Diátaxis bucket — only if project uses a doc-site adapter (Starlight/MkDocs/Docusaurus)>
```

Proceed unless the user objects.

---

## Step 3: Restructure (default mode)

Apply the procedure in `architect-principles.md` §13:

1. Build the spine — the 4-7 sections the document actually needs for its classified type.
2. Drop everything not on the spine. Salvageable side content moves to links or appendix.
3. Rewrite each section using the type-specific discipline (`architect-principles.md` §4).
4. Insert diagrams (Mermaid / PlantUML) where flow or structure beats prose. Delegate complex ones to the `diagram-architect` skill.
5. For runtime systems, include a runtime flow section (§6). For AI/ML, enforce the separation in §8. For robotics/VLA, enforce §9.
6. Replace duplicated content with cross-links to canonical sources (code paths, ADRs, references, glossary).
7. Apply `writing-style.md` rules (headings, emojis, tables, code blocks).
8. Final audit against the 5 goals in §1 — cut any section that doesn't earn its place.

**Delegate** the actual write to the `doc-polisher` agent with:
- File path
- Detected type (expanded taxonomy + Diátaxis mapping)
- Mode (`restructure` or `polish`)
- Code anchors + verified claims
- Spine plan
- List of stale claims to fix

For globs: process sequentially, one file at a time.

---

## Step 4: Quick (polish) Mode

If `--quick`: skip Steps 2.3–2.5 (no code verification). Apply only:
- `writing-style.md` — headings, emoji protocol, bold/italic/code discipline, table vs prose, code-block hygiene.
- `common-rules.md` §6 — review checklist (frontmatter, links, terminology).

Do not rewrite content. Do not move sections.

---

## Step 5: Completion Report

```
Polish complete
─────────────────────────────────
Files:           <N>
Mode:            <restructure | polish>
Type changes:    <list of files where classification changed>
Splits:          <list of files that need to be split — created? deferred?>
Code anchors:    <N verified>
Stale claims:    <N fixed>
Volume:          <total input lines> → <total output lines>
─────────────────────────────────
<per-file summary from agent>

Next steps:
  - Review changes:    git diff
  - Verify against PR: /write-doc review <filepath>
  - If splits are deferred: list the split plan for the user to approve
```
