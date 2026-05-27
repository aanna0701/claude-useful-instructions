---
name: article-writing
description: >
  Write articles, technical guides, blog posts, tutorials, newsletter issues, and
  other long-form content that sounds like an actual person with a point of view —
  structured enough to scan, prose-driven enough to trust. Use when the user wants
  polished long-form content where voice consistency, scan-friendly structure, and
  credibility all matter at once. Especially for engineering- or robotics-flavored
  pieces that mix narrative with diagrams, tables, and code.
  Triggers on: "write an article", "blog post", "tutorial", "guide", "newsletter",
  "essay", "launch post", "long-form", "technical write-up", "포스트 써줘",
  "글 써줘", "아티클", "튜토리얼".
origin: claude-useful-instructions
---

# Article Writing

Write long-form content that sounds like an actual person with a point of view, not an LLM smoothing itself into paste. The goal is not "well-formatted output" and not "essay-only prose" — it is content a reader can both **scan** and **trust**.

This skill governs how you choose structure (headings, tables, diagrams, code) versus prose, so the piece never collapses into either of the two common failure modes:

- prose-only essays that are hard to scan
- table- and diagram-heavy pages that never explain what the reader is supposed to understand

Use structure for navigation. Use prose for understanding.

## 🧭 When to Activate

- drafting blog posts, essays, launch posts, technical guides, tutorials, or newsletter issues
- turning notes, transcripts, or research into polished articles
- matching an existing founder, operator, or brand voice from examples
- tightening structure, pacing, and evidence in already-written long-form copy
- writing engineering/robotics/VLA pieces that mix narrative with concrete artifacts

Not for: short replies, single-paragraph answers, formal API references, or runbooks. For those, defer to `diataxis-doc-system` or the relevant reference skill.

## 🎯 Core Principle: Reader Flow First

Before choosing a format for a section, identify what the reader needs from it.

| Reader need | Best format |
| --- | --- |
| Motivation, tradeoff, subtle behavior, mental model | short prose paragraphs |
| Lookup, comparison, fixed contract | table |
| Structure, data flow, control flow, sequence | diagram |
| Compact grouped facts or stepwise procedure | bulleted list |
| Implementation contract, shapes, masking, decoding | short code snippet |

The table above is a lookup, not a rule. The rule is upstream of it: pick the format that serves the reader's question in that section. Do not default to tables or diagrams just because the content is technical.

## ✍️ Core Writing Rules

1. Lead with the concrete thing: artifact, example, output, anecdote, number, screenshot, diagram, or code.
2. Explain after the example, not before.
3. Keep sentences tight unless the source voice is intentionally expansive.
4. Use proof instead of adjectives.
5. Never invent facts, credibility, customer evidence, benchmarks, or quotes.
6. Every section must add something new — no recap-only sections.

## 🗣️ Voice Handling

If the user supplies a voice target (founder, brand, prior pieces), run the `brand-voice` skill first and reuse its `VOICE PROFILE`. Do not repeat a second style-analysis pass here unless the user explicitly asks for one.

If no voice references are given, default to a sharp operator voice: concrete, unsentimental, useful. Engineering-flavored pieces lean further toward plain language and verifiable claims.

## 🧱 Format Rules

These rules apply *inside* sections, after the outline decision is made.

### 1. Prose for Understanding

Use short prose paragraphs (1–3 sentences) when the reader needs interpretation, not just structure. Especially for:

- motivation and design intent
- causal flow
- tradeoffs and assumptions
- nuanced rule behavior
- generated labels, model outputs, or state semantics
- common misunderstandings
- canonical interpretations

Use prose **before** a table or diagram when the reader needs orientation. Use prose **after** when the artifact needs interpretation. A table that no paragraph introduces or interprets is usually a sign the section is doing lookup work the reader did not ask for yet.

### 2. Tables for Lookup and Comparison

Reach for a table when the reader needs to compare, scan, or reference quickly: metadata, component responsibilities, I/O contracts, config surfaces, failure modes, decision summaries, open questions.

Avoid tables when teaching a concept, narrating runtime flow, or explaining subtle behavior. If a row needs a long sentence to be understandable, the table is too dense — keep the table tight and move the explanation into a short prose subsection with an example.

### 3. Diagrams for Structure and Flow

Use diagrams to clarify system context, module boundaries, data flow, control flow, runtime sequence, ownership boundaries, deployment topology, or failure propagation.

After any non-obvious diagram, add a one- or two-sentence interpretation that names the implication. A diagram without interpretation forces the reader to guess what point you wanted them to take from it.

### 4. Code Snippets for Implementation-Heavy Sections

When the article explains implementation details — model architecture, tensor shapes, loss functions, label masking, dataloader contracts, training loops, inference boundaries, control semantics — include short, contract-focused code snippets.

Use this rhythm:

1. prose explaining the implementation intent
2. code snippet showing the mechanics (function boundary, input/output shapes, the key step)
3. one short prose sentence on the implication or contract

Snippets should be runnable in spirit, not pasted files. Strip imports and boilerplate unless they carry meaning.

### 5. Avoid Table Soup

Do not stack three or more tables back-to-back. Either insert prose that explains how they relate, or convert one into narrative. Preferred section rhythm:

1. 1–3 sentence orientation
2. table, diagram, or bullet list for precise structure
3. 1–2 sentence interpretation or concrete example

## 🧩 Examples and Contracts

Prefer concrete examples whenever the topic is abstract — labeling rules, runtime workflows, model behavior, data pipelines, prompt contracts, robotics/VLA systems, safety or operational boundaries.

**Example pattern — explaining a contract between two surfaces:**

> The rule caption is the clinical anchor. It decides anatomy, action, and operator intent from deterministic inputs. The LLM caption exists only to make that same fact appear in more natural language.
>
> | Surface | Owner | May change meaning? |
> | --- | --- | --- |
> | Rule caption | RuleBasedTextLabeler | Yes, by code rule changes only |
> | LLM caption | LLMTextWriter | No |
>
> The prose fixes the mental model; the table fixes the exact contract. Neither stands alone.

This shape — orient, fix, interpret — is the default rhythm for any contract-style passage in a technical article.

## 🚫 Banned Patterns

Delete and rewrite any of these on sight:

- "In today's rapidly evolving landscape"
- "game-changer", "cutting-edge", "revolutionary", "seamless", "leverage" (as a verb)
- "here's why this matters" as a standalone bridge
- fake vulnerability arcs ("I used to think… then everything changed")
- a closing question added only to juice engagement
- biography padding that does not move the argument
- generic AI throat-clearing that delays the point
- decorative emoji sprinkled into body text
- a closing recap that just restates the section headings

## 🔄 Writing Process

1. **Clarify** audience, purpose, and the one thing the reader should leave with.
2. **Outline** with one job per section. Name the format each section needs (prose / table / diagram / code) before writing.
3. **Draft sections** starting with proof, artifact, conflict, or example.
4. **Expand only** where the next sentence earns space.
5. **Cut** anything templated, overexplained, or self-congratulatory.
6. **Run the quality gate** below before delivering.

## 🧭 Structure Guidance by Genre

### Technical Guides and Tutorials

- open with what the reader gets (artifact, capability, or working command)
- one runnable thing per major section: code, command, screenshot, or concrete output
- mix prose and snippets — never paste a wall of code without naming the contract first
- end with actionable takeaways, not a soft recap

### Essays and Opinion Pieces

- start with tension, contradiction, or a specific observation
- one argument thread per section
- opinions answer to evidence; if there is no evidence, name it as a hypothesis
- avoid tables and diagrams unless they replace at least a paragraph of explanation

### Newsletters

- the first screen does real work — no diary filler
- section labels only when they improve scanability
- bullets are fine for roundups, but each bullet must carry a verb and a specific noun

### Engineering / Robotics / VLA Write-ups

- show the artifact early: a diagram of the data flow, a tensor shape, a labeled frame
- prose explains intent, code/tables fix the contract, diagram fixes the structure
- name assumptions explicitly (frame rate, coordinate convention, label policy)
- separate "what is decided" from "what is still open" — never blur the two

## 🎨 Emoji Use

Use one clear emoji on major section headings when the piece is long enough that scanning helps. Keep emoji meaning consistent across the page. A small consistent set:

- 🧭 overview / orientation
- 🏗️ architecture
- 🧩 components or contracts
- 🔄 runtime flow / process
- 🔌 interfaces
- ⚠️ risks
- ✅ follow-ups or completion

Do not use emoji as decoration, as a substitute for precise heading text, or inside dense contracts where they add visual noise.

## ✅ Quality Gate

Before delivering, confirm each item:

- [ ] every factual claim is backed by a provided source or clearly labeled as the author's view
- [ ] no banned patterns or generic AI transitions remain
- [ ] voice matches the supplied examples or the agreed `VOICE PROFILE`
- [ ] every section adds something new
- [ ] no section is pure table soup or pure prose where the other would serve better
- [ ] diagrams are interpreted, tables are introduced, code snippets are framed
- [ ] formatting matches the intended medium (blog, newsletter, internal doc, etc.)
- [ ] headings are consistent depth and do not skip levels

If any item fails, fix it before delivery — not in a follow-up pass after the user complains.
