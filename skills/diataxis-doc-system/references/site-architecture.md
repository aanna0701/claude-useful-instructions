# 문서 사이트 아키텍처 (Information Architecture)

문서가 쌓이기 시작하면 정작 필요한 정보를 찾는 데 더 많은 시간이 걸린다.
이 파일은 MkDocs 기반 문서 사이트의 **계층 구조, 번호 체계, 거버넌스 규칙**을 정의한다.

`/init-docs` 커맨드가 이 규칙에 따라 프로젝트 문서 구조를 초기화한다.

---

## 1. 계층적 폴더 구조 (The 3-Level Hierarchy)

`00-99` 번호 체계로 정렬 순서를 강제한다. 번호는 **카테고리**를 나타내며,
각 카테고리 안에서 Diátaxis 유형(Tutorial / How-to / Explanation / Reference)이 공존한다.

```
docs/
├── index.md                         # 문서 홈 (프로젝트 개요 + 문서 지도)
├── glossary.md                      # 용어 사전 (SSOT)
│
├── 00_context/                      # 맥락: 왜 이 프로젝트인가
│   ├── index.md                     # 카테고리 개요
│   ├── business-goals.md            # [Explanation] 비즈니스 목표
│   ├── personas.md                  # [Reference] 사용자 페르소나
│   ├── requirements.md              # [Reference] 요구사항 정의
│   └── glossary-guide.md            # [How-to] 용어 사전 관리 방법
│
├── 10_architecture/                 # 설계: 어떻게 만들 것인가
│   ├── index.md
│   ├── system-overview.md           # [Explanation] 시스템 전체 구조
│   ├── tech-stack.md                # [Explanation] 기술 스택 결정 사유
│   ├── data-model.md                # [Reference] 데이터 모델
│   └── adr/                         # Architecture Decision Records
│       ├── 001-database-choice.md
│       └── 002-auth-strategy.md
│
├── 20_implementation/               # 구현: 코드 레벨 상세
│   ├── index.md
│   ├── api-reference.md             # [Reference] API 명세
│   ├── config-reference.md          # [Reference] 설정값
│   ├── cli-reference.md             # [Reference] CLI 옵션
│   └── module-guide.md              # [Explanation] 모듈별 상세 설계
│
├── 30_guides/                       # 가이드: 실무 작업 안내
│   ├── index.md
│   ├── tutorials/                   # [Tutorial] 처음부터 따라하기
│   │   ├── getting-started.md
│   │   └── first-deployment.md
│   └── howto/                       # [How-to] 특정 문제 해결
│       ├── migrate-database.md
│       ├── rotate-tokens.md
│       └── troubleshooting.md
│
├── 40_operations/                   # 운영: 프로덕션 관리
│   ├── index.md
│   ├── deploy-guide.md              # [How-to] 배포 절차
│   ├── monitoring.md                # [Explanation] 모니터링 구성
│   ├── runbook.md                   # [How-to] 장애 대응 매뉴얼
│   └── sla-reference.md             # [Reference] SLA 기준
│
└── 90_archive/                      # 보관: 더 이상 유효하지 않은 문서
    ├── index.md                     # 아카이브 인덱스 + 이동 이유
    └── ...                          # deprecated 문서들
```

### 번호 체계 규칙

| 번호 대역 | 카테고리 | 핵심 질문 |
|-----------|---------|-----------|
| `00` | Context | **왜** 이 프로젝트를 하는가? |
| `10` | Architecture | **어떻게** 만들 것인가? (설계) |
| `20` | Implementation | **무엇을** 만들었는가? (코드 레벨) |
| `30` | Guides | **어떻게** 사용하는가? (실무) |
| `40` | Operations | **어떻게** 운영하는가? (프로덕션) |
| `50-80` | (예약) | 프로젝트별 확장 가능 |
| `90` | Archive | 더 이상 유효하지 않은 문서 |

### 번호 vs Diátaxis 매핑

번호 체계는 **주제(도메인)**별 분류이고, Diátaxis는 **목적**별 분류다.
두 축은 직교한다 — 하나의 카테고리 안에 여러 Diátaxis 유형이 공존할 수 있다.

```
              Tutorial   How-to   Explanation   Reference
00_context       -          ●          ●            ●
10_architecture  -          -          ●            ●
20_implementation-          -          ●            ●
30_guides        ●          ●          -            -
40_operations    -          ●          ●            ●
```

각 문서의 YAML frontmatter `type` 필드로 Diátaxis 유형을 명시한다.

---

## 2. MkDocs 설정

### mkdocs.yml 기본 구조

```yaml
site_name: "[프로젝트명] Documentation"
site_description: "[프로젝트 한줄 설명]"
docs_dir: docs/

theme:
  name: material
  language: ko
  features:
    - navigation.tabs           # 상단 탭 네비게이션
    - navigation.sections       # 사이드바 섹션 접기
    - navigation.indexes        # 카테고리 index.md를 탭 랜딩으로
    - navigation.top            # 맨 위로 버튼
    - search.suggest            # 검색 자동완성
    - search.highlight          # 검색 결과 하이라이트
    - content.tabs.link         # 탭 링크 동기화
    - toc.integrate             # 목차 사이드바 통합
  palette:
    - scheme: default
      toggle:
        icon: material/brightness-7
    - scheme: slate
      toggle:
        icon: material/brightness-4

plugins:
  - search:
      lang: [en, ko]
  - tags                        # 태그 기반 검색
  - git-revision-date-localized:  # 마지막 수정일 자동 표시
      enable_creation_date: true

markdown_extensions:
  - admonition                  # !!! note, warning 박스
  - pymdownx.details            # 접기/펼치기
  - pymdownx.superfences:       # mermaid 렌더링
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:            # 탭 UI (OS별 분기 등)
      alternate_style: true
  - attr_list                   # 이미지 속성
  - md_in_html                  # HTML 안에 마크다운
  - toc:
      permalink: true           # 섹션 링크

extra:
  tags:                         # 태그 정의
    Auth: auth
    Database: database
    API: api
    Infra: infra
    Security: security

nav:
  - Home: index.md
  - 용어 사전: glossary.md
  - Context:
    - 00_context/index.md
    - 비즈니스 목표: 00_context/business-goals.md
    - 요구사항: 00_context/requirements.md
  - Architecture:
    - 10_architecture/index.md
    - 시스템 개요: 10_architecture/system-overview.md
    - 기술 스택: 10_architecture/tech-stack.md
    - ADR:
      - 10_architecture/adr/001-database-choice.md
  - Implementation:
    - 20_implementation/index.md
    - API Reference: 20_implementation/api-reference.md
    - Config Reference: 20_implementation/config-reference.md
  - Guides:
    - 30_guides/index.md
    - Tutorials:
      - 30_guides/tutorials/getting-started.md
    - How-to:
      - 30_guides/howto/migrate-database.md
  - Operations:
    - 40_operations/index.md
    - 배포 가이드: 40_operations/deploy-guide.md
    - Runbook: 40_operations/runbook.md
  - Archive: 90_archive/index.md
```

### index.md 작성 규칙

각 카테고리의 `index.md`는 **문서 지도** 역할:

```markdown
---
title: "[카테고리명]"
tags: []
---

# [카테고리명]

[이 카테고리가 다루는 영역 2~3문장]

## 이 섹션의 문서

| 문서 | 유형 | 설명 | 최종 수정 |
|------|------|------|-----------|
| [시스템 개요](system-overview.md) | Explanation | 전체 아키텍처 설명 | 2025-03-18 |
| [데이터 모델](data-model.md) | Reference | 엔티티 관계, 스키마 | 2025-03-10 |
```

---

## 3. 거버넌스 5대 규칙

문서가 "쓰레기통"이 되지 않게 관리하는 실무 규칙.

### 규칙 1: Single Source of Truth (SSOT)

동일한 정보는 **딱 한 곳**에만 적는다.

| 패턴 | DO | DON'T |
|------|-----|-------|
| API 스펙 | 코드에서 자동 생성, 설계서에서 링크 | 설계서에 스펙 복사-붙여넣기 |
| 설정값 | config reference 한 곳에 정리 | README에도, 가이드에도 중복 나열 |
| 용어 정의 | `glossary.md`에 정의, 다른 문서에서 링크 | 각 문서마다 용어 재정의 |

위반 감지: 같은 내용이 2곳 이상에 있으면, 하나를 정본으로 지정하고 나머지는 링크로 교체.

### 규칙 2: Date & Status Marking

모든 문서 상단 YAML frontmatter에 필수:

```yaml
---
title: "문서 제목"
type: tutorial | howto | explanation | reference
status: draft | review | published | deprecated
author: "작성자"
owner: "유지보수 담당자"     # ← 거버넌스 추가 필드
created: 2025-01-15
updated: 2025-03-18
tags: [auth, api]            # ← 검색용 태그
audience: "Backend Engineers"
---
```

**status 생명주기:**
```
draft → review → published → deprecated → (90_archive/ 이동)
```

### 규칙 3: Searchability (Tagging)

폴더 구조만으로는 교차 관심사(cross-cutting concerns)를 찾기 어렵다.
YAML frontmatter의 `tags` 필드로 검색 효율을 높인다.

태그 규칙:
- 소문자 kebab-case: `auth`, `database`, `deploy`, `monitoring`
- 프로젝트 수준에서 허용 태그 목록을 관리 (mkdocs.yml `extra.tags`)
- 자유 태그 금지 — 허용 목록에 없는 태그는 먼저 목록에 추가

MkDocs Material의 tags 플러그인이 태그 인덱스 페이지를 자동 생성한다.

### 규칙 4: Ownership

각 문서에 `owner` 필드를 지정. 정보가 오래되었을 때 누구에게 물어볼지 명확히 한다.

```yaml
owner: "@alice"   # GitHub handle 또는 팀명
```

오너 책임:
- 분기 1회 문서 유효성 확인 (status가 published인 문서)
- 코드 변경 시 관련 문서 업데이트 (PR 체크리스트 연동)
- deprecated 판단 및 archive 이동

오너가 팀을 떠나면 반드시 새 오너를 지정한다.

### 규칙 5: Pruning (가지치기)

**잘못된 정보는 정보가 없는 것보다 위험하다.**

가지치기 트리거:
- 분기 1회 전체 문서 리뷰 (오너별)
- `updated` 날짜가 6개월 이상 된 문서 자동 경고
- 참조하는 코드/설정이 삭제된 문서

가지치기 절차:
1. 해당 문서에 `status: deprecated` + deprecation 사유 기록
2. `90_archive/`로 이동
3. 원래 위치에 리다이렉트 또는 안내 메시지 남기기 (선택)
4. archive index.md에 이동 사유와 날짜 기록

---

## 4. 카테고리 index.md 템플릿

```markdown
---
title: "[NN_카테고리명]"
---

# [카테고리명]

[이 카테고리가 다루는 영역 설명. 2~3문장.]

## 문서 목록

| 문서 | 유형 | 상태 | 담당자 | 최종 수정 |
|------|------|------|--------|-----------|
| [문서 제목](파일명.md) | [유형] | [상태] | [@이름] | [날짜] |

## 관련 카테고리

- [이전 단계: XX_카테고리](../XX_카테고리/index.md)
- [다음 단계: XX_카테고리](../XX_카테고리/index.md)
```

---

## 5. Archive 규칙

`90_archive/`는 문서의 묘지가 아니라 **참고용 서고**다.

### archive/index.md 템플릿

```markdown
---
title: "Archive"
---

# Archive

더 이상 유효하지 않지만 참고용으로 보존하는 문서.

## 아카이브 목록

| 문서 | 원래 위치 | 이동 사유 | 이동일 | 대체 문서 |
|------|-----------|-----------|--------|-----------|
| [v1 API 스펙](v1-api.md) | 20_implementation/ | v2로 교체 | 2025-03 | [v2 API](../20_implementation/api-reference.md) |
```

### 아카이브된 문서 상단 표시

```markdown
---
status: deprecated
---

> ⚠️ **이 문서는 더 이상 유효하지 않습니다.**
> 대체 문서: [v2 API Reference](../20_implementation/api-reference.md)
> 아카이브 사유: v2 API 출시로 v1 스펙 폐기
> 아카이브 일자: 2025-03-18
```

---

## 6. CI/CD 자동화 (선택)

MkDocs 기반 문서 사이트라면 아래 자동화를 추천:

```yaml
# .github/workflows/docs.yml
name: docs
on:
  push:
    branches: [main]
    paths: ['docs/**', 'mkdocs.yml']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # git-revision-date 플러그인용
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install mkdocs-material mkdocs-git-revision-date-localized-plugin
      - run: mkdocs gh-deploy --force
```

### 링크 검사 자동화

```yaml
# .github/workflows/docs-lint.yml
name: docs-lint
on: pull_request
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install mkdocs-material
      - run: mkdocs build --strict   # 깨진 링크 감지
```
