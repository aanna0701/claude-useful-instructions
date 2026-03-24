---
description: HTML 발표자료를 Navigantis 16:9 다크테마 슬라이드 덱으로 변환한다
---

# format-presentation

발표 내용(텍스트/마크다운/개요)과 로고 파일을 받아 표준 HTML 프레젠테이션으로 변환한다.

---

## 입력

`$ARGUMENTS`: `[content_or_path] [logo_path]`

인자가 없으면 아래를 요청한다:
> "발표 내용(텍스트, 마크다운, 혹은 파일 경로)과 로고 파일 경로를 알려주세요."

---

## 실행 단계

### Step 1: 입력 파싱

- `$ARGUMENTS`가 파일 경로이면 Read로 내용 읽기
- 로고 경로 확인 — 없으면 빈 상태로 계속 (나중에 교체 가능)
- 발표자/날짜/팀 정보가 있으면 추출, 없으면 placeholder 사용

### Step 2: html-presentation 스킬 실행

`~/.claude/skills/html-presentation/SKILL.md` 를 Read한 뒤 Phase 0~4를 순서대로 실행.

**반드시 지켜야 할 규칙:**
- `~/.claude/skills/html-presentation/base-template.html` 의 CSS/JS를 **그대로** 사용
- 모든 슬라이드에 `.slide-dark` 클래스 적용
- 모든 슬라이드에 `.slide-label` 포함 (헤더 자동 업데이트용)
- 로고 경로의 공백은 `%20`으로 인코딩 (예: `my logo.png` → `my%20logo.png`)
- 내용을 슬라이드별 적절한 컴포넌트(cards, table, timeline 등)로 매핑

### Step 3: 출력

완성된 HTML을 Write 툴로 파일에 저장.
- 파일명: `{발표주제}-presentation.html` (현재 디렉터리에 저장)
- 저장 완료 후 슬라이드 목록(번호, 섹션명, 레이아웃)을 표로 요약 출력

---

## 결과 확인

브라우저에서 파일을 열면 바로 동작하는 16:9 슬라이드 덱이 나타납니다.
- ← → 키 또는 하단 버튼으로 슬라이드 이동
- PDF 변환은 `scripts/html_to_pdf.py` 사용 (README 참조)
