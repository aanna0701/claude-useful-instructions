# init-docs — 프로젝트 문서 보관서 초기화

프로젝트에 MkDocs 기반 문서 사이트 구조(번호 체계 + Diátaxis)를 생성하고,
mkdocs.yml과 카테고리별 index.md를 자동 세팅한다.

Target: $ARGUMENTS (프로젝트 루트 경로. 비어있으면 현재 디렉토리)

---

## Step 0: 사전 조건 확인

1. `$ARGUMENTS`가 비어있으면 현재 디렉토리를 프로젝트 루트로 사용
2. 이미 `docs/` 디렉토리가 존재하는지 확인:
   - 존재하면 → 사용자에게 "기존 docs/ 구조가 있습니다. 병합할까요, 덮어쓸까요?" 확인
   - 없으면 → 새로 생성
3. `mkdocs.yml`이 존재하는지 확인:
   - 존재하면 → 백업 후 병합 제안
   - 없으면 → 새로 생성

---

## Step 1: 프로젝트 정보 수집

사용자에게 아래를 확인. 이미 대화에 있으면 다시 묻지 않음.

**필수:**
- 프로젝트 이름
- 프로젝트 한줄 설명

**선택 (기본값 있음):**
- 언어: 한국어(ko) / 영어(en) — 기본: ko
- 테마: material — 기본: material
- 필요한 카테고리 선택 (기본: 전체)

---

## Step 2: 규칙 파일 읽기

반드시 Read:
```
skills/diataxis-doc-system/references/site-architecture.md
```

이 파일의 폴더 구조, mkdocs.yml 템플릿, index.md 템플릿을 기반으로 생성한다.

---

## Step 3: 폴더 구조 생성

`site-architecture.md`의 "계층적 폴더 구조" 섹션에 따라 디렉토리와 파일 생성:

```bash
mkdir -p docs/{00_context,10_architecture/adr,20_implementation,30_guides/{tutorials,howto},40_operations,90_archive}
```

각 카테고리에 `index.md`를 생성한다. 템플릿은 `site-architecture.md`의 "카테고리 index.md 템플릿" 참조.

---

## Step 4: mkdocs.yml 생성

`site-architecture.md`의 "mkdocs.yml 기본 구조" 섹션을 기반으로 생성.
Step 1에서 수집한 프로젝트 정보를 반영:

- `site_name` ← 프로젝트 이름
- `site_description` ← 프로젝트 설명
- `theme.language` ← 선택 언어
- `nav` ← 생성된 파일 구조에 맞춰 동적 생성

---

## Step 5: glossary.md 생성

```markdown
---
title: "용어 사전"
status: published
owner: "[TBD]"
updated: [오늘 날짜]
---

# 용어 사전 (Glossary)

프로젝트 전체에서 사용하는 용어의 단일 정본(Single Source of Truth).

| 용어 | 정의 | 동의어 (사용 금지) |
|------|------|-------------------|
| | | |

## 용어 추가 규칙

1. 새 용어 도입 시 이 파일에 먼저 추가
2. "동의어" 컬럼의 단어는 문서에서 사용 금지
3. 다른 문서에서 용어를 정의하지 않고, 이 파일로 링크
```

---

## Step 6: docs/index.md 생성

```markdown
---
title: "Home"
---

# [프로젝트명] Documentation

[프로젝트 한줄 설명]

## 문서 지도

| 카테고리 | 설명 |
|----------|------|
| [Context](00_context/index.md) | 비즈니스 목표, 요구사항, 용어 사전 |
| [Architecture](10_architecture/index.md) | 시스템 설계, 기술 스택, ADR |
| [Implementation](20_implementation/index.md) | API/Config/CLI 명세 |
| [Guides](30_guides/index.md) | 튜토리얼, How-to 가이드 |
| [Operations](40_operations/index.md) | 배포, 모니터링, Runbook |
| [Archive](90_archive/index.md) | 과거 문서 보관 |

## 빠른 시작

- 🆕 신규 팀원이라면 → [Getting Started](30_guides/tutorials/getting-started.md)
- 🔧 특정 작업이 필요하면 → [How-to Guides](30_guides/howto/)
- 📐 설계 결정을 알고 싶으면 → [Architecture](10_architecture/index.md)
- 📖 API 스펙을 찾고 있다면 → [API Reference](20_implementation/api-reference.md)
```

---

## Step 7: 90_archive/index.md 생성

```markdown
---
title: "Archive"
---

# Archive

더 이상 유효하지 않지만 참고용으로 보존하는 문서.

## 아카이브 목록

| 문서 | 원래 위치 | 이동 사유 | 이동일 | 대체 문서 |
|------|-----------|-----------|--------|-----------|
| (아직 없음) | | | | |

## 아카이브 절차

1. 해당 문서에 `status: deprecated` 설정
2. 이 폴더로 이동
3. 위 표에 이동 사유 기록
4. 원래 위치에 대체 문서 링크 안내 (선택)
```

---

## Step 8: CI/CD 파일 생성 (선택)

사용자에게 확인:
> "GitHub Actions로 문서 자동 배포(gh-pages)와 링크 검사를 설정할까요?"

Yes이면 `.github/workflows/docs.yml`과 `.github/workflows/docs-lint.yml`을
`site-architecture.md`의 "CI/CD 자동화" 섹션에 따라 생성.

---

## Step 9: 완료 리포트

```
문서 보관서 초기화 완료
─────────────────────────────────
프로젝트:  [프로젝트명]
구조:
  docs/
  ├── index.md
  ├── glossary.md
  ├── 00_context/       (index.md)
  ├── 10_architecture/  (index.md + adr/)
  ├── 20_implementation/(index.md)
  ├── 30_guides/        (index.md + tutorials/ + howto/)
  ├── 40_operations/    (index.md)
  └── 90_archive/       (index.md)

  mkdocs.yml            ✅ 생성
  CI/CD                 [✅ 생성 / ⏭ 건너뜀]
─────────────────────────────────
다음 단계:
  pip install mkdocs-material       # MkDocs 설치
  mkdocs serve                      # 로컬 미리보기
  /write-doc [주제]                  # 문서 작성 시작
```
