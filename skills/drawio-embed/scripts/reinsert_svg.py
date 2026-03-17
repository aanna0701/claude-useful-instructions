#!/usr/bin/env python3
"""
reinsert_svg.py — Replace mermaid blocks in markdown with SVG image references.

Reads manifest.json, finds diagrams with exported SVGs (.drawio.svg),
replaces ```mermaid blocks with ![title](path/to/svg).

Usage:
    python scripts/reinsert_svg.py --docs-dir docs/ --diagrams-dir diagrams/
    python scripts/reinsert_svg.py --docs-dir docs/ --diagrams-dir diagrams/ --dry-run
"""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path


def detect_assets_dir(docs_dir: Path) -> Path:
    """Auto-detect assets directory. Checks for MkDocs project structure."""
    for candidate in [docs_dir.parent / "mkdocs.yml", docs_dir / "mkdocs.yml"]:
        if candidate.exists():
            return docs_dir / "assets" / "diagrams"
    return docs_dir / "assets" / "diagrams"


def relative_path_from(source: Path, target: Path) -> str:
    """Calculate relative path from source file's directory to target file."""
    try:
        return os.path.relpath(target, source.parent).replace("\\", "/")
    except ValueError:
        return str(target).replace("\\", "/")


def find_svg_for_diagram(diagram: dict, diagrams_dir: Path) -> Path | None:
    """Find the .drawio.svg file for a diagram, checking multiple locations."""
    candidates = []

    # From manifest svg_path
    if diagram.get("svg_path"):
        candidates.append(diagrams_dir / diagram["svg_path"])

    # Standard locations
    did = diagram["id"]
    drawio_path = diagram.get("drawio_path", "")
    stem = drawio_path.rsplit("/", 1)[0] if "/" in drawio_path else ""

    if stem:
        candidates.append(diagrams_dir / stem / f"{did}.drawio.svg")
    candidates.append(diagrams_dir / f"{did}.drawio.svg")

    for p in candidates:
        if p.exists():
            return p
    return None


def process_file(
    md_path: Path,
    docs_dir: Path,
    diagrams: list[dict],
    diagrams_dir: Path,
    assets_dir: Path,
    keep_mermaid: bool,
    dry_run: bool,
) -> tuple[int, list[str]]:
    """Process one markdown file, replacing mermaid blocks with SVG refs."""
    lines = md_path.read_text(encoding="utf-8").split("\n")
    msgs = []
    replaced = 0

    # Process from bottom to top to preserve line numbers
    for diagram in sorted(diagrams, key=lambda d: d["line_start"], reverse=True):
        svg_src = find_svg_for_diagram(diagram, diagrams_dir)
        if not svg_src:
            msgs.append(f"  SKIP {diagram['id']}: no .drawio.svg found")
            continue

        si = diagram["line_start"] - 1  # 0-based
        ei = diagram["line_end"] - 1

        if si < 0 or ei >= len(lines):
            msgs.append(f"  SKIP {diagram['id']}: line range out of bounds")
            continue

        # Check it's still a mermaid block (not already converted)
        if "mermaid-source" in lines[si]:
            msgs.append(f"  SKIP {diagram['id']}: already converted")
            continue
        if "mermaid" not in lines[si]:
            msgs.append(f"  SKIP {diagram['id']}: line {diagram['line_start']} not a mermaid block")
            continue

        mermaid_content = "\n".join(lines[si + 1 : ei])

        svg_dest = assets_dir / f"{diagram['id']}.drawio.svg"
        if not dry_run:
            svg_dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(svg_src, svg_dest)

        svg_rel = relative_path_from(md_path, svg_dest)
        title = diagram.get("title") or diagram["id"]

        parts = []
        if keep_mermaid:
            parts.append(f"<!-- mermaid-source: {diagram['id']}")
            parts.append(mermaid_content)
            parts.append("-->")
        parts.append(f"![{title}]({svg_rel})")

        lines[si : ei + 1] = "\n".join(parts).split("\n")
        replaced += 1
        msgs.append(f"  DONE {diagram['id']}: → {svg_rel}")

    if replaced > 0 and not dry_run:
        md_path.write_text("\n".join(lines), encoding="utf-8")

    return replaced, msgs


def main():
    parser = argparse.ArgumentParser(
        description="Replace mermaid blocks with SVG image references"
    )
    parser.add_argument("--docs-dir", type=Path, default=Path("."))
    parser.add_argument("--diagrams-dir", type=Path, default=Path("diagrams"))
    parser.add_argument("--assets-dir", type=Path, default=None)
    parser.add_argument("--keep-mermaid", action="store_true", default=True)
    parser.add_argument("--no-keep-mermaid", action="store_false", dest="keep_mermaid")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--only", type=str, default=None)
    args = parser.parse_args()

    docs_dir = args.docs_dir.resolve()
    diagrams_dir = args.diagrams_dir.resolve()
    manifest_path = diagrams_dir / "manifest.json"

    if not manifest_path.exists():
        print(f"Error: {manifest_path} not found.", file=sys.stderr)
        print("Run extract_mermaid.py first.", file=sys.stderr)
        sys.exit(1)

    manifest = json.loads(manifest_path.read_text())
    all_diagrams = manifest["diagrams"]

    if args.only:
        ids = set(args.only.split(","))
        all_diagrams = [d for d in all_diagrams if d["id"] in ids]

    # Update status based on actual SVG existence
    for d in all_diagrams:
        svg = find_svg_for_diagram(d, diagrams_dir)
        if svg:
            d["status"] = "exported"
            d["svg_path"] = str(svg.relative_to(diagrams_dir))

    assets_dir = (
        args.assets_dir.resolve() if args.assets_dir else detect_assets_dir(docs_dir)
    )

    if args.dry_run:
        print("=== DRY RUN ===\n")

    exported = sum(1 for d in all_diagrams if d["status"] == "exported")
    pending = len(all_diagrams) - exported

    print(f"Docs:     {docs_dir}")
    print(f"Diagrams: {diagrams_dir}")
    print(f"Assets:   {assets_dir}")
    print(f"Ready:    {exported}/{len(all_diagrams)} ({pending} need SVG export)\n")

    if pending > 0:
        print("Missing SVGs:")
        for d in all_diagrams:
            if d["status"] != "exported":
                print(f"  {d['id']}: open diagrams/{d['drawio_path']} in Cursor → Convert To → drawio.svg")
        print()

    by_file: dict[str, list] = {}
    for d in all_diagrams:
        by_file.setdefault(d["source_file"], []).append(d)

    total_r = total_s = 0
    for src, ds in sorted(by_file.items()):
        md = docs_dir / src
        if not md.exists():
            print(f"WARNING: {md} not found")
            continue
        print(f"{src}:")
        r, msgs = process_file(
            md, docs_dir, ds, diagrams_dir, assets_dir, args.keep_mermaid, args.dry_run
        )
        for m in msgs:
            print(m)
        total_r += r
        total_s += len(ds) - r
        print()

    print(f"Total: {total_r} replaced, {total_s} skipped")
    if args.dry_run:
        print("\n(Dry run — remove --dry-run to apply)")


if __name__ == "__main__":
    main()
