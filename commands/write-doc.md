# write-doc — Diátaxis Framework 기반 기술 문서 작성

Diátaxis Framework에 따라 문서 유형을 판별하고, 유형별 전문 에이전트에게 위임하여 고품질 기술 문서를 작성한다.

Target: $ARGUMENTS (문서 주제 또는 "review [파일경로]" 형태)

---

## Step 0: 모드 판별

`$ARGUMENTS`를 분석:

| 패턴 | 모드 | 동작 |
|------|------|------|
| `review [파일경로]` | 기존 문서 검토 | → Step 5로 직행 |
| 그 외 | 새 문서 작성 | → Step 1부터 |

---

## Step 1: 입력 수집

사용자에게 아래를 확인. 이미 대화에 있으면 다시 묻지 않음.

**필수:**
- 문서의 주제/범위
- 대상 독자 (신입? 동료 개발자? 경영진?)

**선택 (더 좋은 결과):**
- 기존 코드베이스 경로
- 프로젝트 glossary 경로
- 참고할 기존 문서

---

## Step 2: 유형 판별 (Router)

| 질문 | Yes → 유형 |
|------|-----------|
| 독자가 처음 접하고, 끝까지 따라하면 무언가를 만드는가? | **Tutorial** |
| 독자가 기본은 알고, 특정 문제를 해결하려 하는가? | **How-to Guide** |
| 독자가 "왜 이렇게 설계했는가"를 이해하려 하는가? | **Explanation** |
| 독자가 정확한 스펙/파라미터/타입을 찾으려 하는가? | **Reference** |

판별이 어려우면 사용자에게 질문:
> "이 문서의 주요 독자는 누구이고, 읽은 뒤 어떤 행동을 하길 바라시나요?"

하나의 프로젝트에 여러 유형 필요 시 유형별 별도 파일 생성.

사용자에게 판별 결과를 보여주고 확인:
```
📝 문서 유형: [Tutorial / How-to Guide / Explanation / Reference]
   독자: [대상 독자]
   결과물: [문서를 읽고 나서 독자가 할 수 있는 것]
```

---

## Step 3: 에이전트 위임

유형에 따라 해당 에이전트에게 위임:

- **Tutorial** → `doc-writer-tutorial` 에이전트에게 위임
- **How-to Guide** → `doc-writer-howto` 에이전트에게 위임
- **Explanation** → `doc-writer-explain` 에이전트에게 위임
- **Reference** → `doc-writer-reference` 에이전트에게 위임

위임 시 Step 1에서 수집한 정보를 함께 전달.

---

## Step 4: 파일 저장

에이전트가 작성한 문서를 프로젝트 docs/ 구조에 맞게 저장:

```
docs/
├── tutorials/      ← Tutorial
├── howto/          ← How-to Guide
├── explanation/    ← Explanation (Design Doc, ADR)
│   └── adr/        ← ADR 전용
└── reference/      ← Reference
```

파일명: kebab-case, 한글 금지.
- Tutorial: `getting-started.md`, `first-deployment.md`
- How-to: `migrate-database.md`, `rotate-tokens.md`
- Explanation: `architecture-overview.md`, `adr/001-database-choice.md`
- Reference: `api.md`, `config.md`, `cli.md`

---

## Step 5: 품질 검증 (review 모드 포함)

기존 문서 검토(`review`) 또는 새 문서 검증에 적용:

### 유형 순수성 검사
- [ ] Tutorial에 Reference 표가 끼어 있지 않은가?
- [ ] How-to에 기초 설명이 들어가 있지 않은가?
- [ ] Explanation에 단계별 절차가 있지 않은가?
- [ ] Reference에 의견/추천이 섞이지 않았는가?

### 공통 품질 검사
- [ ] YAML frontmatter가 완전한가?
- [ ] 다이어그램이 Mermaid/PlantUML로 되어 있는가?
- [ ] 용어가 glossary와 일치하는가?
- [ ] 관련 유형 문서로의 상호 참조 링크가 있는가?
- [ ] 6개월 뒤에도 유효한가?

위반 항목이 있으면 수정 사항을 제안하고, 사용자 확인 후 적용.

---

## Step 6: 완료 리포트

```
문서 작성 완료
─────────────────────────────────
유형:     [Tutorial / How-to / Explanation / Reference]
파일:     docs/[경로]/[파일명].md
독자:     [대상 독자]
품질 검사: ✅ 통과 (또는 ⚠️ N건 수정)
─────────────────────────────────
관련 문서 추천:
  - [아직 없는 관련 유형 문서 제안]
```
