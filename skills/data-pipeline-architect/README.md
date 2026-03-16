# data-pipeline-architect

데이터 파이프라인 구조 설계 및 서브에이전트 자동 생성 스킬.

## 트리거

- "데이터 파이프라인 설계해줘", "데이터 구조 리뷰해줘"
- "ETL 구조 잡아줘", "서브에이전트 구성해줘"

## 워크플로우

```
사용자 데이터 구조 초안
  → Phase 1: 8 불변 원칙 진단 (references/principles.md)
  → Phase 2: 파이프라인 단계 경계 식별
  → Phase 3: 서브에이전트 구조 설계 (references/agents.md)
  → Phase 4: Claude Code instruction 세트 생성 (references/instructions.md)
  → Phase 5: 자기 검증 체크리스트
```

부분 실행 가능: "진단만" → Phase 1, "에이전트까지" → Phase 1~3

## 파일 구조

```
data-pipeline-architect/
├── SKILL.md              ← 메인 워크플로우 (항상 로딩)
├── README.md             ← 이 파일
└── references/
    ├── principles.md     ← 8원칙 상세 정의
    ├── agents.md         ← 에이전트 설계 규칙
    └── instructions.md   ← instruction 생성 규칙
```
