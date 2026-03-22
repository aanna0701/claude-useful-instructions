# 6-Step Refinement Checklist

Apply each step sequentially. Each step produces a revised version that feeds into the next.
These steps are **shared across all document types**. Type-specific structure rules are in `doc-types.md`.

---

## Step 1: Sentence Grammar (비문 체크)

Check every sentence individually:

- **Subject-predicate agreement**: Does the subject match the predicate? ("주어-서술어 호응")
- **Particle correctness**: Are particles (은/는, 이/가, 을/를, 에/에서) used correctly?
- **Modifier placement**: Are modifiers adjacent to what they modify? No dangling modifiers.
- **Incomplete sentences**: Every sentence must have a complete predicate. No sentence fragments.
- **Honorific consistency**: Maintain consistent speech level throughout (합니다체 for Korean docs).
- **Spelling & spacing**: Korean spacing rules (띄어쓰기), common misspellings.
- **English docs**: grammar, punctuation, tense consistency, article usage.

**Action**: Fix each issue inline. Do not flag — fix directly.

---

## Step 2: Inter-Sentence Flow (문장 간 흐름)

Check transitions between consecutive sentences:

- **Logical continuity**: Does sentence B follow naturally from sentence A?
- **Conjunction overuse**: Avoid starting consecutive sentences with 그리고/또한/이에/이를 통해.
  Replace with implicit connections or restructure.
- **Topic jumps**: If the topic shifts abruptly, add a bridging phrase or reorder.
- **Repetitive openings**: Vary sentence beginnings. No "저는~" appearing more than twice per paragraph.
- **Cause-effect clarity**: When describing results, ensure the causal chain is explicit.
- **English docs**: Avoid "Additionally/Furthermore/Moreover" chains. Vary transitions.

**Action**: Rewrite transitions. Merge or split sentences as needed.

---

## Step 3: Paragraph Structure (문단 구조)

Evaluate based on the **document type's structure rules** (see `doc-types.md`).

Common checks across all types:
- **Topic sentence**: Each paragraph opens with its main point.
- **Evidence chain**: Every claim follows [Specific result] → [Demonstrated competency] → [Value to reader].
- **Paragraph cohesion**: No paragraph tries to cover more than one main idea.
- **Logical ordering**: Paragraphs progress in a logical sequence (chronological, importance, narrative arc).

Type-specific checks:
- `cover-letter`: 기승전결, 기/결 coherence, max 3 subheadings
- `career-desc`: Per-company chapters, chronological flow, role scope clarity
- `portfolio`: Per-project structure (challenge → solution → impact), visual scanability
- `cover-letter-en`: Hook → Value Proposition → Fit → Close
- `hr-essay`: Claim → Case evidence → Insight pattern

**Action**: Restructure paragraphs. Move sentences between paragraphs if needed.

---

## Step 4: Terminology Simplification (용어 일반화)

Adjust vocabulary for the target audience (hiring manager, not domain expert):

- **Internal jargon**: Replace company-internal terms with industry-standard equivalents.
  - e.g., "사내 ATLAS 시스템" → "사내 통합 모니터링 시스템"
- **Overly technical terms**: If a term requires domain expertise to understand,
  either explain it briefly in context or replace with a general equivalent.
  - e.g., "gRPC 기반 서비스 메시 아키텍처" → "마이크로서비스 간 통신 아키텍처 (gRPC 기반)"
- **Abbreviations**: Spell out on first use unless universally known (API, DB, etc.).
- **Preserve precision**: Do NOT remove technical terms that demonstrate expertise.
  The goal is accessibility, not dumbing down. Keep terms that signal competency
  but ensure they're understandable in context.

**Action**: Replace or contextualize terms. Preserve technical credibility.

---

## Step 5: Tone Adjustment (톤 조정)

Target: readable, professional, not stiff. "A senior professional explaining their work to a peer."

- **Stiff patterns to soften** (Korean):
  - "~하였습니다" → "~했습니다" (where natural)
  - Overly formal constructions → conversational-professional hybrid
  - Long compound sentences → break into two shorter ones
- **Patterns to eliminate**:
  - "저는~" starting every paragraph
  - "다양한", "많은" as filler — replace with specifics
  - "이를 통해 배웠습니다" ending pattern
  - Exaggeration: "혁신적인", "폭발적인", "탁월한", "최고의"
  - Overdrama: "그 순간 깨달았습니다", "피와 땀으로", "DNA에 새겨진"
  - Entry-level tone: "열심히 하겠습니다", "배우고 싶습니다"
- **English docs**: Avoid buzzword chains ("leveraged synergies to drive innovation").
  Prefer concrete language. Active voice over passive.
- **Rhythm**: Alternate sentence lengths. Mix short punchy sentences with longer explanatory ones.
- **Confidence**: Show, don't declare. Let results speak — avoid "I am confident that..."

**Action**: Rewrite for tone. Preserve meaning and structure from previous steps.

---

## Step 6: Character Count (글자수 체크)

- Count **including spaces and line breaks**.
- Target: **95-100%** of the character limit.
- **Zero tolerance** for exceeding by even 1 character.
- Under 80% = wasted space — expand with more detail or examples.
- If over limit: trim lowest-value sentences first. Never cut competency chains.
- If no character limit specified (e.g., portfolio): skip this step.
- Output: `글자수: [N]자 / [limit]자 (공백 포함)`

**Action**: Trim or expand. Re-verify count after every edit.
