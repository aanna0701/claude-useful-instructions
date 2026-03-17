#!/usr/bin/env python3
"""
extract_mermaid.py — Scan markdown files for ```mermaid blocks.

Outputs:
  - {output_dir}/manifest.json         (tracking metadata)
  - {output_dir}/{doc}/{id}.mermaid    (raw mermaid source)

Usage:
    python scripts/extract_mermaid.py --docs-dir docs/ --output-dir diagrams/
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path


def extract_mermaid_blocks(md_path: Path) -> list[dict]:
    """Extract all mermaid code blocks from a markdown file."""
    lines = md_path.read_text(encoding="utf-8").split("\n")
    blocks = []
    i = 0

    while i < len(lines):
        stripped = lines[i].lstrip()
        indent = len(lines[i]) - len(stripped)

        if stripped.startswith("```mermaid"):
            line_start = i + 1  # 1-based
            mermaid_lines = []
            j = i + 1
            while j < len(lines):
                s = lines[j].lstrip()
                if s.startswith("```") and not s.startswith("````"):
                    break
                raw = lines[j]
                if indent > 0 and raw[:indent].strip() == "":
                    raw = raw[indent:]
                mermaid_lines.append(raw)
                j += 1
            line_end = j + 1  # 1-based

            # Look for preceding heading as title
            title = None
            for k in range(i - 1, max(i - 4, -1), -1):
                if k >= 0 and lines[k].strip().startswith("#"):
                    title = lines[k].strip().lstrip("#").strip()
                    break

            content = "\n".join(mermaid_lines).strip()
            if content:
                blocks.append({
                    "content": content,
                    "line_start": line_start,
                    "line_end": line_end,
                    "title": title,
                })
            i = j + 1
        else:
            i += 1
    return blocks


def doc_stem(md_path: Path, docs_dir: Path) -> str:
    """Generate identifier from path: docs/modules/docker.md → modules_docker"""
    rel = md_path.relative_to(docs_dir).with_suffix("")
    return str(rel).replace("/", "_").replace("\\", "_").replace("-", "_")


def main():
    parser = argparse.ArgumentParser(description="Extract mermaid from markdown")
    parser.add_argument("--docs-dir", type=Path, default=Path("."))
    parser.add_argument("--output-dir", type=Path, default=Path("diagrams"))
    parser.add_argument("--filter", type=str, default="**/*.md")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    docs_dir = args.docs_dir.resolve()
    output_dir = args.output_dir.resolve()
    manifest_path = output_dir / "manifest.json"

    if not docs_dir.is_dir():
        print(f"Error: {docs_dir} not found", file=sys.stderr)
        sys.exit(1)

    existing = {}
    if manifest_path.exists() and not args.force:
        existing = {
            d["id"]: d
            for d in json.loads(manifest_path.read_text())["diagrams"]
        }

    all_diagrams = []
    extracted = skipped = 0

    for md_path in sorted(docs_dir.glob(args.filter)):
        blocks = extract_mermaid_blocks(md_path)
        if not blocks:
            continue
        stem = doc_stem(md_path, docs_dir)
        doc_dir = output_dir / stem
        doc_dir.mkdir(parents=True, exist_ok=True)

        for idx, block in enumerate(blocks, 1):
            did = f"{stem}_{idx:02d}"
            mhash = "sha256:" + hashlib.sha256(
                block["content"].encode()
            ).hexdigest()[:16]

            if did in existing and existing[did].get("mermaid_hash") == mhash:
                all_diagrams.append(existing[did])
                skipped += 1
                continue

            mermaid_path = doc_dir / f"{did}.mermaid"
            mermaid_path.write_text(block["content"] + "\n", encoding="utf-8")

            # Check if drawio or svg already exists
            drawio_exists = (doc_dir / f"{did}.drawio").exists()
            svg_exists = (doc_dir / f"{did}.drawio.svg").exists()

            status = "exported" if svg_exists else (
                "drawio_ready" if drawio_exists else "extracted"
            )

            all_diagrams.append({
                "id": did,
                "source_file": str(md_path.relative_to(docs_dir)),
                "line_start": block["line_start"],
                "line_end": block["line_end"],
                "mermaid_hash": mhash,
                "title": block["title"],
                "status": status,
                "mermaid_path": f"{stem}/{did}.mermaid",
                "drawio_path": f"{stem}/{did}.drawio",
                "svg_path": f"{stem}/{did}.drawio.svg" if svg_exists else None,
            })
            extracted += 1

    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(
            {
                "version": "1.0",
                "docs_dir": str(docs_dir),
                "total_diagrams": len(all_diagrams),
                "diagrams": all_diagrams,
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n"
    )

    # Summary
    print(f"Scanned {len(list(docs_dir.glob(args.filter)))} markdown files")
    print(f"Found {len(all_diagrams)} mermaid diagrams")
    print(f"  New/changed: {extracted}")
    print(f"  Unchanged:   {skipped}")
    print(f"Manifest: {manifest_path}\n")

    by_file: dict[str, list] = {}
    for d in all_diagrams:
        by_file.setdefault(d["source_file"], []).append(d)
    for src, ds in sorted(by_file.items()):
        print(f"  {src}:")
        for d in ds:
            print(f"    {d['id']}: {d['title'] or '(untitled)'} [{d['status']}]")

    print(f"\nNext: Claude generates .drawio files from each .mermaid")
    print(f"Then: open .drawio files in Cursor (hediet.vscode-drawio extension)")


if __name__ == "__main__":
    main()
