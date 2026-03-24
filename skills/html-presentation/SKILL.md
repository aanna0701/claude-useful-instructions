---
name: html-presentation
description: >
  HTML 기반 16:9 프레젠테이션 생성 스킬.
  발표 내용(텍스트, 마크다운, 개요)을 입력받아 다크 테마 슬라이드 덱으로 변환한다.
  base-template.html의 CSS/JS 시스템을 엄격히 사용하며, 로고를 헤더에 삽입한다.
  "PPT 만들어줘", "슬라이드 만들어줘", "발표자료 만들어줘",
  "presentation 만들어줘", "HTML 슬라이드", "format-presentation",
  "발표 HTML", "슬라이드 덱" 등의 요청에 트리거.
---

# HTML Presentation Skill

입력 내용 분석 → 슬라이드 구조 설계 → 컴포넌트 선택 → HTML 생성.

```
[입력] → Phase 1: 분석 → Phase 2: 슬라이드 설계 → Phase 3: HTML 생성 → Phase 4: 검증
          (구조 파악)     (레이아웃 선택)           (base-template 기반)   (규칙 체크)
```

---

## 핵심 규칙

1. **항상 `base-template.html` 의 CSS/JS를 그대로 사용** — 스타일을 임의로 수정하지 말 것
2. **모든 슬라이드는 `.slide-dark` 클래스** — 다크 테마 통일
3. **첫 번째 슬라이드에만 `.active` 추가**
4. **모든 슬라이드에 `.slide-label` 포함** — 헤더 라벨 자동 업데이트용 (CSS로 숨겨짐)
5. **16:9 엄수** — `slide-deck`의 `min(100vw, 177.78vh) × min(100vh, 56.25vw)` 유지
6. **로고는 헤더 `img.slide-header-logo`** — 로고 파일 경로를 `src`에 지정 (공백 있으면 `%20` 인코딩)

---

## 워크플로우

### Phase 0: 입력 수집

**필수 (없으면 요청)**
- 발표 내용 (텍스트 / 마크다운 / 슬라이드 개요)
- 로고 파일 경로

**선택**
- 발표 제목, 발표자, 날짜, 팀명
- 슬라이드 수 / 특별히 강조할 섹션

### Phase 1: 구조 분석

내용을 파악하고 아래를 결정:

| 항목 | 결정 |
|------|------|
| 총 슬라이드 수 | 내용량 기반 (권장: 8~14장) |
| 섹션 분류 | 각 슬라이드의 논리적 그룹 |
| 타이틀 슬라이드 | 항상 첫 번째 (title layout) |
| 마무리 슬라이드 | 항상 마지막 (summary layout) |

### Phase 2: 슬라이드별 레이아웃 선택

아래 컴포넌트 카탈로그에서 내용에 맞는 레이아웃 선택.

**슬라이드 구조 예시:**
```
슬라이드 1  → title         발표 제목, 부제, 발표자 정보
슬라이드 2  → cards-3       주요 문제점 3가지
슬라이드 3  → pipeline      단계별 프로세스
슬라이드 4  → flow          시스템 흐름도
슬라이드 5  → cards-3(dark) 주요 데이터셋/실험 정보
슬라이드 6  → grid-2x3      6가지 세부 사항
슬라이드 7  → brain-split   두 가지 대비되는 요소
슬라이드 8  → stats         핵심 수치
슬라이드 9  → table         진행 상황 표
슬라이드 10 → timeline      단계별 타임라인
슬라이드 11 → roadmap       근/중/장기 계획
슬라이드 12 → advantages    차별점 (2×2)
슬라이드 13 → summary       최종 요약
```

### Phase 3: HTML 생성

> `base-template.html` 전체를 기반으로 생성. CSS/JS는 수정 없이 복사.

슬라이드별 HTML 패턴:

```html
<div class="slide slide-dark [active]" data-slide="N">
  <div class="fade-up slide-label">섹션 이름</div>
  [레이아웃별 컴포넌트 HTML]
</div>
```

### Phase 4: 검증

- [ ] 모든 슬라이드에 `.slide-dark` 클래스 있음
- [ ] 첫 슬라이드에만 `.active` 있음
- [ ] 모든 슬라이드에 `.slide-label` 있음
- [ ] 헤더에 `slide-header-label` + 로고 img 있음
- [ ] `data-slide="0"` 부터 순서대로 번호 부여
- [ ] 내용이 각 슬라이드의 16:9 영역에 맞게 배치됨

---

## 컴포넌트 카탈로그

### 1. Title Slide (타이틀)

```html
<div class="slide slide-dark active" data-slide="0">
  <div class="fade-up slide-label">{{SECTION_NAME}}</div>
  <h1 class="fade-up slide-title" style="font-size: 52px;">
    {{TITLE_LINE1}}<br>
    <span class="highlight">{{TITLE_HIGHLIGHT}}</span> {{TITLE_LINE2}}
  </h1>
  <p class="fade-up slide-subtitle">{{SUBTITLE}}</p>
  <div class="fade-up" style="margin-top: 48px; display: flex; gap: 32px; align-items: center;">
    <div style="text-align: center;">
      <div style="font-size: 14px; color: rgba(255,255,255,0.5);">Date</div>
      <div style="font-size: 16px; font-weight: 600; color: white; margin-top: 4px;">{{DATE}}</div>
    </div>
    <div style="width: 1px; height: 32px; background: rgba(255,255,255,0.2);"></div>
    <div style="text-align: center;">
      <div style="font-size: 14px; color: rgba(255,255,255,0.5);">Presenter</div>
      <div style="font-size: 16px; font-weight: 600; color: white; margin-top: 4px;">{{PRESENTER}}</div>
    </div>
    <div style="width: 1px; height: 32px; background: rgba(255,255,255,0.2);"></div>
    <div style="text-align: center;">
      <div style="font-size: 14px; color: rgba(255,255,255,0.5);">Team</div>
      <div style="font-size: 16px; font-weight: 600; color: white; margin-top: 4px;">{{TEAM}}</div>
    </div>
  </div>
</div>
```

---

### 2. Cards-3 (3열 카드 그리드)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up card-grid card-grid-3 content-full" style="margin-top: 20px;">
    <div class="card" style="text-align: center;">
      <div class="card-icon">{{EMOJI}}</div>
      <div class="card-title">{{CARD_TITLE}}</div>
      <div class="card-text">{{CARD_BODY}}</div>
    </div>
    <!-- repeat for 3 cards -->
  </div>
</div>
```

**Dark variant:** `.card` → `.card.card-dark` (어두운 배경에 어울리는 카드)

---

### 3. Grid 2×3 (2행 × 3열 그리드)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up content-full" style="margin-top: 16px; display: grid;
       grid-template-columns: repeat(3, 1fr); grid-template-rows: repeat(2, 1fr); gap: 14px;">
    <div class="card" style="border-top: 3px solid var(--accent);">
      <div style="font-size: 22px; margin-bottom: 8px;">{{EMOJI}}</div>
      <div class="card-title">{{TITLE}}</div>
      <div class="card-text">{{BODY}}</div>
    </div>
    <!-- repeat 6 cards; use --accent / --warning / --danger / --primary for border colors -->
  </div>
</div>
```

---

### 4. Flow Diagram (AI 파이프라인)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up flow-box">
    <div class="flow-node flow-node-input">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{NODE_TITLE}}</div>
      <div class="flow-node-desc">{{NODE_DESC}}</div>
    </div>
    <div class="flow-arrow">&#x27A1;</div>
    <div class="flow-node flow-node-ai">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{AI_TITLE}}</div>
      <div class="flow-node-desc">{{AI_DESC}}</div>
    </div>
    <div class="flow-arrow">&#x27A1;</div>
    <div class="flow-node flow-node-output">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{OUT_TITLE}}</div>
      <div class="flow-node-desc">{{OUT_DESC}}</div>
    </div>
  </div>
</div>
```

---

### 5. Stats (핵심 수치)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up slide-title">{{TITLE}}</h2>
  <div class="fade-up" style="display: flex; gap: 48px; margin: 36px 0;">
    <div style="text-align: center;">
      <div class="stat-number">{{NUMBER}}</div>
      <div class="stat-unit">{{UNIT}}</div>
      <div class="stat-label">{{LABEL}}</div>
    </div>
    <!-- repeat for each stat -->
  </div>
</div>
```

---

### 6. Progress Table (진행 상황 표)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up content-full" style="margin-top: 16px;">
    <table class="progress-table">
      <thead><tr><th>Component</th><th>Status</th><th>Description</th></tr></thead>
      <tbody>
        <tr>
          <td><strong>{{EMOJI}} {{COMPONENT}}</strong></td>
          <td><span class="badge badge-done">Complete</span></td>
          <!-- badge-done / badge-progress / badge-next -->
          <td>{{DESCRIPTION}}</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

---

### 7. Timeline (단계별 타임라인)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up timeline" style="margin-top: 40px;">
    <div class="timeline-item">
      <div class="timeline-dot timeline-dot-done">&#x2713;</div>
      <!-- timeline-dot-done / timeline-dot-active / timeline-dot-future -->
      <div class="timeline-label">{{PHASE}}</div>
      <div class="timeline-sub">{{DESC}}</div>
    </div>
    <!-- repeat for each phase -->
  </div>
</div>
```

---

### 8. Brain Split (두 요소 비교)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up brain-split" style="margin-top: 24px;">
    <div class="brain-box brain-box-eyes">
      <div class="brain-icon">{{EMOJI}}</div>
      <div class="brain-title">{{BOX1_TITLE}}</div>
      <div class="brain-subtitle">{{BOX1_SUBTITLE}}</div>
      <ul class="brain-list">
        <li>{{ITEM}}</li>
      </ul>
    </div>
    <div class="brain-connector">
      <div style="font-size: 11px;">{{CONNECTOR_TOP}}</div>
      <div class="brain-connector-arrow">&#x27A1;</div>
      <div style="font-size: 11px;">{{CONNECTOR_BOTTOM}}</div>
    </div>
    <div class="brain-box brain-box-hands">
      <!-- same structure as box1 -->
    </div>
  </div>
</div>
```

---

### 9. Roadmap (근/중/장기 계획)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up roadmap-row" style="margin-top: 28px;">
    <div class="roadmap-card roadmap-near">
      <div class="roadmap-horizon">Near Term</div>
      <div class="roadmap-title">{{TITLE}}</div>
      <ul class="roadmap-items"><li>{{ITEM}}</li></ul>
    </div>
    <div class="roadmap-card roadmap-mid">
      <div class="roadmap-horizon">Medium Term</div>
      <!-- same structure -->
    </div>
    <div class="roadmap-card roadmap-long">
      <div class="roadmap-horizon">Long Term</div>
      <!-- same structure -->
    </div>
  </div>
</div>
```

---

### 10. Advantages (차별점 2×2)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up card-grid card-grid-2 content-full" style="margin-top: 20px;">
    <div class="advantage-card">
      <div class="advantage-num">01</div>
      <div>
        <div class="advantage-title">{{TITLE}}</div>
        <div class="advantage-desc">{{DESC}}</div>
      </div>
    </div>
    <!-- repeat with 02, 03, 04 -->
  </div>
</div>
```

---

### 11. Pipeline (단계별 파이프라인)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up pipeline" style="margin: 20px 0;">
    <div class="pipeline-step pipeline-step-active">
      <div class="pipeline-step-icon">{{EMOJI}}</div>
      <div class="pipeline-step-label">{{LABEL}}</div>
      <div class="pipeline-step-sub">{{SUB}}</div>
    </div>
    <div class="pipeline-arrow">&#x25B6;</div>
    <div class="pipeline-step pipeline-step-muted">
      <!-- same structure; active = highlighted, muted = greyed out -->
    </div>
  </div>
</div>
```

---

### 12. Summary Slide (마지막 슬라이드)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">Summary</div>
  <h1 class="fade-up slide-title">
    {{SUMMARY_TITLE}}<br>
    <span class="highlight">{{HIGHLIGHT_WORD}}</span>
  </h1>
  <div class="fade-up final-stats">
    <div class="final-stat">
      <div class="final-stat-num">{{STAT}}</div>
      <div class="final-stat-label">{{LABEL}}</div>
    </div>
    <!-- repeat 3-4 stats -->
  </div>
  <div class="fade-up" style="margin-top: 24px; max-width: 600px; text-align: center;">
    <p style="font-size: 18px; color: rgba(255,255,255,0.7); line-height: 1.7;">
      {{CLOSING_TEXT}}
    </p>
  </div>
  <div class="fade-up" style="margin-top: 40px; font-size: 28px; font-weight: 300; color: rgba(255,255,255,0.4);">
    Thank You
  </div>
</div>
```

---

## 하이라이트 색상 선택

| 클래스 | 색상 | 사용처 |
|--------|------|--------|
| `.highlight` | 초록 `#00A676` | 긍정적 강조, AI, 핵심 기능 |
| `.highlight-blue` | 파랑 `#0066CC` | 기술적 요소, 시스템 |
| `.highlight-warm` | 주황 `#FF6B35` | 문제점, 도전 과제 |
| `.highlight-danger` | 빨강 `#E63946` | 위험, 경고, 임팩트 |

## 출력 형식

완성된 HTML 파일을 바로 제공. 파일명은 `{발표주제}-presentation.html` 형식으로 저장.
