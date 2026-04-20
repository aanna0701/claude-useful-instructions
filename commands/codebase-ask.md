# codebase-ask — Ask questions about the codebase (GitNexus-backed)

Answer a question about the codebase using GitNexus MCP tools. Read-only — never edits code.

Arguments: $ARGUMENTS
- Free-form question about the codebase.
- Optional `--focus=<area>` hint (e.g., `--focus=auth`).
- Optional `--deep` to force delegation to `codebase-researcher` even for simple questions.

---

## Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- **QUESTION**: everything except `--focus=` / `--deep` flags
- **FOCUS**: value of `--focus=` if present
- **DEEP**: true if `--deep` present

If `QUESTION` is empty, ask the user what they want to know and stop.

---

## Step 2: Invoke codebase-qa skill

Dispatch to the `codebase-qa` skill with the parsed inputs. The skill handles:

1. GitNexus preflight (`list_repos`, freshness check).
2. Intent classification.
3. Direct execution for simple queries, or delegation to `codebase-researcher` agent for complex/multi-hop.
4. Evidence-based answer with `file:line` anchors.

If `DEEP=true`, the skill must force agent delegation.

---

## Step 3: Present results

Show the skill's answer to the user. If the answer references `(unverified)` symbols or a stale index, highlight that at the top of the response.

If GitNexus is not installed or not indexed:
```
GitNexus not available for this repo.
  - Install: npm install -g gitnexus
  - Register MCP: claude mcp add gitnexus -- npx -y gitnexus@latest mcp
  - Index: cd <repo> && gitnexus analyze
See README.md "GitNexus setup" section.
```
