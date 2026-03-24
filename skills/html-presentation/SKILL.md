---
name: html-presentation
description: >
  기존 HTML 발표자료를 표준 16:9 다크테마 슬라이드 덱으로 변환하는 스킬.
  입력 HTML에서 슬라이드 내용(제목, 텍스트, 구조)을 추출하고
  base-template.html의 CSS/JS 시스템으로 재구성한다. 로고를 헤더에 삽입.
  "PPT 포맷 맞춰줘", "슬라이드 변환해줘", "발표자료 포맷", "format-presentation",
  "HTML 슬라이드 변환", "템플릿에 맞춰줘", "발표 HTML 바꿔줘" 등의 요청에 트리거.
---

# HTML Presentation Skill

기존 HTML 분석 → 내용 추출 → 컴포넌트 매핑 → 표준 포맷으로 재생성.

```text
[입력 HTML] → Phase 1: 파싱    → Phase 2: 매핑          → Phase 3: 재생성        → Phase 4: 검증
              (슬라이드 추출)     (컴포넌트 선택)           (base-template 기반)      (규칙 체크)
```

---

## 핵심 규칙

1. **`base-template.html`의 CSS/JS를 그대로 사용** — 임의로 스타일 추가/수정 금지
2. **모든 슬라이드는 `.slide-dark` 클래스** — 다크 테마 통일
3. **첫 번째 슬라이드에만 `.active` 추가**
4. **모든 슬라이드에 `.slide-label` 포함** — 헤더 라벨 자동 업데이트용 (CSS로 숨겨짐)
5. **16:9 구조 유지** — `slide-deck`의 `min(100vw, 177.78vh) × min(100vh, 56.25vw)`
6. **로고는 헤더 `img.slide-header-logo`** — 공백 있는 경로는 `%20` 인코딩
7. **내용은 원본 HTML에서 그대로 가져옴** — 텍스트를 임의로 바꾸지 말 것

---

## 워크플로우

### Phase 0: 입력 수집

#### 필수 (없으면 요청)

- 입력 HTML 파일 경로 (이미 어느 정도 작성된 발표자료)
- 로고 파일 경로

#### 선택

- 출력 파일명 (기본: `{원본명}-formatted.html`)

### Phase 1: 입력 HTML 파싱

입력 파일을 Read한 뒤 각 슬라이드에서 아래 정보를 추출:

| 추출 항목 | 찾는 방법 |
| --------- | --------- |
| 슬라이드 수 | `<section>`, `<slide>`, `data-slide`, 구분 주석 등 |
| 슬라이드 제목 | `<h1>`, `<h2>`, `<h3>` 또는 제목처럼 보이는 첫 텍스트 |
| 섹션 이름 | 발표 흐름상 논리적 그룹명 (없으면 제목에서 유추) |
| 본문 내용 | 텍스트, 목록, 표, 수치, 이모지 등 |
| 발표자 정보 | 이름, 날짜, 팀 (첫 슬라이드에서 추출) |
| 로고 경로 | `$ARGUMENTS`에서 제공된 경로 사용 |

**입력 HTML이 구조화되지 않은 경우:** 내용의 논리적 흐름을 파악해서 슬라이드 경계를 직접 결정한다.

### Phase 2: 슬라이드별 컴포넌트 매핑

추출한 내용을 아래 기준으로 컴포넌트에 매핑:

| 내용 특성 | 선택 컴포넌트 |
| --------- | ------------- |
| 발표 제목 + 발표자 정보 | `title` |
| 3가지 항목 나열 | `cards-3` |
| 6가지 항목 나열 | `grid-2x3` |
| 단계별 순서 (선형) | `pipeline` |
| A → B → C 데이터 흐름 | `flow` |
| 두 요소 대비/비교 | `brain-split` |
| 핵심 숫자 강조 | `stats` |
| 항목별 상태(완료/진행/예정) | `table` |
| 시간 순서 단계 | `timeline` |
| 근/중/장기 계획 | `roadmap` |
| 4가지 차별점/강점 | `advantages` |
| 단락+박스 강조 | `section + callout` |
| 마지막 요약 | `summary` |

### Phase 3: HTML 재생성

`base-template.html`을 Read하여 CSS/JS 전체를 복사한 뒤,
각 슬라이드를 컴포넌트 카탈로그 패턴대로 재구성한다.

#### 반드시 지킬 것

- 원본의 텍스트 내용은 그대로 유지 (요약/변형 금지)
- 단, 원본이 너무 길면 슬라이드 1장에 들어갈 분량으로 자연스럽게 압축
- 이모지는 원본에 있으면 유지, 없으면 내용에 맞는 것을 추가

### Phase 4: 검증

- [ ] 모든 슬라이드에 `.slide-dark` 클래스 있음
- [ ] 첫 슬라이드에만 `.active` 있음
- [ ] 모든 슬라이드에 `.fade-up slide-label` div 있음
- [ ] 헤더 `slide-header`에 `headerLabel` span + 로고 img 있음
- [ ] `data-slide="0"` 부터 순서대로 번호 부여됨
- [ ] 원본의 모든 슬라이드 내용이 누락 없이 변환됨

---

## 컴포넌트 카탈로그

### 1. Title Slide

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
    <!-- 3개 반복 -->
  </div>
  <!-- 하단 callout (선택) -->
  <div class="fade-up" style="margin-top: 32px; padding: 20px 40px;
       background: rgba(0,102,204,0.15); border: 1px solid rgba(0,102,204,0.3);
       border-radius: 14px; max-width: 700px; text-align: center;">
    <strong style="color: var(--accent);">{{CALLOUT_LABEL}}:</strong>
    <span style="color: rgba(255,255,255,0.7);">{{CALLOUT_TEXT}}</span>
  </div>
</div>
```

**Dark variant:** `.card` → `.card.card-dark`

---

### 3. Grid 2×3 (2행 × 3열)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up content-full" style="margin-top: 16px; display: grid;
       grid-template-columns: repeat(3, 1fr); grid-template-rows: repeat(2, 1fr); gap: 14px;">
    <!-- Row 1 — --accent / --warning / --danger -->
    <div class="card" style="border-top: 3px solid var(--accent);">
      <div style="font-size: 22px; margin-bottom: 8px;">{{EMOJI}}</div>
      <div class="card-title">{{TITLE}}</div>
      <div class="card-text">{{BODY}}</div>
    </div>
    <!-- Row 2 — --primary -->
    <div class="card" style="border-top: 3px solid var(--primary);">
      <div style="font-size: 22px; margin-bottom: 8px;">{{EMOJI}}</div>
      <div class="card-title">{{TITLE}}</div>
      <div class="card-text">{{BODY}}</div>
    </div>
    <!-- 총 6개 -->
  </div>
</div>
```

---

### 4. Pipeline (단계별 파이프라인)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up pipeline" style="margin: 20px 0 36px;">
    <div class="pipeline-step pipeline-step-active">
      <div class="pipeline-step-icon">{{EMOJI}}</div>
      <div class="pipeline-step-label">{{LABEL}}</div>
      <div class="pipeline-step-sub">{{SUB}}</div>
    </div>
    <div class="pipeline-arrow">&#x25B6;</div>
    <div class="pipeline-step pipeline-step-muted">
      <!-- pipeline-step-active = 강조, pipeline-step-muted = 비활성 -->
    </div>
  </div>
</div>
```

---

### 5. Flow Diagram (데이터 흐름)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up flow-box">
    <div class="flow-node flow-node-input">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{TITLE}}</div>
      <div class="flow-node-desc">{{DESC}}</div>
    </div>
    <div class="flow-arrow">&#x27A1;</div>
    <div class="flow-node flow-node-ai">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{TITLE}}</div>
      <div class="flow-node-desc">{{DESC}}</div>
    </div>
    <div class="flow-arrow">&#x27A1;</div>
    <div class="flow-node flow-node-output">
      <div class="flow-node-icon">{{EMOJI}}</div>
      <div class="flow-node-title">{{TITLE}}</div>
      <div class="flow-node-desc">{{DESC}}</div>
    </div>
  </div>
  <!-- 하단 stats (선택) -->
  <div class="fade-up card-grid card-grid-4 content-full" style="margin-top: 16px;">
    <div style="text-align: center; padding: 16px;">
      <div class="stat-number" style="font-size: 40px;">{{NUM}}</div>
      <div class="stat-unit">{{UNIT}}</div>
      <div class="stat-label">{{LABEL}}</div>
    </div>
  </div>
</div>
```

---

### 6. Stats (핵심 수치)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up slide-title">
    <span class="highlight">{{KEY_STAT}}</span> — {{TITLE}}
  </h2>
  <div class="fade-up" style="display: flex; gap: 48px; margin: 36px 0;">
    <div style="text-align: center;">
      <div class="stat-number">{{NUMBER}}</div>
      <div class="stat-unit">{{UNIT}}</div>
      <div class="stat-label">{{LABEL}}</div>
    </div>
    <!-- 3~4개 반복 -->
  </div>
</div>
```

---

### 7. Progress Table (상태 표)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up content-full" style="margin-top: 16px;">
    <table class="progress-table">
      <thead><tr><th>{{COL1}}</th><th>{{COL2}}</th><th>{{COL3}}</th></tr></thead>
      <tbody>
        <tr>
          <td><strong>{{EMOJI}} {{ITEM}}</strong></td>
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

### 8. Timeline (타임라인)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up timeline" style="margin-top: 40px;">
    <div class="timeline-item">
      <div class="timeline-dot timeline-dot-done">&#x2713;</div>
      <!-- done=완료 / active=진행중(pulse) / future=미완 -->
      <div class="timeline-label">{{PHASE}}</div>
      <div class="timeline-sub">{{DESC}}</div>
    </div>
    <!-- 반복 -->
  </div>
  <!-- 하단 callout (선택) -->
  <div class="fade-up" style="margin-top: 48px; padding: 16px 32px;
       background: rgba(0,166,118,0.15); border-radius: 12px;
       border: 1px solid rgba(0,166,118,0.35); max-width: 600px; text-align: center;">
    <span style="font-size: 14px; color: var(--accent);">{{CALLOUT}}</span>
  </div>
</div>
```

---

### 9. Brain Split (두 요소 비교)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">{{SECTION}}</div>
  <h2 class="fade-up section-title" style="text-align: center;">{{TITLE}}</h2>
  <div class="fade-up brain-split" style="margin-top: 24px;">
    <div class="brain-box brain-box-eyes">
      <div class="brain-icon">{{EMOJI}}</div>
      <div class="brain-title">{{BOX1_TITLE}}</div>
      <div class="brain-subtitle">{{BOX1_SUB}}</div>
      <ul class="brain-list">
        <li>{{ITEM}}</li>
      </ul>
    </div>
    <div class="brain-connector">
      <div style="font-size: 11px;">{{TOP_LABEL}}</div>
      <div class="brain-connector-arrow">&#x27A1;</div>
      <div style="font-size: 11px;">{{BOTTOM_LABEL}}</div>
    </div>
    <div class="brain-box brain-box-hands">
      <!-- 동일 구조 -->
    </div>
  </div>
  <!-- 하단 설명 박스 (선택) -->
  <div class="fade-up" style="margin-top: 28px; padding: 16px 32px;
       background: rgba(255,255,255,0.06); border-radius: 12px; max-width: 700px;
       text-align: center; border: 1px solid rgba(255,255,255,0.12);">
    <span style="font-size: 14px; color: rgba(255,255,255,0.65);">{{EXPLANATION}}</span>
  </div>
</div>
```

---

### 10. Roadmap (근/중/장기)

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
      <div class="roadmap-title">{{TITLE}}</div>
      <ul class="roadmap-items"><li>{{ITEM}}</li></ul>
    </div>
    <div class="roadmap-card roadmap-long">
      <div class="roadmap-horizon">Long Term</div>
      <div class="roadmap-title">{{TITLE}}</div>
      <ul class="roadmap-items"><li>{{ITEM}}</li></ul>
    </div>
  </div>
</div>
```

---

### 11. Advantages (차별점 2×2)

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
    <!-- 02, 03, 04 반복 -->
  </div>
</div>
```

---

### 12. Summary (마지막 슬라이드)

```html
<div class="slide slide-dark" data-slide="N">
  <div class="fade-up slide-label">Summary</div>
  <h1 class="fade-up slide-title">
    {{SUMMARY_LINE}}<br>
    <span class="highlight">{{HIGHLIGHT_WORD}}</span>
  </h1>
  <div class="fade-up final-stats">
    <div class="final-stat">
      <div class="final-stat-num">{{STAT}}</div>
      <div class="final-stat-label">{{LABEL}}</div>
    </div>
    <!-- 3~4개 반복 -->
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

## 하이라이트 색상

| 클래스 | 색상 | 사용처 |
| ------ | ---- | ------ |
| `.highlight` | 초록 `#00A676` | 긍정 강조, AI, 핵심 기능 |
| `.highlight-blue` | 파랑 `#0066CC` | 기술 요소, 시스템 |
| `.highlight-warm` | 주황 `#FF6B35` | 문제점, 도전 |
| `.highlight-danger` | 빨강 `#E63946` | 위험, 경고 |

## 출력

Write 툴로 `{원본파일명}-formatted.html` 저장 후 슬라이드 목록 표 출력.
