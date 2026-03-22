# Document Type Definitions

Each document type has its own structure rules, NLM prompt template, and reviewer weight adjustments.

---

## 1. cover-letter (자소서 / 자기소개서)

### Structure: 기승전결

- **기 (Intro)**: Hook — serves as an umbrella for all experiences that follow.
  Self-check: "Does this intro naturally lead into all the experiences?"
- **승 (Development)**: Experience sections — max 3 subheadings (3-5 words each), each a chapter in the story. Not a list.
- **전 (Turn)**: Pivot — the insight/realization that ties experiences together.
- **결 (Conclusion)**: Synthesizes all experiences and connects to this company/role. Must NOT just summarize the last experience.
- **기/결 coherence**: Read 기 and 결 alone — they must form a coherent pair.

### Competency Framing (Required)

Every project mention must follow:
1. **Fact/result**: "Optimized response time to 200ms under 500K daily traffic"
2. **Proven competency**: "Performance optimization in large-scale traffic environments"
3. **Job contribution**: "Can contribute immediately to [specific challenge] at your company"

### NLM Prompt Template

```
다음 자소서 항목에 대해 경력 기술서와 인사관점 에세이를 바탕으로 초안을 작성해줘.

[자소서 항목]: {item}
[지원 직무]: {role}
[강조 포인트]: {emphasis}
[글자수 제한]: {limit}자 (공백 포함)

기승전결 구조로 작성하되, 구체적인 수치와 성과를 포함해줘.
경력직 톤으로, 과장 없이 차분한 자신감으로 써줘.
```

### Reviewer Weights

All 6 dimensions equally weighted. Structure dimension specifically checks 기승전결.

---

## 2. career-desc (경력기술서)

### Structure: Chronological per-company

```markdown
### [Company] — [Title] (YYYY.MM ~ YYYY.MM)
[Role scope in 2-3 sentences — what chapter this company represents in the growth narrative]

**주요 프로젝트 및 성과:**
- [Project name]: [specific contribution] → [quantified outcome]

**핵심 역량:** [keywords]
```

### Design Principles

- **Growth narrative**: Define a single-line career trajectory (e.g., "Domain expert → System architect → Organization leader"). Each company is a chapter.
- **Differentiation point**: What distinguishes this candidate from others with similar careers? Weave throughout.
- Factual, data-driven, specific to personal contribution, no exaggeration.

### NLM Prompt Template

```
경력 기술서를 작성해줘. 업로드된 이력서와 프로젝트 자료를 바탕으로,
회사별/시간순으로 정리하되 각 회사에서의 역할 범위, 주요 프로젝트, 정량적 성과를 포함해줘.

[지원 직무]: {role}
[강조 포인트]: {emphasis}

성장 서사를 중심으로, 각 회사가 커리어의 어떤 장(chapter)인지 드러나게 써줘.
```

### Reviewer Weights

- Structure & Storyline: higher weight (growth narrative coherence)
- Character Count: lower weight (often no strict limit)

---

## 3. portfolio (포트폴리오)

### Structure: Per-project

```markdown
### [Project Name]
**기간:** YYYY.MM ~ YYYY.MM | **팀 규모:** N명 | **역할:** [role]

**Challenge:** [What problem needed solving]
**Solution:** [What you built/designed/led — specific technical decisions]
**Impact:** [Quantified outcomes — metrics, business impact]
**Tech Stack:** [technologies used]
```

### Design Principles

- **Visual scanability**: Readers skim. Use consistent structure, bold labels, concise bullets.
- **Challenge → Solution → Impact**: Every project follows this arc.
- Select 3-5 strongest projects, not an exhaustive list.
- Show decision-making: "Chose X over Y because Z" demonstrates engineering judgment.

### NLM Prompt Template

```
포트폴리오를 정리해줘. 업로드된 프로젝트 자료를 바탕으로,
프로젝트별로 Challenge → Solution → Impact 구조로 작성해줘.

[지원 직무]: {role}
[선별 기준]: {emphasis}

가장 임팩트가 큰 3-5개 프로젝트를 선별하고,
기술적 의사결정 과정이 드러나게 써줘.
```

### Reviewer Weights

- Structure & Storyline: higher weight (per-project arc consistency)
- Terminology & Tone: higher weight (technical credibility)
- Character Count: often not applicable

---

## 4. cover-letter-en (커버레터 — English)

### Structure: Hook → Value Prop → Fit → Close

- **Hook (1-2 sentences)**: Why this company, why now. Specific — not "I'm excited about your mission."
- **Value Proposition (2-3 paragraphs)**: Top 2-3 achievements mapped to JD requirements.
  Each: [What you did] → [Measurable result] → [Why this matters for this role].
- **Fit (1 paragraph)**: Why you + this company specifically. Show you've researched them.
- **Close (2-3 sentences)**: Confident, not needy. No "I would be honored." End with forward momentum.

### Design Principles

- Max 400 words (one page).
- Active voice, concrete numbers, no buzzwords.
- Every sentence earns its place — if it doesn't add new information, cut it.

### NLM Prompt Template

```
Write a cover letter in English based on my career documents.

[Position]: {role} at {company}
[Key JD Requirements]: {emphasis}
[Word Limit]: ~400 words

Structure: Hook → Value Proposition → Company Fit → Close.
Use specific metrics and achievements. Professional but not stiff.
```

### Reviewer Weights

- Sentence Grammar: evaluated for English grammar, not Korean
- Terminology & Tone: higher weight (English professional register)

---

## 5. hr-essay (인사관점 에세이)

### Structure: Claim → Case → Insight

Each soft-skill topic follows:
1. **Claim**: State the competency (1 sentence)
2. **Case**: Concrete example with context, action, result (3-5 sentences)
3. **Insight**: What this reveals about your work style (1-2 sentences)

### Topics to Cover

Collaboration, leadership/mentoring, communication, problem-solving approach, organizational contribution.

### Design Principles

- 800-1500 characters.
- All claims backed by concrete examples. No empty character descriptions ("성실합니다" without evidence).
- Show, don't tell. The case IS the proof.

### NLM Prompt Template

```
인사관점 에세이를 작성해줘. 경력 기술서와 프로젝트 자료를 바탕으로,
협업, 리더십, 커뮤니케이션, 문제해결 역량을 구체적 사례와 함께 써줘.

[지원 직무]: {role}
[글자수 제한]: {limit}자 (공백 포함)

각 역량마다 [주장 → 구체적 사례 → 인사이트] 구조로 작성해줘.
빈 수식어 없이, 사례가 곧 증거가 되도록 써줘.
```

### Reviewer Weights

- Fact & Fit: higher weight (cases must be verifiable against context)
- Structure & Storyline: evaluated for claim→case→insight pattern
