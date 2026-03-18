# diataxis-doc-system

Diátaxis Framework 기반 기술 문서 작성 스킬. 문서 유형을 자동 판별하고 유형별 전문 에이전트에게 위임한다.

## 트리거

- "문서 작성해줘", "기술 문서", "가이드 작성", "튜토리얼 작성"
- "설계 문서", "Design Doc", "RFC 작성", "ADR 작성"
- "API 문서", "레퍼런스 문서", "config reference", "CLI reference"
- "how-to 가이드", "문서화", "documentation"

## 핵심 원칙

1. **유형 분리** — Tutorial / How-to / Explanation / Reference를 한 문서에 섞지 않는다
2. **독자 중심** — 독자가 누구인지, 읽고 나서 무엇을 하는지로 유형을 결정
3. **Docs as Code** — Markdown + Mermaid + Git, 이미지 파일 대신 텍스트 코드
4. **용어 일관성** — Glossary로 같은 대상을 다른 이름으로 부르지 않기
5. **상호 참조** — 유형 간 적극적으로 링크

## 워크플로우

```
사용자 요청
  → Phase 1: 유형 판별 (Router)
  → Phase 2: 에이전트 위임 (4 유형 중 택)
  → Phase 3: 품질 검증 (공통 규칙 체크)
```

## 파일 구조

```
diataxis-doc-system/
├── SKILL.md              ← 메인 워크플로우 (Router)
├── README.md             ← 이 파일
└── references/
    ├── common-rules.md   ← Docs as Code 공통 규칙
    ├── tutorial-rules.md ← Tutorial 에이전트 상세 규칙
    ├── howto-rules.md    ← How-to Guide 에이전트 상세 규칙
    ├── explain-rules.md  ← Explanation 에이전트 상세 규칙
    └── reference-rules.md← Reference 에이전트 상세 규칙
```

## 관련 에이전트

- `agents/doc-writer-tutorial.md` — Tutorial 작성 전담
- `agents/doc-writer-howto.md` — How-to Guide 작성 전담
- `agents/doc-writer-explain.md` — Explanation (Design Doc / ADR) 작성 전담
- `agents/doc-writer-reference.md` — Reference 작성 전담

## 관련 스킬

- `diagram-architect` — 문서 내 아키텍처 다이어그램 생성
- `diagram-pipeline` — Mermaid → draw.io → docs 삽입
