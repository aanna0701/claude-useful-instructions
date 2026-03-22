---
name: diataxis-doc-system
description: >
  Diátaxis Framework 기반 기술 문서 작성 시스템.
  문서를 Tutorial, How-to Guide, Explanation, Reference 4가지 유형으로 분리하고,
  각 유형에 최적화된 서브 에이전트(doc-writer-tutorial, doc-writer-howto,
  doc-writer-explain, doc-writer-reference)를 호출하여 고품질 기술 문서를 생성한다.
  "문서 작성", "기술 문서", "아키텍처 문서", "API 문서", "가이드 작성", "튜토리얼 작성",
  "설계 문서", "Design Doc", "RFC 작성", "ADR 작성", "README 작성",
  "문서화", "documentation", "technical writing", "how-to 가이드",
  "레퍼런스 문서", "config reference", "CLI reference",
  "문서 구조", "docs 초기화", "MkDocs", "문서 사이트", "문서 보관서",
  "information architecture", "문서 체계" 등의 요청에 트리거.
  문서화 관련 요청이면 종류를 불문하고 이 스킬을 먼저 참조할 것.
---

# Diátaxis Documentation System

사용자의 문서 요청을 분석 → 유형 판별 → 유형별 에이전트 위임 → 품질 검증.

```
[요청] → Phase 1: 유형 판별 → Phase 2: 에이전트 위임 → Phase 3: 품질 검증
          (Router)              (4 유형 중 택)            (공통 규칙 체크)
```

---

## 핵심 원리

기술 문서의 실패는 대부분 **목적이 다른 내용을 한 문서에 섞는 것**에서 시작된다.
이 스킬은 Diátaxis Framework에 따라 문서를 4가지 유형으로 엄격히 분리하고,
각 유형에 특화된 에이전트를 위임한다.

| 유형 | 목적 | 독자 상태 | 에이전트 |
|------|------|-----------|----------|
| **Tutorial** | 학습 | 처음 접함 | `doc-writer-tutorial` |
| **How-to Guide** | 문제 해결 | 기본은 앎, 특정 문제 있음 | `doc-writer-howto` |
| **Explanation** | 이해 | "왜 이렇게?"를 알고 싶음 | `doc-writer-explain` |
| **Reference** | 정보 검색 | 정확한 스펙 필요 | `doc-writer-reference` |

---

## 워크플로우

### Phase 0: 입력 수집

**필수 (없으면 요청)**
- 문서의 주제/범위
- 대상 독자 (신입? 동료 개발자? 경영진?)
- 목적 (온보딩? 설계 리뷰? API 배포?)

**선택 (있으면 더 좋은 결과)**
- 기존 코드베이스 또는 문서
- 프로젝트 glossary
- 기존 다이어그램

### Phase 1: 유형 판별 (Router)

아래 질문으로 유형을 판별한다:

| 질문 | Yes → 유형 |
|------|-----------|
| 독자가 처음 접하고, 끝까지 따라하면 무언가를 만들 수 있는가? | **Tutorial** |
| 독자가 이미 기본을 알고, 특정 문제를 해결하려 하는가? | **How-to Guide** |
| 독자가 "왜 이렇게 설계했는가"를 이해하려 하는가? | **Explanation** |
| 독자가 정확한 스펙/파라미터/타입을 찾으려 하는가? | **Reference** |

판별이 어렵다면 사용자에게 질문:
> "이 문서의 주요 독자는 누구이고, 읽은 뒤 어떤 행동을 하길 바라시나요?"

하나의 프로젝트에 여러 유형이 필요할 수 있다. 이 경우 유형별로 별도 파일을 생성한다.

### Phase 2: 에이전트 위임

유형이 결정되면 해당 에이전트에게 위임한다:

- **Tutorial** → `doc-writer-tutorial` 에이전트에게 위임
- **How-to Guide** → `doc-writer-howto` 에이전트에게 위임
- **Explanation** → `doc-writer-explain` 에이전트에게 위임
- **Reference** → `doc-writer-reference` 에이전트에게 위임

에이전트 위임 시 Phase 0에서 수집한 정보를 함께 전달한다.

### Phase 3: 품질 검증

> 공통 규칙: `references/common-rules.md` 참조.
> 가독성/문체 규칙: `references/writing-style.md` 참조.

기존 문서 리뷰 요청이면 `doc-reviewer` 에이전트에게 위임할 수 있다.

문서 초안 완성 후 아래를 확인:

1. **유형 순수성**: 한 문서 안에 다른 유형의 내용이 섞이지 않았는가?
   - Tutorial에 Reference 표가 끼어 있으면 분리한다.
   - Explanation에 단계별 절차가 들어가면 How-to로 분리한다.
2. **독자 적합성**: 설정한 독자가 이 문서를 받아들고 목적을 달성할 수 있는가?
3. **6개월 테스트**: Apply longevity test (see common-rules.md).
4. **용어 일관성**: 같은 대상을 다른 이름으로 부르지 않았는가?
5. **상호 참조**: 관련 유형 문서로의 링크가 있는가?
6. **Diagrams as Code**: 다이어그램이 Mermaid/PlantUML로 작성되었는가?

---

## 부분 실행

| 요청 | 실행 범위 |
|------|-----------|
| "문서 작성해줘" | Phase 0→3 전체 |
| "이 문서 유형 판별해줘" | Phase 1만 |
| "이 문서 검토해줘" | Phase 3만 (기존 문서에 품질 검증) |
| "Reference만 추가해줘" | Phase 2 바로 진입 (유형 확정) |
| "문서 구조 잡아줘" | `/init-docs` 커맨드로 안내 |

---

## Explanation 서브타입: Design Doc vs ADR

Explanation 유형은 두 가지 서브타입이 있다:

| 서브타입 | 용도 | 규모 |
|----------|------|------|
| **Design Doc (RFC)** | 새 기능/시스템의 전체 설계 제안서 | 큰 변경, 리뷰 필요 |
| **ADR** | 개별 아키텍처 결정 기록 | 작은 결정, 이력 보존 |

판별 기준:
- "새 시스템/기능을 설계하고 리뷰 받고 싶다" → Design Doc
- "특정 기술 선택의 이유를 기록하고 싶다" → ADR

둘 다 `doc-writer-explain` 에이전트가 처리하며, 에이전트 내부에서 템플릿을 분기한다.

---

## 다른 스킬/커맨드와의 연계

- **`/init-docs`**: 프로젝트에 문서 사이트 구조(번호 체계 + MkDocs) 초기화
- **diagram-architect**: Explanation 문서에 아키텍처 다이어그램이 필요할 때 위임
- **doc-reviewer**: 기존 문서의 가독성/유형순수성/거버넌스 종합 리뷰
## 문서 사이트 아키텍처

개별 문서 작성 전에 프로젝트 전체의 문서 구조가 필요하다면:

> 사이트 구조 규칙: `references/site-architecture.md` 참조.
> 번호 체계(00-90), MkDocs 설정, 거버넌스 5대 규칙을 정의한다.
> `/init-docs` 커맨드가 이 규칙에 따라 구조를 자동 생성한다.
