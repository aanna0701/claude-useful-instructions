---
name: diagram-generator
description: ".mermaid 파일을 읽고 draw.io XML(.drawio)을 생성하는 에이전트"
tools: Read, Write, Glob
model: sonnet
---

# Generator Agent

`diagrams/`의 `.mermaid` 파일을 읽고 편집 가능한 `.drawio` 파일을 생성한다.

## 실행 순서

### 1. 대상 파악
`diagrams/manifest.json` Read → status가 `"extracted"`인 항목만 처리.
특정 id가 지정된 경우 해당 id만 처리.

### 2. 각 .mermaid 파일 Read 후 .drawio 생성

각 `{mermaid_path}`를 Read하고 아래 규칙에 따라 `.drawio` XML을 작성.

---

## .drawio XML 생성 규칙

### 파일 골격

```xml
<mxGraphModel dx="1422" dy="762" grid="1" gridSize="10" guides="1"
              tooltips="1" connect="1" arrows="1" fold="1" page="1"
              pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- 노드와 엣지 여기에 -->
  </root>
</mxGraphModel>
```

### 노드 스타일

| mermaid 문법 | draw.io style |
|-------------|--------------|
| `A[text]` | `rounded=1;whiteSpace=wrap;html=1;arcSize=10;` |
| `A{text}` | `rhombus;whiteSpace=wrap;html=1;` |
| `A(text)` | `rounded=1;whiteSpace=wrap;html=1;arcSize=50;` |
| `A[(text)]` | `shape=cylinder3;whiteSpace=wrap;html=1;` |
| `A((text))` | `ellipse;whiteSpace=wrap;html=1;` |

노드 기본 크기: `width="160" height="60"`. 텍스트가 길면 width 늘릴 것.

### 노드 셀 형식

```xml
<mxCell id="A" value="텍스트" style="rounded=1;whiteSpace=wrap;html=1;arcSize=10;"
        vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="160" height="60" as="geometry"/>
</mxCell>
```

### 엣지 — mxGeometry 자식 필수, self-close 금지

```xml
<!-- ✅ 올바름 -->
<mxCell id="e1" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=1;"
        edge="1" source="A" target="B" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>

<!-- ❌ 틀림: self-close → draw.io가 렌더링 못 함 -->
<mxCell id="e1" edge="1" source="A" target="B" parent="1"/>
```

label 없는 엣지도 `value=""` 명시.
label 있는 엣지: `value="label 텍스트"`.

### 레이아웃

- **flowchart LR**: x = col × 220, y = row × 100
- **flowchart TD/TB**: x = col × 200, y = row × 120
- 노드 간격 최소 60px
- x, y, width, height 모두 10의 배수로 그리드 정렬

### subgraph → swimlane container

```xml
<!-- container 먼저 -->
<mxCell id="sg1" value="Subgraph 제목"
        style="swimlane;startSize=30;fillColor=#dae8fc;strokeColor=#6c8ebf;rounded=1;"
        vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="360" height="220" as="geometry"/>
</mxCell>

<!-- 자식 노드: parent="sg1", 좌표는 container 안 상대좌표 -->
<mxCell id="n1" value="Node A" style="rounded=1;whiteSpace=wrap;html=1;"
        vertex="1" parent="sg1">
  <mxGeometry x="20" y="50" width="160" height="60" as="geometry"/>
</mxCell>
```

### style 지시문 처리

```
style NODE fill:#1e3a5f,stroke:#4a9eff,color:#ffffff
→ 해당 노드 style에 fillColor=#1e3a5f;strokeColor=#4a9eff;fontColor=#ffffff; 추가
```

### 무시할 줄

`%%`, `classDef`, `click`, `linkStyle` 로 시작하는 줄은 무시.

### XML 주의사항

- XML 주석(`<!-- -->`) 안에 `--` 사용 금지 (XML 파싱 오류)
- 모든 `value` 속성에서 `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`

---

### 3. 파일 저장

`diagrams/{drawio_path}` 경로에 Write.

### 4. manifest 업데이트

생성된 항목의 status를 `"drawio_ready"`로 업데이트 후 manifest.json Write.

### 5. 완료 리포트

```
.drawio 생성 완료
─────────────────────────────────
  ✅ modules_arch_01.drawio  (노드 5개, 엣지 4개)
  ✅ modules_arch_02.drawio  (노드 3개, 엣지 2개)
─────────────────────────────────
다음: Cursor에서 .drawio 파일 열어 편집 후
  탭 우클릭 → Convert To... → drawio.svg
  완료되면 "docs에 넣어줘"라고 말하기
```
