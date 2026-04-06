# Writing Rules for Slide Content

This document defines content generation rules for each slide type.
Read this before generating any slide content.

## General Style Rules

### Language

- "~한다" over "~할 수 있다"
- "reduces" over "can potentially reduce"
- No hedging: remove "might", "could", "perhaps", "it is believed that"
- No filler: remove "very", "highly", "significantly", "greatly", "extremely"
  - Instead, use specific metrics: "3x faster", "40% reduction", "sub-10ms latency"

### Structure

- Phrases over sentences — presentation slides are not essays
- One claim per bullet
- Consistent terminology — same concept = same word everywhere
  - Pick one: latency / throughput / robustness / calibration / deployment
  - Never swap synonyms slide-to-slide ("처리 속도" on slide 3, "연산 시간" on slide 5)
- Parallel grammar in lists — if bullet 1 starts with a verb, all bullets start with verbs

### Compression Examples

| Before | After |
|--------|-------|
| 본 시스템은 복잡한 환경에서도 안정적인 처리를 보장하기 위해 다양한 예외 상황을 고려하여 설계되었다. | 예외 상황 포함한 안정성 중심 설계 |
| This system provides a very efficient and flexible architecture that can handle diverse scenarios. | Modular architecture for multi-environment deployment |
| 굉장히 유연하고 효율적인 구조를 통해 여러 환경에 잘 대응할 수 있습니다. | 다중 환경 대응 모듈형 구조 |
| The proposed method significantly outperforms baseline approaches in terms of both accuracy and speed. | +12% accuracy, 2.3x throughput vs. baseline |

---

## Bullet Slides

### Rules

- 3–5 main bullets (level 1) per slide maximum
- Each bullet: 1 line preferred, 2 lines maximum
- No connecting words between bullets ("또한", "그리고", "Furthermore", "Additionally")
- Concrete nouns over abstract ones
- Action verbs: "reduces", "enables", "eliminates", "integrates", "replaces"
- Remove unnecessary modifiers

### Bullet Hierarchy (follow template lstStyle)

Typical 4-level hierarchy:

| Level | Purpose | Style | Example |
|-------|---------|-------|---------|
| 0 | Section header | Bold, largest | "System Architecture" |
| 1 | Main point | Bold, medium | "Decoupled encoder-decoder pipeline" |
| 2 | Supporting detail | Normal, smaller | "Reduces cross-stage dependency by 60%" |
| 3 | Sub-detail / example | Normal, smallest | "└ Verified on 3 production environments" |

### Anti-patterns

**Bad:**
```
• 이 시스템은 전반적으로 매우 효율적이고 유연한 구조를 바탕으로
  다양한 상황에 대응할 수 있도록 설계되었습니다.
• 또한 확장성이 뛰어나며 다양한 모듈을 추가할 수 있습니다.
• 그리고 기존 시스템과의 호환성도 우수합니다.
```

**Good:**
```
§ System Design Principles
  • Modular pipeline for diverse deployment
  • Horizontal scaling via plug-in modules
  • Backward-compatible with legacy systems
```

---

## Table Content

### Rules

- One key point per cell
- Phrases, not sentences
- Standardize numbers: units, decimal places, abbreviations
- Row/column meaning must be consistent and obvious
- Comparison tables: fix axes clearly (rows = methods, columns = metrics)

### Example

| Method | Strength | Limitation |
|--------|----------|------------|
| Rule-based | Interpretable | Low scalability |
| End-to-end | Simple pipeline | Lower controllability |
| Hybrid | Balanced trade-off | Complex tuning |

### Anti-patterns

- Cells with 3+ lines of text
- Mixing units in the same column (ms vs s vs min)
- Headers that don't clearly describe the column content

---

## Figure Captions

### Rules

- Caption = interpretation point, not description
- 1–2 sentences maximum
- Focus on: what axis shows, what trend means, key takeaway
- Avoid "Figure shows…" or "As can be seen…"

### Examples

| Bad | Good |
|-----|------|
| Figure 3 shows the relationship between latency and throughput under various conditions. | Latency decreases linearly as stage coupling is reduced. |
| This graph demonstrates that our method performs better than the baseline. | +15% F1 vs. baseline across all test splits. |
| 그래프에서 볼 수 있듯이 성능이 향상되었다. | 처리량 2.3배 향상, 지연시간 40% 감소 |

---

## Diagram Labels

When the template contains diagrams (flowcharts, architecture diagrams, process flows):

### Rules

- **Never change diagram structure** — same number of boxes, arrows, layers
- Only replace label text inside existing shapes
- Each node label: ≤ 15 characters (Korean) or ≤ 20 characters (English)
- Relationships expressed as verb phrases: "전달", "변환", "집계", "validates", "routes to"
- Parallel stages must have parallel grammar

### Example

```
입력 → 인코더 → 융합 → 디코더 → 출력
센서 입력 → 상태 추정 → 경로 계획 → 제어 명령
```

### Anti-patterns

- Changing the number of nodes
- Labels longer than the box width
- Inconsistent verb forms across parallel nodes

---

## Cover Slide Content

Cover slides typically have minimal editable content:
- Presentation title or subtitle
- Presenter name and date
- Do NOT modify: company logo, tagline, background, decorative elements

Format presenter info exactly as the template placeholder shows.
Example: `{Name} | {Date}` → `홍길동 | 2025.06.15`

---

## Speaker Notes

Use speaker notes for content that doesn't fit on slides:
- Detailed explanations
- Data sources and references
- Transition phrases ("다음 슬라이드에서는...")
- Backup details for Q&A

Speaker notes have no formatting constraints — write in full sentences here.
