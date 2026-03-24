---
description: HTML 슬라이드 덱을 PDF로 변환한다. 16:9 슬라이드 영역만 캡처 (letterbox 제외)
---

# export-pdf

`$ARGUMENTS`: `[input.html] [output.pdf]`

출력 경로 생략 시 `{입력파일명}.pdf`로 저장.

---

## 실행

### Step 1: 의존성 확인

```bash
uv run python -c "import playwright; import PIL" 2>/dev/null
```

실패하면 설치 안내 후 중단:

> playwright 또는 pillow가 없습니다. 아래를 실행하세요:
> ```
> uv run playwright install chromium
> ```
> (pillow는 uv가 pyproject.toml에서 자동 설치합니다)

### Step 2: 변환 실행

```bash
uv run {SKILL_DIR}/scripts/html_to_pdf.py {input.html} {output.pdf}
```

`{SKILL_DIR}`은 스킬이 설치된 경로 (`~/.claude/skills/html-presentation` 또는 레포 루트의 `scripts/`).

실제 스크립트 위치는 아래 순서로 탐색:
1. `~/.claude/scripts/html_to_pdf.py`
2. 현재 디렉터리의 `scripts/html_to_pdf.py`
3. 레포 루트의 `scripts/html_to_pdf.py`

### Step 3: 결과 보고

변환 완료 후 출력:

```
✓ PDF 생성 완료
  입력: {input.html}  ({슬라이드 수}장)
  출력: {output.pdf}  ({파일 크기} MB)
```

실패 시 오류 메시지와 함께 원인 진단:
- `playwright install chromium` 미실행 → 설치 명령 안내
- 파일 경로 오류 → 경로 확인 요청
- `#deck` 요소 없음 → "표준 포맷이 아닙니다. /format-presentation을 먼저 실행하세요"
