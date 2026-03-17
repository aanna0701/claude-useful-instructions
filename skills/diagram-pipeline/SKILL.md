---
name: diagram-pipeline
description: >
  Markdown 문서의 mermaid 다이어그램을 draw.io로 변환하고, Cursor에서 편집 후
  다시 docs에 삽입하는 end-to-end 파이프라인 스킬.
  "mermaid를 drawio로", "다이어그램 예쁘게", "drawio 변환", "diagram pipeline",
  "mermaid extract", "drawio embed", "다이어그램 docs에 넣어줘",
  "mermaid to svg", "다이어그램 편집" 등의 요청에 트리거.
---

# Diagram Pipeline

```
Phase 1: extract   →   Phase 2: generate   →   Phase 3: 사용자 편집   →   Phase 4: insert
(extractor 에이전트)   (generator 에이전트)    (Cursor에서 시각 편집)    (inserter 에이전트)
```

---

## 전체 흐름

### Phase 1 — mermaid 추출
`extractor` 에이전트에게 위임:
> "docs/ 안의 mermaid 블록을 모두 찾아서 diagrams/에 추출하고 manifest.json을 만들어줘"

완료되면 `diagrams/manifest.json`과 각 `.mermaid` 파일이 생긴다.

### Phase 2 — .drawio 생성
`generator` 에이전트에게 위임:
> "diagrams/ 안의 .mermaid 파일들을 읽고 각각 .drawio 파일을 만들어줘"

완료되면 각 `.drawio` 파일이 생긴다.

### Phase 3 — 사용자가 Cursor에서 편집
사용자에게 안내:
```
1. hediet.vscode-drawio 확장이 없으면 설치
2. diagrams/ 안의 .drawio 파일 클릭 → 비주얼 에디터 오픈
3. 노드 배치, 색상, 레이아웃 조정 후 Ctrl+S
4. 탭 우클릭 → Convert To... → drawio.svg
5. 편집 완료되면 "다이어그램 docs에 넣어줘"라고 말하기
```

### Phase 4 — docs에 재삽입
`inserter` 에이전트에게 위임:
> "diagrams/ 안의 .drawio.svg 파일들을 docs에 삽입해줘"

---

## 부분 실행

| 요청 | 위임 |
|------|------|
| "mermaid 추출만 해줘" | extractor만 |
| "drawio 파일 만들어줘" | generator만 |
| "docs에 넣어줘" / "삽입해줘" | inserter만 |
| "처음부터 끝까지" | Phase 1→2 실행 후 사용자에게 Phase 3 안내 |

---

## 나중에 다이어그램 수정할 때

mermaid 원본이 바뀐 경우:
> "extractor 다시 실행해줘" → 변경된 것만 재추출 → generator로 재생성

SVG만 다시 교체하고 싶은 경우:
> "index_01만 docs에 다시 넣어줘" → inserter에게 id 지정해서 위임
