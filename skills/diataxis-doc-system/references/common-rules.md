# 공통 규칙: Docs as Code

이 규칙은 문서 유형(Tutorial / How-to / Explanation / Reference)에 관계없이 **모든 문서**에 적용된다.
에이전트는 문서 작성 전 이 파일을 반드시 Read해야 한다.

---

## 1. 저장과 버전 관리

### Single Source of Truth
- 문서는 코드 저장소(Git)에 함께 존재한다
- Confluence, Notion 등 외부 위키에 복사본을 두지 않는다
- 문서 변경도 코드 변경과 동일한 리뷰 프로세스(PR)를 거친다

### 파일 형식
- **Markdown** (.md) 기본
- 복잡한 조판이 필요하면 AsciiDoc (.adoc)
- Word, PDF는 최종 배포물이지, 원본이 아니다

### 파일 구조 규칙

프로젝트 규모에 따라 두 가지 구조 중 선택한다:

- **소규모 (문서 20개 미만):** Diátaxis 유형별 분류 (tutorials/, howto/, explanation/, reference/)
- **중대규모 (문서 20개 이상):** 번호 체계 + MkDocs (00_context ~ 90_archive)

For directory structure templates, see init-docs.md.
번호 체계의 상세 규칙: `references/site-architecture.md` 참조.

---

## 2. Diagrams as Code

### 원칙
- 다이어그램은 이미지 파일(.png, .jpg)이 아니라 **텍스트 코드**로 관리
- 구조가 바뀌면 텍스트 한 줄만 수정
- Git diff로 변경 사항 추적 가능

### 도구 선택
| 상황 | 도구 | 이유 |
|------|------|------|
| 빠른 플로차트, 시퀀스 | **Mermaid** | GitHub/GitLab 네이티브 렌더링 |
| 복잡한 UML, 정밀 레이아웃 | **PlantUML** | 레이아웃 제어력 우수 |
| 인프라/클라우드 토폴로지 | **Diagrams (Python)** | 클라우드 아이콘 지원 |

> diagram-architect 스킬이 있으면 다이어그램 생성을 위임할 수 있다.

### Mermaid 작성 규칙
- 노드 이름: 약어 대신 전체 단어 (`DB` → `Database`)
- 화살표 레이블: 조건이나 관계를 명시
- 색상: 시맨틱하게 사용 (오류=빨강, 성공=초록)

---

## 3. 용어 일관성

### Glossary 파일 유지
프로젝트 루트에 `glossary.md`를 유지한다.
For glossary table template, see init-docs.md Step 5.

### 규칙
- 새 용어 도입 → glossary에 먼저 추가
- 문서 리뷰 시 용어 일관성을 체크리스트에 포함
- 외부 독자용 문서라면 첫 등장 시 정의를 괄호 병기

---

## 4. 메타데이터

모든 문서 상단에 YAML frontmatter:

```yaml
---
title: "문서 제목"
type: tutorial | howto | explanation | reference
status: draft | review | published | deprecated
author: "작성자"
owner: "유지보수 담당자"       # 정보가 오래되면 이 사람에게 문의
created: 2025-01-15
updated: 2025-03-18
tags: [auth, api]              # 검색용 태그 (허용 목록에서 선택)
audience: "대상 독자 (예: Backend Engineers)"
---
```

**status 생명주기:**
```
draft → review → published → deprecated → (90_archive/ 이동)
```

> 거버넌스 5대 규칙(SSOT, 날짜/상태, 태그, 오너십, 가지치기)의 상세:
> `references/site-architecture.md` 참조.

---

## 5. 상호 참조 (Cross-linking)

문서 유형은 서로 보완 관계다. 적극적으로 링크:

```
Tutorial → How-to → Reference → Explanation → Tutorial
```

- 상대 경로: `[관련 가이드](../howto/migrate-database.md)`
- 절대 URL은 외부 링크에만
- 깨진 링크 검사를 CI/CD에 포함

---

## 6. 리뷰 체크리스트

문서 PR 시 확인:

### 유형 & 구조
- [ ] 문서 유형이 명확한가? (Tutorial/How-to/Explanation/Reference 중 하나)
- [ ] 한 문서에 다른 유형의 내용이 섞이지 않았는가?
- [ ] 메타데이터(YAML frontmatter)가 완전한가? (title, type, status, author, owner, tags)
- [ ] 다이어그램이 텍스트 코드(Mermaid/PlantUML)로 작성되었는가?

### 품질 & 일관성
- [ ] 용어가 glossary와 일치하는가?
- [ ] 관련 문서로의 상호 참조 링크가 있는가?
- [ ] 6개월 뒤에도 유효한가? (변하기 쉬운 수치에 하드코딩이 없는가?)

### 가독성 & 문체 (writing-style.md)
- [ ] 제목과 굵은 글씨만으로 전체 흐름이 파악되는가? (Scanning test)
- [ ] 능동태/명령형을 사용하고, 한 문장에 하나의 정보만 담았는가?
- [ ] 리스트 항목 ≤ 9개, 들여쓰기 ≤ 3단계를 지켰는가?
- [ ] Bold/Italic/Code 강조가 기능적으로 사용되었는가?

### 거버넌스
- [ ] `owner` 필드가 지정되어 있는가?
- [ ] 같은 정보가 다른 문서에 중복되지 않는가? (SSOT)
- [ ] `tags`가 허용 목록에 있는 태그만 사용하는가?
