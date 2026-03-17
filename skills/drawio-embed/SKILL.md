---
name: drawio-embed
description: Embed edited draw.io diagrams back into Markdown docs, replacing mermaid code blocks with SVG image references. Use this skill when the user has finished editing .drawio files in Cursor and wants to put them back into docs, or says "embed diagrams", "replace mermaid with SVG", "put diagrams back", "update docs with diagrams", "drawio to docs". This is Phase 2 of the mermaid-extract → drawio-embed pipeline. Also use when the user wants to export .drawio to SVG and update markdown files.
---

# draw.io Embed — Phase 2: .drawio → SVG → Docs

Take edited `.drawio` files, export to SVG, and replace mermaid blocks in Markdown.

## Cursor workflow

The user has been editing `.drawio` files in Cursor with the `hediet.vscode-drawio` extension. Now they want to:
1. Export each `.drawio` to `.drawio.svg`
2. Replace the original ```` ```mermaid ```` blocks with `![title](path.svg)` references

## Step 1 — Export .drawio to .drawio.svg

In Cursor with the draw.io extension, for each `.drawio` file:

1. Open the `.drawio` file (visual editor appears)
2. Click the tab title → select **"Convert To..."** → choose **"drawio.svg"**
3. This creates a `.drawio.svg` that is both valid SVG and editable in Cursor

Or if the user prefers to keep `.drawio` and export separately:
- In the visual editor toolbar: click **Export** icon → **SVG**
- Save as `{id}.drawio.svg` in the same directory

### Batch conversion helper

If there are many files, Claude can help by reading each `.drawio` XML and generating a basic SVG rendering. This won't be as pretty as the draw.io export, but works when the extension's export isn't practical.

For best quality, always prefer the extension's built-in export.

### Checking export status

```bash
python <this-skill>/scripts/reinsert_svg.py \
  --docs-dir docs/ --diagrams-dir diagrams/ --dry-run
```

This shows which diagrams have SVGs ready and which still need export.

## Step 2 — Replace mermaid blocks

```bash
python <this-skill>/scripts/reinsert_svg.py \
  --docs-dir docs/ \
  --diagrams-dir diagrams/ \
  [--assets-dir docs/assets/diagrams/] \
  [--keep-mermaid] \
  [--dry-run]
```

### What it does

1. Reads `manifest.json` for diagram → file mappings
2. For each diagram with a `.drawio.svg`:
   - Copies SVG to docs assets directory (`docs/assets/diagrams/`)
   - Replaces the ```` ```mermaid ... ``` ```` block with `![title](relative/path.svg)`
   - Preserves original mermaid as HTML comment (default, `--no-keep-mermaid` to skip)
3. Skips diagrams without SVGs

### Before / After

**Before:**
````markdown
### 시스템 아키텍처

```mermaid
flowchart LR
    A --> B --> C
```
````

**After:**
```markdown
### 시스템 아키텍처

<!-- mermaid-source: index_01
flowchart LR
    A --> B --> C
-->
![시스템 아키텍처](assets/diagrams/index_01.drawio.svg)
```

### CLI options

| Flag | Default | Description |
|------|---------|-------------|
| `--docs-dir` | `.` | Markdown files location |
| `--diagrams-dir` | `diagrams/` | manifest.json and SVGs |
| `--assets-dir` | auto | Where to copy SVGs (auto-detects MkDocs) |
| `--keep-mermaid` | `true` | Preserve mermaid as HTML comment |
| `--no-keep-mermaid` | | Omit mermaid preservation |
| `--dry-run` | | Preview without writing |
| `--only` | all | Comma-separated diagram IDs |

### Asset directory auto-detection

If `mkdocs.yml` exists nearby, SVGs go to `docs/assets/diagrams/`. Image paths in markdown are calculated as relative paths from each `.md` file.

## Step 3 — Verify

```bash
# Check the git diff
git diff docs/

# Preview in MkDocs
mkdocs serve
```

### MkDocs dark mode (optional)

SVGs with transparent backgrounds work in both themes. If colors look off in dark mode:

```css
/* docs/assets/stylesheets/custom.css */
[data-md-color-scheme="slate"] img[src*="drawio"] {
  filter: invert(0.88) hue-rotate(180deg);
}
```

## Selective processing

```bash
# Only specific diagrams
python scripts/reinsert_svg.py --only index_01,agents_01 --docs-dir docs/ --diagrams-dir diagrams/

# Preview first
python scripts/reinsert_svg.py --dry-run --docs-dir docs/ --diagrams-dir diagrams/
```

## Updating diagrams later

1. Open the `.drawio` (or `.drawio.svg`) in Cursor
2. Edit in the visual editor
3. Re-export to SVG
4. Run `reinsert_svg.py` again (updates the SVG in docs assets)

## File organization

```
project/
├── docs/
│   ├── assets/diagrams/          ← SVGs served by MkDocs (commit these)
│   │   ├── index_01.drawio.svg
│   │   └── agents_01.drawio.svg
│   ├── index.md                  ← mermaid → ![img] replaced
│   └── agents.md
├── diagrams/                     ← working directory (commit these too)
│   ├── manifest.json
│   ├── index/
│   │   ├── index_01.mermaid      ← original mermaid
│   │   ├── index_01.drawio       ← editable source (Cursor)
│   │   └── index_01.drawio.svg   ← exported SVG
│   └── agents/
│       └── ...
```

### What to commit

| Path | Commit | Why |
|------|--------|-----|
| `docs/assets/diagrams/*.svg` | **Yes** | Final output for docs site |
| `diagrams/*.drawio` | **Yes** | Editable source of truth |
| `diagrams/*.mermaid` | **Yes** | Original mermaid backup |
| `diagrams/manifest.json` | **Yes** | Tracks diagram ↔ file mapping |
