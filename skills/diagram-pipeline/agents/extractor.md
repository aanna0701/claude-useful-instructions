---
name: diagram-extractor
description: "docs의 mermaid 블록을 찾아 .mermaid 파일로 추출하고 manifest.json을 생성하는 에이전트"
tools: Read, Write, Glob, Grep
model: sonnet
---

# Extractor Agent

docs/ 안의 모든 markdown 파일에서 ```mermaid 블록을 찾아 diagrams/에 추출한다.

## 실행 순서

### 1. 기존 manifest 로드 (있으면)
`diagrams/manifest.json`이 있으면 Read해서 기존 항목을 `existing` 맵으로 로드.
없으면 빈 맵으로 시작.

### 2. markdown 파일 수집
`docs/**/*.md` glob으로 모든 markdown 파일 목록 수집.

### 3. 각 파일에서 mermaid 블록 추출

파일을 Read한 뒤 줄 단위로 스캔:

```
lines = file_content.splitlines()
i = 0
while i < len(lines):
    if lines[i].strip() == "```mermaid":  # 정확히 ```mermaid인 줄
        fence_start = i                    # 0-based, ```mermaid 줄
        content_lines = []
        j = i + 1
        while j < len(lines):
            if lines[j].strip() == "```":  # 닫는 펜스
                break
            content_lines.append(lines[j])
            j += 1
        fence_end = j                      # 0-based, 닫는 ``` 줄
        content = "\n".join(content_lines).strip()
        # fence_start 위쪽에서 가장 가까운 ## 제목 찾기 (최대 5줄 위)
        title = None
        for k in range(fence_start - 1, max(fence_start - 6, -1), -1):
            t = lines[k].strip()
            if t.startswith("#"):
                title = t.lstrip("#").strip()
                break
            if t:  # 비어있지 않은 줄이면 중단
                break
        # 블록 기록
        i = fence_end + 1
    else:
        i += 1
```

### 4. 각 블록에 ID 부여 및 파일 저장

- **doc_stem**: `docs/modules/arch.md` → `modules_arch`
  - `relative_path.with_suffix("").replace("/", "_").replace("-", "_")`
- **diagram id**: `{doc_stem}_{index:02d}` (같은 파일 내 순서, 1부터)
- **content_hash**: content를 SHA-256 앞 16자리 (`sha256:xxxxxxxxxxxxxxxx`)

변경 감지:
- `existing[id].content_hash == 새 content_hash` 이면 → 기존 항목 재사용 (fence 위치만 업데이트)
- 다르거나 새로운 id면 → .mermaid 파일 새로 Write

파일 저장 위치: `diagrams/{doc_stem}/{id}.mermaid`

status 결정:
- `diagrams/{doc_stem}/{id}.drawio.svg` 존재 → `"exported"`
- `diagrams/{doc_stem}/{id}.drawio` 존재 → `"drawio_ready"`
- 없으면 → `"extracted"`

### 5. manifest.json 작성

```json
{
  "version": "2.0",
  "docs_dir": "docs/",
  "total_diagrams": N,
  "diagrams": [
    {
      "id": "modules_arch_01",
      "source_file": "modules/arch.md",
      "fence_start": 14,
      "fence_end": 21,
      "content_hash": "sha256:abcd1234efgh5678",
      "title": "System Architecture",
      "status": "extracted",
      "mermaid_path": "modules_arch/modules_arch_01.mermaid",
      "drawio_path":  "modules_arch/modules_arch_01.drawio",
      "svg_path": null
    }
  ]
}
```

`fence_start`, `fence_end`는 **0-based** 줄 번호.
`svg_path`는 exported 상태면 상대경로, 아니면 null.

### 6. 완료 리포트 출력

```
추출 완료
─────────────────────────────────
docs/modules/arch.md
  [extracted    ] modules_arch_01 — System Architecture
  [drawio_ready ] modules_arch_02 — Sequence Flow

새로 추출: 2 / 변경없음: 3 / 전체: 5
─────────────────────────────────
다음: generator 에이전트에게 .drawio 생성 요청
  → "status가 extracted인 .mermaid 파일들 .drawio로 만들어줘"
```

## 주의사항

- ```` ```mermaid ```` 로 시작하는 줄만 인식 (````mermaid` 등 중첩 펜스 무시)
- 이미 `<!-- mermaid-source:` 주석으로 교체된 블록은 스캔하지 않음
- fence_start와 fence_end는 항상 0-based 정수로 저장
