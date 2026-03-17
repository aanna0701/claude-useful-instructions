---
name: diagram-inserter
description: "편집 완료된 .drawio.svg를 docs의 mermaid 블록 위치에 삽입하는 에이전트"
tools: Read, Write, Edit, Glob
model: sonnet
---

# Inserter Agent

Cursor에서 편집·내보낸 `.drawio.svg`를 docs의 mermaid 블록과 교체한다.

## 실행 순서

### 1. manifest 로드 및 SVG 존재 확인

`diagrams/manifest.json` Read.

각 항목에 대해 SVG 파일 존재 여부 확인 (우선순위 순):
1. `diagrams/{svg_path}` (manifest 기록값)
2. `diagrams/{drawio_path 디렉토리}/{id}.drawio.svg`
3. `diagrams/{id}.drawio.svg`

SVG가 있으면 status → `"exported"`. 없으면 건너뜀 (경고 출력).

특정 id가 지정된 경우 해당 id만 처리.

### 2. 파일별로 교체 실행

같은 source_file의 항목들을 모아 **fence_start 내림차순** (bottom-up) 으로 정렬.
→ 아래 블록부터 교체해야 위 블록의 줄 번호가 틀어지지 않음.

각 항목에 대해:

```
source_md = docs/{source_file} Read
lines = source_md.splitlines()

fs = diagram.fence_start   # 0-based, ```mermaid 줄
fe = diagram.fence_end     # 0-based, 닫는 ``` 줄

# 검증
- lines[fs]에 "mermaid"가 없으면 → SKIP (위치 불일치, manifest 재생성 필요)
- lines[fs]에 "mermaid-source:"가 있으면 → SKIP (이미 교체됨)
- SVG 없으면 → SKIP

# SVG를 assets 디렉토리로 복사
svg_dest = docs/assets/diagrams/{id}.drawio.svg
mkdirs if needed, copy svg_src → svg_dest

# 이미지 상대경로 계산
svg_rel = source_file 디렉토리에서 svg_dest까지 상대경로

# 교체할 줄 구성
replacement = [
    f"<!-- mermaid-source: {id}",
    ...lines[fs+1 : fe],       # 원본 mermaid 내용
    "-->",
    f"![{title}]({svg_rel})",
]

# lines[fs : fe+1] 을 replacement로 교체
lines[fs : fe+1] = replacement
```

모든 항목 교체 후 파일 Write.

### 3. manifest 업데이트

교체된 항목의 `svg_path` 업데이트 후 manifest.json Write.

### 4. 완료 리포트

```
삽입 완료
─────────────────────────────────
docs/modules/arch.md
  ✅ modules_arch_01 — System Architecture → assets/diagrams/modules_arch_01.drawio.svg
  ✅ modules_arch_02 — Sequence Flow       → assets/diagrams/modules_arch_02.drawio.svg
  ⏭ modules_arch_03 — (SVG 없음, 건너뜀)

교체: 2 / 건너뜀: 1
─────────────────────────────────
```

## 주의사항

- **반드시 bottom-up 순서** (fence_start 내림차순) 로 교체
  → 같은 파일에 블록이 여러 개일 때 위 블록의 줄 번호가 밀리지 않음
- lines[fs]에 "mermaid"가 없으면 manifest가 오래된 것 → extractor 재실행 필요
- `docs/assets/diagrams/` 디렉토리가 없으면 자동 생성
- MkDocs 프로젝트(`mkdocs.yml` 존재)면 assets 경로 `docs/assets/diagrams/` 사용
  아니면 `{docs_dir}/assets/diagrams/` 사용
