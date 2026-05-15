---
name: diagram-architect
description: >
  수기 SVG 기반 아키텍처 다이어그램 설계 스킬.
  복잡한 시스템을 C4 모델 계층(Context/Container/Component)으로 분해하고,
  도형 내 텍스트 최소화 + 번호 매기기 + 범례로 깔끔한 다이어그램을 생성한다.
  모든 다이어그램은 직각 라우팅 기반 수기 SVG로 출력한다. Mermaid는 사용하지 않는다.
  "다이어그램 그려줘", "아키텍처 도식화", "시스템 구조도", "mermaid 다이어그램",
  "flowchart 그려줘", "sequence diagram", "구조 시각화", "diagram",
  "시스템 설계 그림", "데이터 흐름도", "컴포넌트 다이어그램",
  "ERD 그려줘", "클래스 다이어그램" 등의 요청에 트리거.
  시스템 설계, 아키텍처 논의, 구조 설명에서 시각화가 도움이 될 때도 이 스킬을 사용할 것.
---

# Diagram Architect

사용자의 시스템/구조를 분석 → 적절한 계층과 다이어그램 타입 결정 → Mermaid 코드 생성.

```
[입력] → Phase 1: 분석 → Phase 2: 분해 → Phase 3: 생성 → Phase 4: 검증
          (구조 파악)     (계층/뷰 분리)   (Mermaid 코드)   (체크리스트)
```

---

## 핵심 원칙

> 상세 규칙:
> - 공통 (C4/레이아웃/색상/번호/범례): `references/diagram-rules.md` — Phase 3 실행 전 반드시 읽을 것. Mermaid 문법 섹션은 무시.
> - SVG 전용 (직각 라우팅, 채널, 겹침 방지, 반응형 폭): `references/svg-rules.md` — **모든 다이어그램에 필수**.

Apply the 5 core principles from diagram-rules.md: C4 layering, line semantics, abstraction levels, color consistency, text minimization. All diagrams are emitted as hand-authored SVG with orthogonal routing only, reserved channel lanes between subgraphs, zero overlap between edges and unrelated boxes / titles, and a `max-width` CSS cap for responsive embedding.

---

## 워크플로우

### Phase 0: 입력 수집

**필수 (없으면 요청)**
- 시스템/구조의 개요 (무엇을 시각화할 것인가)
- 대상 청중 (개발자? 경영진? 신입?)
- 목적 (설계 문서? 발표? 코드 리뷰?)

**선택 (있으면 더 좋은 결과)**
- 기존 코드베이스 또는 문서
- 이미 그린 다이어그램
- 강조하고 싶은 부분

### Phase 1: 분석

시스템을 파악하고 아래를 결정:

| 판단 항목 | 결과 |
|-----------|------|
| 시스템 복잡도 | 단순(도형 ≤10) / 중간(11-15) / 복잡(16+) |
| 적합한 C4 레벨 | L1 Context / L2 Container / L3 Component |
| 다이어그램 타입 | flowchart / sequence / class / ER / state / C4 |
| 분할 필요 여부 | 단일 / 2-3장 분할 / 계층별 분할 |

**도형 15개 초과 → 반드시 분할.** 예외 없음.

### Phase 2: 분해

복잡한 시스템은 아래 전략으로 분해:

**전략 A — C4 계층 분리:**
- L1: 외부 시스템/사용자와의 관계만 (5개 이내)
- L2: 내부 컨테이너 구성 (서버, DB, 큐 등)
- L3: 특정 컨테이너 내부 컴포넌트

**전략 B — 관점(View) 분리:**
- 데이터 흐름도 vs 배포 구조도 vs 시퀀스 다이어그램
- 같은 시스템이라도 관점마다 별도 다이어그램

**전략 C — 영역(Domain) 분리:**
- MSA면 도메인별로 분리
- 각 다이어그램은 하나의 bounded context만

각 다이어그램에 제목 + 설명 한 줄 부여.

### Phase 3: 생성

**`diagram-writer` 에이전트에게 위임한다.**

> Phase 3 실행 전 반드시 `references/diagram-rules.md`와 `references/svg-rules.md`를 Read할 것.

각 다이어그램마다:
1. SVG 파일 생성 (수기 SVG, 직각 라우팅, 채널 기반 엣지) — `public/diagrams/<name>.svg` 등 정적 자산 경로에 저장
2. SVG 내부에 범례 그룹 임베드
3. Markdown에서는 `![](/diagrams/<name>.svg)` 이미지 링크로 참조
4. 반응형 폭 CSS (`img[src*="/diagrams/"] { max-width: min(100%, 56rem); }`) 적용 여부 확인 — 없으면 추가
5. 번호별 설명 텍스트 작성

### Phase 4: 검증

> 체크리스트: `references/checklist.md` 참조.

모든 다이어그램에 대해 체크리스트 실행.
위반 항목이 있으면 Phase 3로 돌아가 수정.

---

## 부분 실행

| 요청 | 실행 범위 |
|------|-----------|
| "다이어그램 그려줘" | Phase 0→4 전체 |
| "이 구조 분석만 해줘" | Phase 1만 |
| "이 다이어그램 검토해줘" | Phase 4만 (사용자 다이어그램에 체크리스트 적용) |
| "더 단순하게 쪼개줘" | Phase 2→3 재실행 |

---

## 출력 형식

각 다이어그램은 아래 구조로 출력:

```markdown
## [다이어그램 제목] (L[N] [타입])

[한 줄 설명]

![제목](/diagrams/<name>.svg)

### 흐름 설명
1. [번호] — [설명]
2. [번호] — [설명]
```

범례는 SVG 파일 내부에 그룹으로 임베드한다 (별도 표 작성 금지). 여러 장이면 전체 목차를 먼저 출력하고 각 다이어그램을 순서대로 제시. SVG 파일 저장 경로와 (필요 시) 추가한 CSS 규칙을 본문 끝에 한 줄로 명시.
