"""Gemini Review MCP Server.

Provides 6 tools for Claude-Codex-Gemini collaboration:
1. gemini_summarize_design_pack — Compress design docs into implementation-ready summary
2. gemini_derive_contract — Generate contract.md draft from design summary
3. gemini_audit_implementation — Neutral audit of code against contract
4. gemini_compare_diffs — Cross-compare multiple branch diffs
5. gemini_draft_release_notes — Generate release notes from work items
6. gemini_polish_career_doc — Polish career documents for natural, authentic tone

Usage:
    GEMINI_API_KEY=... uv run python server.py
"""

import asyncio
import os
import subprocess
from pathlib import Path

import google.generativeai as genai
from mcp.server import Server
from mcp.server.stdio import stdio_server

# ── Configuration ─────────────────────────────────────────────────────────

MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-pro")
API_KEY = os.environ.get("GEMINI_API_KEY", "")

if not API_KEY:
    raise EnvironmentError(
        "GEMINI_API_KEY environment variable is required. "
        "Set it before starting the server."
    )

genai.configure(api_key=API_KEY)

server = Server("gemini-review")


# ── Helpers ───────────────────────────────────────────────────────────────

def _read_files(paths: list[str]) -> str:
    """Read multiple files and return concatenated content with headers."""
    parts = []
    for p in paths:
        path = Path(p)
        if not path.exists():
            parts.append(f"--- {p} (NOT FOUND) ---\n")
            continue
        content = path.read_text(encoding="utf-8", errors="replace")
        parts.append(f"--- {p} ---\n{content}\n")
    return "\n".join(parts)


def _git_diff(branch: str) -> str:
    """Get diff of a branch against main."""
    try:
        result = subprocess.run(
            ["git", "diff", f"main...{branch}", "--stat", "--patch"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.stdout or f"(no diff for {branch})"
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return f"(failed to get diff for {branch})"


def _collect_work_item(feat_id: str) -> str:
    """Read all files from a work item directory."""
    work_dir = None
    items_dir = Path("work/items")
    if items_dir.exists():
        for d in items_dir.iterdir():
            if d.is_dir() and feat_id in d.name:
                work_dir = d
                break

    if work_dir is None:
        return f"(work item {feat_id} not found)"

    parts = []
    for f in sorted(work_dir.iterdir()):
        if f.is_file() and f.suffix == ".md":
            content = f.read_text(encoding="utf-8", errors="replace")
            parts.append(f"--- {f} ---\n{content}\n")
    return "\n".join(parts)


async def _call_gemini(system_prompt: str, user_content: str) -> str:
    """Call Gemini API with system prompt and user content."""
    model = genai.GenerativeModel(
        model_name=MODEL,
        system_instruction=system_prompt,
    )
    response = await asyncio.to_thread(
        model.generate_content, user_content
    )
    return response.text


# ── Tools ─────────────────────────────────────────────────────────────────

@server.tool()
async def gemini_summarize_design_pack(file_paths: list[str]) -> str:
    """Compress multiple design documents (RFC, ADR, references) into an
    implementation-ready summary. Returns: valid decisions, conflicts,
    invariants, open questions."""
    from prompts import SUMMARIZE_DESIGN_PACK

    content = _read_files(file_paths)
    if not content.strip():
        return "Error: No readable files provided."

    return await _call_gemini(
        SUMMARIZE_DESIGN_PACK,
        f"Analyze these design documents:\n\n{content}",
    )


@server.tool()
async def gemini_derive_contract(
    design_summary: str,
    scope: str,
    boundaries: str,
) -> str:
    """Generate a contract.md draft from a design summary. The contract
    defines interfaces, allowed/forbidden boundaries, invariants, and test
    requirements. Output is always status: draft — Claude must review."""
    from prompts import DERIVE_CONTRACT

    user_content = (
        f"## Design Summary\n{design_summary}\n\n"
        f"## Scope\n{scope}\n\n"
        f"## Boundaries\n{boundaries}"
    )
    return await _call_gemini(DERIVE_CONTRACT, user_content)


@server.tool()
async def gemini_audit_implementation(
    contract_path: str,
    changed_files: list[str],
    checklist_path: str,
) -> str:
    """Neutral third-party audit of implementation against contract and
    checklist. Returns compliance table, boundary violations, edge cases,
    and risk assessment. Does NOT suggest code changes."""
    from prompts import AUDIT_IMPLEMENTATION

    contract = _read_files([contract_path])
    checklist = _read_files([checklist_path])
    code = _read_files(changed_files)

    user_content = (
        f"## Contract\n{contract}\n\n"
        f"## Checklist\n{checklist}\n\n"
        f"## Implementation Code\n{code}"
    )
    return await _call_gemini(AUDIT_IMPLEMENTATION, user_content)


@server.tool()
async def gemini_compare_diffs(branches: list[str]) -> str:
    """Cross-compare diffs from multiple feature branches. Identifies
    common logic, potential conflicts, recommended integration order,
    and convention violations."""
    from prompts import COMPARE_DIFFS

    diffs = []
    for branch in branches:
        diff = _git_diff(branch)
        diffs.append(f"## Branch: {branch}\n{diff}\n")

    return await _call_gemini(
        COMPARE_DIFFS,
        f"Compare these branch diffs:\n\n{''.join(diffs)}",
    )


@server.tool()
async def gemini_draft_release_notes(
    feat_ids: list[str],
    include_migration: bool = True,
) -> str:
    """Generate release notes from completed work items. Reads work item
    files, diffs, and reviews to produce user-facing release documentation
    including breaking changes and migration steps."""
    from prompts import DRAFT_RELEASE_NOTES

    parts = []
    for feat_id in feat_ids:
        item = _collect_work_item(feat_id)
        parts.append(f"## Work Item: {feat_id}\n{item}\n")

        # Try to get branch diff
        items_dir = Path("work/items")
        if items_dir.exists():
            for d in items_dir.iterdir():
                if d.is_dir() and feat_id in d.name:
                    diff = _git_diff(f"feat/{d.name}")
                    parts.append(f"## Diff: feat/{d.name}\n{diff}\n")
                    break

    migration_note = (
        "\nInclude detailed migration guide."
        if include_migration
        else "\nSkip migration guide."
    )

    return await _call_gemini(
        DRAFT_RELEASE_NOTES,
        f"Generate release notes from:\n\n{''.join(parts)}{migration_note}",
    )


@server.tool()
async def gemini_polish_career_doc(
    document: str,
    doc_type: str,
    char_limit: int = 0,
) -> str:
    """Polish a refined career document for natural, authentic tone.
    Takes a pre-refined draft and smooths it to read like a genuine career
    document — not AI-generated text. Preserves all facts and structure.

    Args:
        document: The refined document text to polish.
        doc_type: One of: cover-letter, career-desc, portfolio, cover-letter-en, hr-essay.
        char_limit: Character limit including spaces (0 = no limit).
    """
    from prompts import POLISH_CAREER_DOC

    limit_note = (
        f"\n\nCharacter limit: {char_limit}자 (spaces included). Do NOT exceed this."
        if char_limit > 0
        else ""
    )

    user_content = (
        f"## Document Type\n{doc_type}\n\n"
        f"## Document to Polish\n{document}"
        f"{limit_note}"
    )
    return await _call_gemini(POLISH_CAREER_DOC, user_content)


# ── Main ──────────────────────────────────────────────────────────────────

async def _run():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream)


def main():
    asyncio.run(_run())


if __name__ == "__main__":
    main()
