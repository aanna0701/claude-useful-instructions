---
description: 기존 HTML 발표자료를 표준 16:9 다크테마 슬라이드 덱으로 변환한다
---

# format-presentation

이미 어느 정도 작성된 HTML 발표자료를 읽어서 표준 포맷으로 재생성한다.
슬라이드 내용은 그대로 유지하고, CSS/JS/레이아웃만 base-template으로 교체한다.

---

## 입력

`$ARGUMENTS`: `[input.html] [logo_path]`

인자가 없으면 아래를 요청한다:

> "변환할 HTML 파일 경로와 로고 파일 경로를 알려주세요."

---

## 실행 단계

### Step 1: 파일 읽기

- `$ARGUMENTS`의 HTML 파일을 Read
- 로고 경로 확인 (공백 있으면 `%20` 인코딩 필요)

### Step 2: html-presentation 스킬 실행

`~/.claude/skills/html-presentation/SKILL.md`를 Read한 뒤 Phase 0~4를 순서대로 실행.

**핵심 원칙:**

- `~/.claude/skills/html-presentation/base-template.html`의 CSS/JS를 **그대로** 사용
- 원본 HTML의 텍스트 내용은 변경 없이 유지
- 모든 슬라이드에 `.slide-dark` 클래스 적용
- 모든 슬라이드에 `.slide-label` 포함

### Step 3: 출력

완성된 HTML을 Write 툴로 저장.

- 파일명: `{원본파일명}-formatted.html` (같은 디렉터리)
- 저장 후 슬라이드 목록(번호 / 섹션명 / 컴포넌트 타입) 표로 요약 출력

---

## PDF 변환

```bash
# 최초 1회 설정
uv run playwright install chromium

# 변환 (1920×1080, .slide-deck 영역만 캡처)
uv run scripts/html_to_pdf.py output-formatted.html
```
