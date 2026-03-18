# diagram-architect

Mermaid 기반 아키텍처 다이어그램 설계 스킬.

## 트리거

- "다이어그램 그려줘", "아키텍처 도식화", "시스템 구조도"
- "mermaid 다이어그램", "flowchart", "sequence diagram"
- "데이터 흐름도", "ERD", "컴포넌트 다이어그램"

## 핵심 원칙

1. **C4 계층화** — 한 장에 모든 것 금지
2. **선 의미 명확화** — 실선(동기), 점선(비동기)
3. **추상화 수준 유지** — 인프라 ↔ 비즈니스 혼합 금지
4. **색상 일관성** — 3-4색 + 범례 필수
5. **텍스트 최소화** — 도형 안 축약, 번호 매기기, 본문 설명

## 워크플로우

```
사용자 요청
  → Phase 1: 분석 (복잡도, C4 레벨, 타입 결정)
  → Phase 2: 분해 (계층/관점/영역별 분할)
  → Phase 3: 생성 (diagram-writer 에이전트 위임)
  → Phase 4: 검증 (체크리스트)
```

## 파일 구조

```
diagram-architect/
├── SKILL.md              ← 메인 워크플로우
├── README.md             ← 이 파일
└── references/
    ├── diagram-rules.md  ← Mermaid 작성 규칙 (색상, 선, 텍스트, C4)
    └── checklist.md      ← 검증 체크리스트
```

## 관련 에이전트

- `agents/diagram-writer.md` — Mermaid 코드 생성 전담
