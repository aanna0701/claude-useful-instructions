# SVG Diagram Rules — Hand-Authored SVG Authoring Rules

Mandatory reference when generating **SVG** (as opposed to Mermaid) diagrams. Use SVG instead of Mermaid when:

- The docs container width is constrained and Mermaid auto-layout overflows horizontally.
- The user explicitly asks for an image / static asset.
- The diagram has more than ~12 nodes with multi-target routing and Mermaid produces tangled edges.
- The diagram will be embedded in HTML / Markdown via `<img src="...">`.

---

## 1. Coordinate Discipline

Plan the layout on paper or a comment block **before** writing any `<path>`. Assign:

- A **canvas viewBox** sized for the docs container (e.g. `920 × 720` for ~880 px content area).
- A **grid** of node coordinates with explicit `x`, `y`, `width`, `height`.
- A list of **reserved channels** (vertical lanes and horizontal trunks) for edges. Each lane has a single x or y value and a documented purpose.

Example channel plan (write as an SVG comment):

```svg
<!-- Channels:
     x=600  vertical: frame_sync→runner (y 225-320), Stage2→Triton (y 370-510)
     x=650  vertical: vas_client→VasSys return loop (y 145-490)
     y=170  horizontal trunk: VasSys→frame_sync TCP (x 410-600)
     y=425  horizontal trunk: text_augmentation→Stage1 (x 160-540) -->
```

A channel may host more than one edge **only if their y / x ranges do not overlap**.

---

## 2. Orthogonal Edges Only

All edges must be polyline paths with **right-angle bends only**. No diagonals.

```svg
<!-- ✅ -->
<path d="M 280 250 L 280 285 L 130 285 L 130 320" marker-end="url(#arrow)"/>

<!-- ❌ -->
<path d="M 280 250 L 130 320" marker-end="url(#arrow)"/>
```

Acceptable forms: `L` (horizontal/vertical), `M` (move). Avoid `C` (curve) unless explicitly representing async / fall-back semantics with a different stroke style.

---

## 3. No Box Overlap

Every edge segment must lie in **empty corridor space**, not inside any node bounding box other than its own start and end nodes. Before committing a path:

1. Compute each segment endpoint.
2. For every other node bounding box `[x, x+w] × [y, y+h]`, check the segment does **not** intersect the interior.
3. If it does, reroute via a different channel (usually shifting the lane outward into the gap between subgraphs).

Common offenders:

- A "shortest" L-route that cuts through a sibling box on the way to its target.
- A vertical lane placed inside a subgraph's content area instead of in the corridor between subgraphs.

When two subgraphs have rectangles `A: x=20-640` and `B: x=660-900`, the safe vertical channel is `x=650`. Using `x=600` (inside A) risks overlapping nodes inside A.

---

## 4. No Title / Label Overlap

Group titles (subgraph headers) and edge labels are text and must not collide with each other or with path lines.

Rules:

- Place group titles **inside their subgraph header strip** (typically `y = subgraph_y + 20`), centered with `text-anchor="middle"`.
- Edge labels go on **clear space adjacent to a single segment**, not at corners where two segments meet.
- If an edge passes near a group title, route the edge so its label is at least **16 px** from any title text.
- For labels that must sit on top of a busy area, add a faint background:

```svg
<rect x="LABEL_X-4" y="LABEL_Y-12" width="LABEL_W+8" height="14" fill="white" fill-opacity="0.85"/>
<text class="lbl-edge" x="LABEL_X" y="LABEL_Y">protocol</text>
```

---

## 5. Color and Weight

Maintain the same 3-4 color palette as Mermaid rules. SVG-specific weight tuning:

| Element       | Stroke / fill                                | Font size | Weight |
|---------------|----------------------------------------------|-----------|--------|
| Node border   | `stroke-width: 1.5`, palette stroke          | —         | —      |
| Edge          | `stroke: #555`, `stroke-width: 1.4`          | —         | —      |
| Node title    | fill `#1f2937`                               | 13 px     | 600    |
| Sub-text      | fill `#6b7280`                               | 11 px     | 400    |
| Edge label    | fill `#4b5563`                               | 11 px     | 400    |
| Group title   | fill `#444`, letter-spacing 0.5 px           | 12 px     | 600    |

If an edge label sits on or near a colored fill, switch its fill to a darker shade to keep ≥4.5:1 contrast against the background. Never use the same color for an edge and a label that touches it.

---

## 6. Markers (Arrowheads)

Define one shared marker in `<defs>` and reuse:

```svg
<defs>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
          markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="#555"/>
  </marker>
</defs>
```

`refX="9"` ensures the arrow tip sits exactly on the target edge. If the arrow visually overshoots a node border, increase `refX` to 10–11.

---

## 7. Subgraph Backgrounds

Use a soft fill plus dashed border so groups read as containers without competing with node colors:

```svg
.grp { fill: #fafafa; stroke: #d1d5db; stroke-dasharray: 4 3; }
```

Draw all subgraph backgrounds **first**, then nodes, then edges, then labels, so z-order is correct.

---

## 8. Embedding and Responsive Width

When the SVG is embedded in Markdown via `![](/path.svg)`, the rendered width follows the container. On 4K monitors with adaptive page width, an unconstrained SVG becomes oversized.

Apply a `max-width` cap in site CSS:

```css
.sl-markdown-content img[src*="/diagrams/"] {
  max-width: min(100%, 56rem);
  display: block;
  margin-inline: auto;
}
```

`56rem` (~896 px) keeps a `920` viewBox at near-native scale on wide screens while still shrinking on narrow ones.

Alternatively, set explicit width on the `<img>` tag:

```html
<img src="/diagrams/foo.svg" alt="..." style="max-width: 920px; width: 100%;" />
```

---

## 9. SVG Output Checklist

Before declaring an SVG done, verify:

- [ ] All paths use only `M` and orthogonal `L` commands.
- [ ] No path segment intersects an unrelated node's bounding box.
- [ ] Group titles are centered with `text-anchor="middle"` and inside their subgraph header strip.
- [ ] Every edge label is in clear space (no overlap with paths, titles, or other labels).
- [ ] Color palette ≤ 4 colors; legend present.
- [ ] Arrow marker tips land on node edges (no overshoot, no gap).
- [ ] A `max-width` rule constrains the rendered size on wide monitors.

A single overlap is a validation failure. Reroute via an unused channel and re-check.
