---
name: mermaid-extract
description: Extract Mermaid diagrams from Markdown docs and convert them into editable draw.io (.drawio.svg) files for Cursor. Use this skill when the user wants to convert mermaid to drawio, extract diagrams from docs for polishing, replace mermaid with prettier draw.io diagrams, or says things like "mermaid to drawio", "extract diagrams", "prettier diagrams", "improve my diagrams". This is Phase 1 of a two-skill workflow — after editing in Cursor, use drawio-embed (Phase 2) to replace the mermaid blocks.
---

# Mermaid Extract — Phase 1: Docs → .drawio.svg Files

Extract ```` ```mermaid ```` blocks from Markdown and generate `.drawio.svg` files for editing in Cursor.

## Key insight: .drawio.svg format

The `hediet.vscode-drawio` Cursor extension can edit `.drawio.svg` files directly. These files are simultaneously:
- **Valid SVG** — renderable by browsers and MkDocs
- **Editable draw.io diagrams** — double-click in Cursor opens the GUI editor

This means **no separate export step**. Edit in Cursor, save, done.

## Workflow

```
1. Run extract script → find all mermaid blocks → create manifest.json
2. Claude reads each .mermaid file → generates .drawio.svg with draw.io XML
3. User opens .drawio.svg in Cursor → visual editor appears → edit & save
4. Run drawio-embed to replace mermaid blocks with SVG image references
```

## Step 1 — Extract mermaid blocks

```bash
python <this-skill>/scripts/extract_mermaid.py \
  --docs-dir docs/ \
  --output-dir diagrams/
```

Output:
```
diagrams/
├── manifest.json
├── agents/
│   ├── agents_01.mermaid      ← raw mermaid source
│   └── agents_02.mermaid
├── index/
│   └── index_01.mermaid
└── ...
```

## Step 2 — Generate .drawio.svg files

For each `.mermaid` file, Claude should:

1. Read the mermaid source
2. Parse the diagram structure (nodes, edges, subgraphs, styles)
3. Generate draw.io XML (mxGraphModel format)
4. Wrap it in a valid SVG with embedded draw.io XML
5. Write to `diagrams/{doc_name}/{id}.drawio.svg`

### .drawio.svg file format

The file must be a valid SVG that contains draw.io diagram data. The `hediet.vscode-drawio` extension recognizes and edits this format.

The simplest approach: generate a `.drawio` XML file first, then the user can convert it by opening and saving as `.drawio.svg` in Cursor. Alternatively, generate the SVG wrapper directly.

**Option A — Generate .drawio first (simpler for Claude, user renames):**

Write the draw.io XML as `{id}.drawio`. When the user opens and saves it in Cursor with the draw.io extension, they can use "Export" or simply work with it as-is.

**Option B — Generate .drawio.svg directly (ideal):**

The `.drawio.svg` format embeds the mxGraphModel XML inside an SVG. The extension detects and renders it. The exact embedding format uses a `<svg>` wrapper with the diagram data in a specific structure that the extension reads.

**Recommended: Use Option A** — generate `.drawio` files. The Cursor draw.io extension handles `.drawio` natively, and users can export to `.drawio.svg` from the extension's menu (right-click → "Export as SVG with embedded draw.io data", or use "Convert To..." in the extension).

### draw.io XML template

```xml
<mxGraphModel dx="1422" dy="762" grid="1" gridSize="10" guides="1"
              tooltips="1" connect="1" arrows="1" fold="1" page="1"
              pageScale="1" pageWidth="1169" pageHeight="827"
              math="0" shadow="0">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- diagram content here -->
  </root>
</mxGraphModel>
```

### Mermaid → draw.io conversion rules

**Nodes:**

| Mermaid | draw.io style |
|---------|--------------|
| `A["text"]` | `rounded=1;whiteSpace=wrap;html=1;` |
| `A{"text"}` | `rhombus;whiteSpace=wrap;html=1;` |
| `A("text")` | `rounded=1;whiteSpace=wrap;html=1;arcSize=50;` |
| `A[("text")]` | `shape=cylinder3;whiteSpace=wrap;html=1;` |
| `subgraph Title` | `swimlane;startSize=30;container=1;` |

**Edges — CRITICAL: never self-close edge cells:**

```xml
<!-- CORRECT -->
<mxCell id="e1" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=1;"
        edge="1" source="a" target="b" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>

<!-- WRONG — will not render -->
<mxCell id="e1" edge="1" source="a" target="b" parent="1"/>
```

**Labeled edges:**
```xml
<mxCell id="e2" value="label text" style="edgeStyle=orthogonalEdgeStyle;"
        edge="1" source="a" target="b" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

**Style mapping (mermaid → draw.io):**
```
style NODE fill:#1e3a5f,stroke:#4a9eff,color:#e0f0ff
  → fillColor=#1e3a5f;strokeColor=#4a9eff;fontColor=#e0f0ff;
```

**Subgraphs → Swimlane containers:**
```xml
<mxCell id="sg1" value="Title" style="swimlane;startSize=30;fillColor=#dae8fc;
        strokeColor=#6c8ebf;rounded=1;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="400" height="300" as="geometry"/>
</mxCell>
<!-- Children use parent="sg1" with relative coordinates -->
<mxCell id="n1" value="Child" style="rounded=1;whiteSpace=wrap;html=1;"
        vertex="1" parent="sg1">
  <mxGeometry x="20" y="40" width="120" height="60" as="geometry"/>
</mxCell>
```

### Layout rules

- **LR flow**: x = column × 280, y = row × 120
- **TD flow**: x = column × 250, y = row × 150
- Minimum node size: 120×60
- Subgraph padding: 40px top (title), 20px sides/bottom
- Space nodes at least 200px apart
- Align to grid (multiples of 10)
- Never use `--` inside XML comments

## Step 3 — Guide the user

After generating `.drawio` files, tell the user:

```
Generated N .drawio files in diagrams/

To edit in Cursor:
  1. Install extension: hediet.vscode-drawio (if not already)
  2. Open any .drawio file → visual editor opens automatically
  3. Edit: drag nodes, change colors, adjust layout
  4. Save (Ctrl+S)
  5. To get SVG: right-click .drawio tab → "Convert To → drawio.svg"
     (or use the extension's export menu)

When done editing all diagrams, use drawio-embed to update docs.
```

## Conversion priority guide

Not all mermaid diagrams benefit equally:

| Priority | Type | Why convert |
|----------|------|-------------|
| **High** | Complex multi-subgraph | Custom layout impossible in mermaid |
| **High** | Architecture overviews | Visual polish matters for documentation |
| **Medium** | Module internals | Moderate complexity |
| **Low** | Simple 2-4 node chains | Mermaid renders these fine |

Ask the user which diagrams to convert if there are many.

## Edge cases

- **Mermaid in admonitions** (`!!! note`): strips leading indentation
- **Multiple per file**: sequential IDs (`agents_01`, `agents_02`)
- **Emoji in labels**: works in draw.io XML `value` attributes
- **`%%` directives**: strip during conversion
- **Already-converted blocks**: skip if `mermaid-source:` HTML comment found
