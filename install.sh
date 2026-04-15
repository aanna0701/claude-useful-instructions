#!/usr/bin/env bash
# install.sh — Copy Claude settings (commands, agents, rules, skills) into <TARGET>/.claude/
# Skills install only to .claude/skills/ (Claude Code). No .cursor/skills or .agent/skills copies.
# Usage: ./install.sh [OPTIONS] TARGET_DIR
#   TARGET_DIR: project root to install into (REQUIRED)
#
# Options:
#   --all           Install all bundles (default if no bundle flags given)
#   --core          Core utilities (smart-git-commit-push, optimize-tokens, guard-trunk)
#   --docs          Documentation & diagrams (diataxis, write-doc, init-docs, sync-docs, doc/diagram agents)
#   --data-pipeline Data pipeline architect skill
#   --career        Career document tools (career-docs skill, career agents)
#   --dl            PyTorch DL standards + agents (capture, data, model, train, eval, infra)
#   --collab        Claude-Codex collaboration (work items, AGENTS.md, CLAUDE.md)
#   --ppt-generation PPT template-based generation (fill content into base PPT)
#   --google-style  Google C++/Python Style Guide refactor (rules, skill, command, agents, Cursor .mdc, .clang-format)
#   --exclude NAME  Exclude a bundle (repeatable, e.g. --exclude dl --exclude career)
#   --interactive   Interactive mode: choose bundles from a menu
#   --list          List available bundles and exit
#   --uninstall     Remove installed files (respects bundle flags)
#   -y, --yes       Skip confirmation prompts (e.g. work/ directory removal)
#
# Examples:
#   ./install.sh ~/proj                           # Install all bundles
#   ./install.sh --core --docs ~/proj             # Install core + docs only
#   ./install.sh --exclude career ~/proj          # Install all except career
#   ./install.sh --interactive ~/proj             # Interactive selection
#   ./install.sh --uninstall ~/proj               # Uninstall all from ~/proj
#   ./install.sh --uninstall --collab ~/proj      # Uninstall collab bundle only

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Bundle definitions ──────────────────────────────────────────────────────
# Each bundle lists its files relative to REPO_DIR.
# Format: "type:relative_path" where type is rules|commands|agents|skills|templates|...
#   cursor-command:basename.md → templates/cursor-commands/<basename> → .cursor/commands/<basename>
#   collab-pipeline:project → assemble templates/collab-pipeline-body.md into
#     .cursor/rules/collab-pipeline.mdc and .agent/workflows/collab-pipeline.md (single source)

BUNDLE_CORE=(
  "commands:smart-git-commit-push.md"
  "commands:optimize-tokens.md"
  "commands:debug-guide.md"
  "agents:debug-guide.md"
  "commands:what-to-do.md"
  "agents:what-to-do.md"
  "agents:token-duplication-detector.md"
  "agents:token-load-measurer.md"
  "agents:token-mcp-analyzer.md"
  "agents:token-split-detector.md"
  "claude-hook:git-auto-pull"
  "claude-hook:branch-naming"
  "claude-hook:guard-branch"
  "claude-hook:guard-merge"
  "claude-hook:auto-pr-commit"
  "claude-hook:worktree-cleanup"
  "claude-hook:auto-pr"
  "template:pre-commit"
)

BUNDLE_DOCS=(
  "skills:diataxis-doc-system"
  "commands:write-doc.md"
  "commands:init-docs.md"
  "commands:sync-docs.md"
  "agents:doc-writer-guide.md"
  "agents:doc-writer-explain.md"
  "agents:doc-writer-reference.md"
  "agents:doc-writer-task.md"
  "agents:doc-writer-contract.md"
  "agents:doc-writer-checklist.md"
  "agents:doc-writer-review.md"
  "agents:doc-reviewer.md"
  "agents:doc-reviewer-execution.md"
  "agents:doc-polisher.md"
  "commands:polish-doc.md"
  "skills:diagram-architect"
  "agents:diagram-writer.md"
)

BUNDLE_DATA_PIPELINE=(
  "skills:data-pipeline-architect"
)

BUNDLE_CAREER=(
  "skills:career-docs"
  "agents:career-docs-writer.md"
  "agents:career-docs-reviewer.md"
  "agents:career-docs-reviser.md"
)

BUNDLE_DL=(
  "rules:pytorch-dl-standards.md"
  "agents:dl-capture.md"
  "agents:dl-data.md"
  "agents:dl-eval.md"
  "agents:dl-infra.md"
  "agents:dl-model.md"
  "agents:dl-train.md"
)

BUNDLE_COLLAB=(
  "rules:collab-workflow.md"
  "rules:review-merge-policy.md"
  "commands:work-plan.md"
  "commands:work-impl.md"
  "commands:work-refactor.md"
  "commands:work-review.md"
  "commands:work-status.md"
  "skills:collab-workflow"
  "agents:ci-audit-agent.md"
  "agents:pr-reviewer.md"
  "templates:work-item"
  "collab-pipeline:project"
  "workflow:branch-auto-sync.yml"
  "workflow:safe-branch-cleanup.yml"
  "workflow:pr-checks.yml"
  "root-file:AGENTS.md"
  "root-file:CLAUDE.md"
  "script:codex-run.sh"
  "script:lib/merge-lock.sh"
)

BUNDLE_PRESENTATION=(
  "skills:html-presentation"
  "commands:create-presentation.md"
  "commands:format-presentation.md"
  "commands:edit-presentation.md"
  "commands:export-pdf.md"
  "script:scripts/html_to_pdf.py"
)

BUNDLE_WORKNOTE=(
  "skills:worknote"
  "agents:worknote-sync.md"
  "agents:worknote-review.md"
  "agents:worknote-plan.md"
  "claude-hook:worknote-stop"
)

BUNDLE_PPT_GENERATION=(
  "skills:ppt-generation"
  "commands:generate-ppt.md"
  "agents:ppt-density-checker.md"
  "agents:ppt-format-reviewer.md"
)

BUNDLE_GOOGLE_STYLE=(
  "rules:google-style-cpp.md"
  "rules:google-style-python.md"
  "skills:google-style-refactor"
  "commands:refactor-google-style.md"
  "agents:google-style-refactor-cpp.md"
  "agents:google-style-refactor-python.md"
  "cursor-rule:google-style-cpp.mdc"
  "cursor-rule:google-style-python.mdc"
  "template:google-style"
)

BUNDLE_NAMES=("core" "docs" "data-pipeline" "career" "dl" "collab" "presentation" "worknote" "ppt-generation" "google-style")
BUNDLE_DESCRIPTIONS=(
  "Core utilities (smart-git-commit-push, optimize-tokens, debug-guide, guard-branch, auto-pr, pre-commit)"
  "Documentation & diagrams (diataxis framework, doc agents, diagram-architect)"
  "Data pipeline architect"
  "Career document tools (cover letters, Korean)"
  "PyTorch DL standards + agents (capture, data, model, train, eval, infra)"
  "Claude-Codex collaboration (work items, guard-branch, auto-sync, AGENTS.md, CLAUDE.md)"
  "HTML presentation generator (16:9 dark theme slides + PDF export)"
  "Work journal with Notion sync (daily log, review, planning)"
  "PPT template-based generation (fill content into base PPT without changing design)"
  "Google C++/Python Style Guide refactor (rules, skill, /refactor-google-style, Cursor .mdc, .clang-format)"
)

# ── Parse arguments ─────────────────────────────────────────────────────────
SELECTED_BUNDLES=()
EXCLUDED_BUNDLES=()
TARGET_DIR=""
INTERACTIVE=false
LIST_ONLY=false
UNINSTALL=false
FORCE_YES=false
INSTALL_HAS_COLLAB=false
INSTALL_HAS_CORE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)           SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}"); shift ;;
    --core)          SELECTED_BUNDLES+=("core"); shift ;;
    --docs)          SELECTED_BUNDLES+=("docs"); shift ;;
    --data-pipeline) SELECTED_BUNDLES+=("data-pipeline"); shift ;;
    --career)        SELECTED_BUNDLES+=("career"); shift ;;
    --dl)            SELECTED_BUNDLES+=("dl"); shift ;;
    --collab)        SELECTED_BUNDLES+=("collab"); shift ;;
    --presentation)  SELECTED_BUNDLES+=("presentation"); shift ;;
    --worknote)      SELECTED_BUNDLES+=("worknote"); shift ;;
    --ppt-generation) SELECTED_BUNDLES+=("ppt-generation"); shift ;;
    --google-style)  SELECTED_BUNDLES+=("google-style"); shift ;;
    --exclude)       shift; EXCLUDED_BUNDLES+=("$1"); shift ;;
    --interactive)   INTERACTIVE=true; shift ;;
    --list)          LIST_ONLY=true; shift ;;
    --uninstall)     UNINSTALL=true; shift ;;
    -y|--yes)        FORCE_YES=true; shift ;;
    -*)              echo "Unknown option: $1" >&2; exit 1 ;;
    *)               TARGET_DIR="$1"; shift ;;
  esac
done

# ── List mode ───────────────────────────────────────────────────────────────
if $LIST_ONLY; then
  echo "Available bundles:"
  echo ""
  for i in "${!BUNDLE_NAMES[@]}"; do
    printf "  %-16s %s\n" "${BUNDLE_NAMES[$i]}" "${BUNDLE_DESCRIPTIONS[$i]}"
  done
  echo ""
  echo "Usage: ./install.sh --core --docs [TARGET_DIR]"
  exit 0
fi

# ── Interactive mode ────────────────────────────────────────────────────────
if $INTERACTIVE; then
  echo "Select bundles to install (space-separated numbers, or 'a' for all):"
  echo ""
  for i in "${!BUNDLE_NAMES[@]}"; do
    printf "  [%d] %-16s %s\n" "$((i+1))" "${BUNDLE_NAMES[$i]}" "${BUNDLE_DESCRIPTIONS[$i]}"
  done
  echo ""
  read -rp "Choice: " choice

  if [[ "$choice" == "a" || "$choice" == "A" ]]; then
    SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}")
  else
    for num in $choice; do
      idx=$((num - 1))
      if [[ $idx -ge 0 && $idx -lt ${#BUNDLE_NAMES[@]} ]]; then
        SELECTED_BUNDLES+=("${BUNDLE_NAMES[$idx]}")
      else
        echo "Invalid selection: $num" >&2
      fi
    done
  fi

  if [[ ${#SELECTED_BUNDLES[@]} -eq 0 ]]; then
    echo "No bundles selected. Exiting."
    exit 0
  fi
fi

# ── Default: install all if no bundles specified ────────────────────────────
if [[ ${#SELECTED_BUNDLES[@]} -eq 0 ]]; then
  if $UNINSTALL; then
    echo "WARNING: No bundle specified — this will uninstall ALL bundles."
    if $FORCE_YES; then
      SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}")
    elif [ -t 0 ]; then
      read -rp "Continue? [y/N] " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}")
      else
        echo "Aborted."
        exit 0
      fi
    else
      echo "Use -y to confirm, or specify bundles (e.g. --uninstall --dl)."
      exit 1
    fi
  else
    SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}")
  fi
fi

# ── Apply exclusions ───────────────────────────────────────────────────────
if [[ ${#EXCLUDED_BUNDLES[@]} -gt 0 ]]; then
  FILTERED=()
  for bundle in "${SELECTED_BUNDLES[@]}"; do
    skip=false
    for ex in "${EXCLUDED_BUNDLES[@]}"; do
      [[ "$bundle" == "$ex" ]] && skip=true
    done
    $skip || FILTERED+=("$bundle")
  done
  SELECTED_BUNDLES=("${FILTERED[@]}")
fi

if printf '%s\n' "${SELECTED_BUNDLES[@]}" | grep -qx "collab"; then
  INSTALL_HAS_COLLAB=true
fi

if printf '%s\n' "${SELECTED_BUNDLES[@]}" | grep -qx "core"; then
  INSTALL_HAS_CORE=true
fi

# ── Resolve target directory (REQUIRED) ─────────────────────────────────────
# All bundles install into a project directory. Global (~/) install is not supported.
if [ -z "$TARGET_DIR" ]; then
  echo "ERROR: project directory is required." >&2
  echo "" >&2
  echo "  All bundles install into a project's .claude/ directory." >&2
  echo "" >&2
  echo "  Usage:" >&2
  echo "    ./install.sh /path/to/project                  # install all bundles" >&2
  echo "    ./install.sh --core --collab /path/to/project   # specific bundles" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

CLAUDE_DIR="$PROJECT_ROOT/.claude"

# ── Collect files to install ────────────────────────────────────────────────
declare -a INSTALL_LIST=()

get_bundle_items() {
  local bundle_name="$1"
  case "$bundle_name" in
    core)          printf '%s\n' "${BUNDLE_CORE[@]}" ;;
    docs)          printf '%s\n' "${BUNDLE_DOCS[@]}" ;;
    data-pipeline) printf '%s\n' "${BUNDLE_DATA_PIPELINE[@]}" ;;
    career)        printf '%s\n' "${BUNDLE_CAREER[@]}" ;;
    dl)            printf '%s\n' "${BUNDLE_DL[@]}" ;;
    collab)        printf '%s\n' "${BUNDLE_COLLAB[@]}" ;;
    presentation)  printf '%s\n' "${BUNDLE_PRESENTATION[@]}" ;;
    worknote)        printf '%s\n' "${BUNDLE_WORKNOTE[@]}" ;;
    ppt-generation)  printf '%s\n' "${BUNDLE_PPT_GENERATION[@]}" ;;
    google-style)    printf '%s\n' "${BUNDLE_GOOGLE_STYLE[@]}" ;;
  esac
}

for bundle in "${SELECTED_BUNDLES[@]}"; do
  while IFS= read -r item; do
    INSTALL_LIST+=("$item")
  done < <(get_bundle_items "$bundle")
done

# ── Install functions ───────────────────────────────────────────────────────
install_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp -v "$src" "$dst"
  chmod 644 "$dst"
}

# Assemble collab pipeline from templates/collab-pipeline-body.md (single source; no duplicate templates).
install_collab_pipeline_project_artifacts() {
  local body="$REPO_DIR/templates/collab-pipeline-body.md"
  local tmp_cursor tmp_agent
  if [ ! -f "$body" ]; then
    echo "ERROR: missing collab pipeline body template: $body" >&2
    exit 1
  fi
  tmp_cursor="$(mktemp)"
  tmp_agent="$(mktemp)"
  {
    printf '%s\n' '---'
    printf '%s\n' 'description: "collab pipeline — /collab-workflow {instruction} orchestrates Claude→You→Codex→You→Claude via terminal"'
    printf '%s\n' 'globs: ["work/**", "AGENTS.md", "CLAUDE.md"]'
    printf '%s\n' 'alwaysApply: false'
    printf '%s\n' '---'
    printf '%s\n' ''
    cat "$body"
  } >"$tmp_cursor"
  {
    printf '%s\n' '---'
    printf '%s\n' 'description: "collab pipeline — /collab-workflow {instruction} orchestrates Claude→You→Codex→You→Claude via terminal"'
    printf '%s\n' '---'
    printf '%s\n' ''
    cat "$body"
  } >"$tmp_agent"
  install_file "$tmp_cursor" "$PROJECT_ROOT/.cursor/rules/collab-pipeline.mdc"
  install_file "$tmp_agent" "$PROJECT_ROOT/.agent/workflows/collab-pipeline.md"
  rm -f "$tmp_cursor" "$tmp_agent"
}

install_command() {
  local path="$1"
  local src="$REPO_DIR/commands/$path"
  local dst="$CLAUDE_DIR/commands/$path"
  
  install_file "$src" "$dst"

  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    local dst_ag="$PROJECT_ROOT/.agent/workflows/$path"
    mkdir -p "$(dirname "$dst_ag")"
    
    local first_line
    first_line=$(head -n 1 "$src" 2>/dev/null || true)
    local desc="Execute command"
    
    if [[ "$first_line" == *"—"* ]]; then
      desc=$(echo "$first_line" | awk -F'—' '{print $2}' | xargs)
    elif [[ "$first_line" == *"-"* ]]; then
      desc=$(echo "$first_line" | awk -F'-' '{print $2}' | xargs)
    fi
    
    echo -e "---\ndescription: $desc\n---\n$(cat "$src")" > "$dst_ag"
  fi
}

install_skill_dir() {
  local skill_name="$1"
  local src="$REPO_DIR/skills/$skill_name"
  local dst="$CLAUDE_DIR/skills/$skill_name"

  [ -d "$src" ] || return 0

  mkdir -p "$dst"
  find "$src" -type d | while read -r dir; do
    relative="${dir#$src}"
    [ -n "$relative" ] && mkdir -p "$dst/$relative" || true
  done
  find "$src" -type f | while read -r file; do
    relative="${file#$src}"
    install_file "$file" "$dst/$relative"
  done

  # Remove legacy per-IDE skill paths from older installer versions (single tree: .claude/skills only).
  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    rm -rf "$PROJECT_ROOT/.agent/skills/$skill_name" "$PROJECT_ROOT/.cursor/skills/$skill_name"
  fi
}

install_template_dir() {
  local tpl_name="$1"
  local src="$REPO_DIR/templates/$tpl_name"
  local dst="$CLAUDE_DIR/templates/$tpl_name"

  [ -d "$src" ] || return 0

  mkdir -p "$dst"
  find "$src" -type f | while read -r file; do
    relative="${file#$src}"
    install_file "$file" "$dst/$relative"
  done || true
}

install_root_file() {
  local filename="$1"
  local src=""
  local dst="$PROJECT_ROOT/$filename"

  # Resolve source: check templates/codex/ then templates/claude/
  if [ -f "$REPO_DIR/templates/codex/$filename" ]; then
    src="$REPO_DIR/templates/codex/$filename"
  elif [ -f "$REPO_DIR/templates/claude/$filename" ]; then
    src="$REPO_DIR/templates/claude/$filename"
  else
    echo "WARNING: Template not found for root-file: $filename" >&2
    return 0
  fi

  # Backup existing file
  if [ -f "$dst" ]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up existing $filename → $(basename "$backup")"
    cp "$dst" "$backup"
  fi

  install_file "$src" "$dst"
}

install_mcp_dir() {
  local mcp_name="$1"
  local src="$REPO_DIR/mcp/$mcp_name"
  local dst="$PROJECT_ROOT/mcp/$mcp_name"

  [ -d "$src" ] || return 0

  mkdir -p "$dst"
  find "$src" -type f | while read -r file; do
    relative="${file#$src}"
    install_file "$file" "$dst/$relative"
  done || true
}

install_hook() {
  local hook_name="$1"
  local src="$REPO_DIR/templates/hooks/$hook_name"

  [ -f "$src" ] || { echo "WARNING: Hook template not found: $hook_name" >&2; return 0; }

  # Find git common dir (shared hooks dir for worktrees)
  local git_common_dir
  git_common_dir=$(git -C "$PROJECT_ROOT" rev-parse --git-common-dir 2>/dev/null || true)
  if [ -z "$git_common_dir" ]; then
    echo "  Skip hook $hook_name: not a git repository"
    return 0
  fi

  local hooks_dir="$git_common_dir/hooks"
  mkdir -p "$hooks_dir"

  # Derive target hook name (e.g., "post-checkout-work-link" -> "post-checkout")
  local target_hook="${hook_name%%-work-link}"
  target_hook="${target_hook%%-*-*}"
  # More precise: extract up to "post-checkout" or "pre-commit" pattern
  if [[ "$hook_name" == post-checkout* ]]; then
    target_hook="post-checkout"
  elif [[ "$hook_name" == pre-commit* ]]; then
    target_hook="pre-commit"
  fi

  local dst="$hooks_dir/$target_hook"

  if [ -f "$dst" ]; then
    # Check if snippet is already installed
    if grep -q "Auto-link work/ from docs worktree" "$dst" 2>/dev/null; then
      echo "  Skip hook $target_hook: work-link snippet already present"
      return 0
    fi
    # Append snippet (skip shebang line from template)
    echo "" >> "$dst"
    echo "# ─── work-link snippet (installed by claude-useful-instructions) ───" >> "$dst"
    tail -n +2 "$src" >> "$dst"
    echo "  Appended work-link snippet to existing $target_hook hook"
  else
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "  Installed hook: $target_hook"
  fi
}

install_hook_lib() {
  local src="$REPO_DIR/hooks/lib"
  local dst="$HOME/.claude/hooks/lib"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for f in "$src"/*.py; do
    [ -f "$f" ] || continue
    cp -v "$f" "$dst/$(basename "$f")"
  done
}

install_claude_hook() {
  local hook_name="$1"
  local src="$REPO_DIR/hooks/$hook_name"
  local dst_dir="$HOME/.claude/hooks"

  [ -d "$src" ] || { echo "WARNING: Claude hook dir not found: $src" >&2; return 0; }

  mkdir -p "$dst_dir"

  # Always install shared lib alongside hooks
  install_hook_lib

  local copied_files=()
  for f in "$src"/*.py "$src"/*.sh; do
    [ -f "$f" ] || continue
    local filename
    filename="$(basename "$f")"
    cp -v "$f" "$dst_dir/$filename"
    chmod +x "$dst_dir/$filename"
    copied_files+=("$filename")
  done

  for f in "$src"/*.json.example; do
    [ -f "$f" ] || continue
    local filename
    filename="$(basename "$f")"
    cp -v "$f" "$dst_dir/$filename"
  done

  python3 "$REPO_DIR/scripts/patch-hook-settings.py" "$hook_name"
}

# ── Uninstall functions ────────────────────────────────────────────────────
remove_file() {
  local path="$1"
  if [ -f "$path" ]; then
    rm -v "$path"
  fi
}

remove_command() {
  local path="$1"
  remove_file "$CLAUDE_DIR/commands/$path"
  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    remove_file "$PROJECT_ROOT/.agent/workflows/$path"
  fi
}

remove_dir_if_empty() {
  local dir="$1"
  [ -d "$dir" ] && rmdir --ignore-fail-on-non-empty -p "$dir" 2>/dev/null || true
}

remove_skill_dir() {
  local skill_name="$1"
  local dst="$CLAUDE_DIR/skills/$skill_name"
  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    local dst_ag="$PROJECT_ROOT/.agent/skills/$skill_name"
    local dst_cu="$PROJECT_ROOT/.cursor/skills/$skill_name"
    if [ -e "$dst_ag" ] || [ -L "$dst_ag" ]; then
      rm -rv "$dst_ag"
    fi
    if [ -e "$dst_cu" ] || [ -L "$dst_cu" ]; then
      rm -rv "$dst_cu"
    fi
  fi
  if [ -d "$dst" ] || [ -L "$dst" ]; then
    rm -rv "$dst"
  fi
}

remove_template_dir() {
  local tpl_name="$1"
  local dst="$CLAUDE_DIR/templates/$tpl_name"
  if [ -d "$dst" ]; then
    rm -rv "$dst"
  fi
}

remove_root_file() {
  local filename="$1"
  local dst="$PROJECT_ROOT/$filename"
  # Remove the file and any backups
  remove_file "$dst"
  for backup in "$PROJECT_ROOT"/"$filename".backup.*; do
    if [ -f "$backup" ]; then
      rm -v "$backup"
    fi
  done
}

remove_mcp_dir() {
  local mcp_name="$1"
  local dst="$PROJECT_ROOT/mcp/$mcp_name"
  if [ -d "$dst" ]; then
    rm -rv "$dst"
  fi
  remove_dir_if_empty "$PROJECT_ROOT/mcp"
}

remove_hook() {
  local hook_name="$1"

  local git_common_dir
  git_common_dir=$(git -C "$PROJECT_ROOT" rev-parse --git-common-dir 2>/dev/null || true)
  [ -z "$git_common_dir" ] && return 0

  local target_hook
  if [[ "$hook_name" == post-checkout* ]]; then
    target_hook="post-checkout"
  elif [[ "$hook_name" == pre-commit* ]]; then
    target_hook="pre-commit"
  fi

  local dst="$git_common_dir/hooks/$target_hook"
  [ -f "$dst" ] || return 0

  # Detect our hook content by either marker
  if grep -q "Auto-link work/ from docs worktree" "$dst" 2>/dev/null; then
    if grep -q "work-link snippet (installed by claude-useful-instructions)" "$dst" 2>/dev/null; then
      # Appended snippet — remove only the snippet block
      local tmp="$dst.tmp"
      sed '/# ─── work-link snippet (installed by claude-useful-instructions) ───/,$ d' "$dst" > "$tmp"
      local remaining
      remaining=$(grep -cv '^\(#!\|#\|$\)' "$tmp" 2>/dev/null || echo "0")
      if [ "$remaining" -eq 0 ] || [ ! -s "$tmp" ]; then
        rm -v "$dst"
        rm -f "$tmp"
        echo "  Removed hook: $target_hook"
      else
        mv "$tmp" "$dst"
        chmod +x "$dst"
        echo "  Removed work-link snippet from $target_hook hook"
      fi
    else
      # Standalone install — remove the entire hook file
      rm -v "$dst"
      echo "  Removed hook: $target_hook"
    fi
  fi
}

remove_claude_hook() {
  local hook_name="$1"
  local dst_dir="$HOME/.claude/hooks"
  local src="$REPO_DIR/hooks/$hook_name"
  [ -d "$src" ] || return 0

  # settings.json FIRST — deregister hooks before deleting files.
  # If files are deleted first, any Bash PostToolUse hook that fires in
  # the window between file deletion and settings.json cleanup will fail
  # with "No such file or directory".
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    python3 - "$hook_name" "$REPO_DIR/scripts/patch-hook-settings.py" <<'PYEOF'
import importlib.util
import json
import os
import sys

settings_path = os.path.expanduser("~/.claude/settings.json")
hook_name = sys.argv[1]
script_path = sys.argv[2]

spec = importlib.util.spec_from_file_location("patch_hook_settings", script_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

config = module.HOOK_REGISTRY.get(hook_name, {})
managed = config.get("managed", set())

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})

def is_managed(command: str) -> bool:
    return any(name in command for name in managed)

def remove_managed_hooks(entries: list) -> list:
    result = []
    for entry in entries:
        filtered = [h for h in entry.get("hooks", []) if not is_managed(h.get("command", ""))]
        if filtered:
            result.append({**entry, "hooks": filtered})
    return result

changed = False
for event in list(hooks.keys()):
    cleaned = remove_managed_hooks(hooks[event])
    if cleaned != hooks[event]:
        hooks[event] = cleaned
        changed = True
    if not hooks[event]:
        del hooks[event]
        changed = True

if changed:
    settings["hooks"] = hooks
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"  Removed {hook_name} hooks from settings.json")
PYEOF
  fi

  # Delete hook files AFTER settings.json is updated
  for f in "$src"/*.py "$src"/*.sh "$src"/*.json.example; do
    [ -f "$f" ] || continue
    local filename
    filename="$(basename "$f")"
    if [ -f "$dst_dir/$filename" ]; then
      rm -v "$dst_dir/$filename"
    fi
  done
}

remove_work_dir() {
  # Remove work/ from the target project only (no sibling worktrees)
  local work_dir="$PROJECT_ROOT/work"
  if [ -L "$work_dir" ]; then
    rm -v "$work_dir"
    echo "  Removed work/ symlink"
  elif [ -d "$work_dir" ]; then
    if $FORCE_YES; then
      rm -rv "$work_dir"
    elif [ -t 0 ]; then
      read -rp "  Remove work/ directory (contains work items)? [y/N] " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rv "$work_dir"
      else
        echo "  Skipped work/ directory (use -y to force)"
      fi
    else
      echo "  Skipped work/ directory (run interactively or use -y to force)"
    fi
  fi
}

ensure_collab_scaffold() {
  mkdir -p "$PROJECT_ROOT/work/items"
}

ensure_branch_protection() {
  # Configure GitHub branch protection + squash-only repo settings.
  # Requires `gh` auth with admin:repo on the target repository.
  if ! command -v gh &>/dev/null; then
    echo "  NOTE: gh CLI not found — skipping branch protection setup"
    return
  fi

  local repo
  repo=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s/\.git$//')
  if [[ -z "$repo" ]]; then
    echo "  NOTE: No GitHub remote detected — skipping branch protection setup"
    return
  fi

  # Resolve default branch
  local default_branch
  default_branch=$(gh api "repos/$repo" --jq .default_branch 2>/dev/null || true)
  if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
    echo "  NOTE: Could not resolve default branch — skipping branch protection setup"
    return
  fi

  echo "  Configuring branch protection on $repo@$default_branch..."

  # Backup current protection (if any)
  local backup_file="$PROJECT_ROOT/.branch-protection-backup.json"
  if gh api "repos/$repo/branches/$default_branch/protection" >"$backup_file" 2>/dev/null; then
    echo "    ✓ Existing protection backed up to .branch-protection-backup.json"
  else
    rm -f "$backup_file"
  fi

  # Apply v2 protection
  local protection_json
  protection_json=$(cat <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["check"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "required_conversation_resolution": true,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
)
  if echo "$protection_json" | gh api -X PUT "repos/$repo/branches/$default_branch/protection" --input - >/dev/null 2>&1; then
    echo "    ✓ Branch protection applied"
  else
    echo "    WARN: Branch protection failed (needs admin:repo token). Configure manually:"
    echo "      Settings → Branches → Add rule on $default_branch"
  fi

  # Repo-level merge settings: squash only, auto-delete branches
  if gh api -X PATCH "repos/$repo" \
      -F allow_squash_merge=true \
      -F allow_merge_commit=false \
      -F allow_rebase_merge=false \
      -F delete_branch_on_merge=true \
      -F squash_merge_commit_title=PR_TITLE \
      -F squash_merge_commit_message=PR_BODY \
      >/dev/null 2>&1; then
    echo "    ✓ Squash-only merge + auto-delete branches enabled"
  else
    echo "    WARN: Repo settings update failed (needs admin:repo token)"
  fi
}

ensure_cursor_mcp() {
  local mcp_file="$PROJECT_ROOT/.cursor/mcp.json"
  if [[ -f "$mcp_file" ]]; then
    echo "  .cursor/mcp.json already exists — skipping"
    return
  fi
  mkdir -p "$PROJECT_ROOT/.cursor"
  cat > "$mcp_file" <<'MCPEOF'
{
  "mcpServers": {
    "github": {
      "command": "bash",
      "args": ["-lc", "token=$(gh auth token 2>/dev/null || true); if [ -n \"$token\" ]; then export GITHUB_PERSONAL_ACCESS_TOKEN=\"$token\"; fi; exec npx -y @modelcontextprotocol/server-github"]
    }
  }
}
MCPEOF
  echo "  Created .cursor/mcp.json (uses gh auth token automatically)"
}

# ── Execute uninstall ─────────────────────────────────────────────────────
if $UNINSTALL; then
  echo "Uninstalling Claude settings from $CLAUDE_DIR"
  echo "Bundles: ${SELECTED_BUNDLES[*]}"
  echo "────────────────────────────────────────────────────────"

  HAS_COLLAB=false
  for entry in "${INSTALL_LIST[@]}"; do
    type="${entry%%:*}"
    path="${entry#*:}"

    case "$type" in
      rules)     remove_file "$CLAUDE_DIR/rules/$path" ;;
      commands)  remove_command "$path" ;;
      agents)    remove_file "$CLAUDE_DIR/agents/$path" ;;
      skills)    remove_skill_dir "$path" ;;
      templates) remove_template_dir "$path" ;;
      workflow)
        remove_file "$PROJECT_ROOT/.github/workflows/$path"
        # Remove legacy scripts/ directory (parse-branch-map.py no longer used)
        remove_file "$PROJECT_ROOT/.github/workflows/scripts/parse-branch-map.py"
        remove_dir_if_empty "$PROJECT_ROOT/.github/workflows/scripts"
        ;;
      root-file)   remove_root_file "$path" ;;
      cursor-rule) remove_file "$PROJECT_ROOT/.cursor/rules/$path" ;;
      cursor-command) remove_file "$PROJECT_ROOT/.cursor/commands/$path" ;;
      agent-rule)  remove_file "$PROJECT_ROOT/.agent/workflows/$path" ;;
      collab-pipeline)
        remove_file "$PROJECT_ROOT/.cursor/rules/collab-pipeline.mdc"
        remove_file "$PROJECT_ROOT/.agent/workflows/collab-pipeline.md"
        ;;
      script)      remove_file "$PROJECT_ROOT/$path" ;;
      hook)        remove_hook "$path" ;;
      claude-hook) remove_claude_hook "$path" ;;
      mcp)         remove_mcp_dir "$path" ;;
    esac
  done

  if printf '%s\n' "${SELECTED_BUNDLES[@]}" | grep -qx "collab"; then
    HAS_COLLAB=true
  fi

  # Remove work/ dir and cursor MCP if collab bundle is being uninstalled
  if $HAS_COLLAB; then
    remove_work_dir
    remove_file "$PROJECT_ROOT/.cursor/mcp.json"
  fi

  # Remove worktree guard marker if core or collab uninstalled
  HAS_CORE=false
  if printf '%s\n' "${SELECTED_BUNDLES[@]}" | grep -qx "core"; then HAS_CORE=true; fi
  if $HAS_CORE || $HAS_COLLAB; then
    remove_file "$PROJECT_ROOT/.claude-worktree-enabled"
  fi

  # Clean up empty .claude subdirectories
  for subdir in rules commands agents skills templates; do
    remove_dir_if_empty "$CLAUDE_DIR/$subdir"
  done
  remove_dir_if_empty "$CLAUDE_DIR"

  # Clean up empty Antigravity / Cursor directories (.agent/, .cursor/)
  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    for subdir in workflows skills; do
      remove_dir_if_empty "$PROJECT_ROOT/.agent/$subdir"
    done
    remove_dir_if_empty "$PROJECT_ROOT/.agent"
    remove_dir_if_empty "$PROJECT_ROOT/.cursor/skills"
    remove_dir_if_empty "$PROJECT_ROOT/.cursor/commands"
    remove_dir_if_empty "$PROJECT_ROOT/.cursor/rules"
    remove_dir_if_empty "$PROJECT_ROOT/.cursor"
  fi

  echo "────────────────────────────────────────────────────────"
  echo "Done. Uninstalled bundles: ${SELECTED_BUNDLES[*]}"
  exit 0
fi

# ── Execute installation ───────────────────────────────────────────────────
echo "Installing Claude settings from $REPO_DIR → $CLAUDE_DIR"
echo "Bundles: ${SELECTED_BUNDLES[*]}"
echo "────────────────────────────────────────────────────────"

for entry in "${INSTALL_LIST[@]}"; do
  type="${entry%%:*}"
  path="${entry#*:}"

  case "$type" in
    rules)
      install_file "$REPO_DIR/rules/$path" "$CLAUDE_DIR/rules/$path"
      ;;
    commands)
      install_command "$path"
      ;;
    agents)
      install_file "$REPO_DIR/agents/$path" "$CLAUDE_DIR/agents/$path"
      ;;
    skills)
      install_skill_dir "$path"
      ;;
    templates)
      install_template_dir "$path"
      ;;
    root-file)
      install_root_file "$path"
      ;;
    cursor-rule)
      mkdir -p "$PROJECT_ROOT/.cursor/rules"
      install_file "$REPO_DIR/templates/cursor/$path" "$PROJECT_ROOT/.cursor/rules/$path"
      ;;
    collab-pipeline)
      mkdir -p "$PROJECT_ROOT/.cursor/rules" "$PROJECT_ROOT/.agent/workflows"
      install_collab_pipeline_project_artifacts
      ;;
    cursor-command)
      mkdir -p "$PROJECT_ROOT/.cursor/commands"
      install_file "$REPO_DIR/templates/cursor-commands/$path" "$PROJECT_ROOT/.cursor/commands/$path"
      ;;
    agent-rule)
      mkdir -p "$PROJECT_ROOT/.agent/workflows"
      install_file "$REPO_DIR/templates/agent-rules/$path" "$PROJECT_ROOT/.agent/workflows/$path"
      ;;
    script)
      install_file "$REPO_DIR/$path" "$PROJECT_ROOT/$path"
      chmod +x "$PROJECT_ROOT/$path"
      ;;
    hook)
      install_hook "$path"
      ;;
    workflow)
      _wf_src="$REPO_DIR/templates/workflows/$path"
      _wf_dst="$PROJECT_ROOT/.github/workflows/$path"
      if [ -f "$_wf_src" ]; then
        mkdir -p "$(dirname "$_wf_dst")"
        install_file "$_wf_src" "$_wf_dst"
        _scripts_dir="$REPO_DIR/templates/workflows/scripts"
        if [ -d "$_scripts_dir" ]; then
          mkdir -p "$PROJECT_ROOT/.github/workflows/scripts"
          for s in "$_scripts_dir"/*.py; do
            [ -f "$s" ] || continue
            install_file "$s" "$PROJECT_ROOT/.github/workflows/scripts/$(basename "$s")"
          done
        fi
      else
        echo "WARNING: Workflow template not found: $_wf_src" >&2
      fi
      ;;
    claude-hook)
      install_claude_hook "$path"
      ;;
    template)
      # Copy template files to project root (e.g., .pre-commit-config.yaml)
      _tmpl_dir="$REPO_DIR/templates/$path"
      if [ -d "$_tmpl_dir" ]; then
        for _tmpl_file in "$_tmpl_dir"/.*  "$_tmpl_dir"/*; do
          [ -f "$_tmpl_file" ] || continue
          _fname="$(basename "$_tmpl_file")"
          [[ "$_fname" == "." || "$_fname" == ".." ]] && continue
          _dst_path="$PROJECT_ROOT/$_fname"
          if [ -f "$_dst_path" ]; then
            echo "  $_fname already exists — skipping"
          else
            install_file "$_tmpl_file" "$_dst_path"
          fi
        done
      else
        echo "WARNING: Template dir not found: $_tmpl_dir" >&2
      fi
      ;;
    mcp)
      install_mcp_dir "$path"
      ;;
  esac
done

if $INSTALL_HAS_COLLAB; then
  ensure_collab_scaffold
  ensure_cursor_mcp
  ensure_branch_protection
fi

# ── Enable worktree guard for projects that install core or collab ─────────
if $INSTALL_HAS_CORE || $INSTALL_HAS_COLLAB; then
  _marker="$PROJECT_ROOT/.claude-worktree-enabled"
  if [[ ! -f "$_marker" ]]; then
    touch "$_marker"
    echo "  ✓ Worktree guard enabled (.claude-worktree-enabled)"
  fi
fi

# ── Auto-install pre-commit when core bundle is installed ────────────────
ensure_pre_commit() {
  if [[ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
    return
  fi

  # Install pre-commit if not available
  if ! command -v pre-commit &>/dev/null; then
    if command -v uv &>/dev/null; then
      echo "  Installing pre-commit via uv..."
      uv tool install pre-commit 2>/dev/null || uv pip install pre-commit 2>/dev/null || true
    elif command -v pip &>/dev/null; then
      echo "  Installing pre-commit via pip..."
      pip install pre-commit 2>/dev/null || true
    else
      echo "  NOTE: pre-commit not found. Install with: uv tool install pre-commit"
      return
    fi
  fi

  if command -v pre-commit &>/dev/null; then
    # Unset core.hooksPath at all levels — conflicts with pre-commit install
    _hooks_path=$(git config --global --get core.hooksPath 2>/dev/null || true)
    if [[ -n "$_hooks_path" ]]; then
      echo "  Unsetting global core.hooksPath (was: $_hooks_path) for pre-commit compatibility"
      git config --global --unset-all core.hooksPath 2>/dev/null || true
    fi
    _hooks_path=$(git -C "$PROJECT_ROOT" config --local --get core.hooksPath 2>/dev/null || true)
    if [[ -n "$_hooks_path" ]]; then
      echo "  Unsetting local core.hooksPath (was: $_hooks_path) for pre-commit compatibility"
      git -C "$PROJECT_ROOT" config --local --unset-all core.hooksPath 2>/dev/null || true
    fi
    if (cd "$PROJECT_ROOT" && pre-commit install 2>&1); then
      echo "  ✓ pre-commit hooks installed"
    else
      echo "  WARNING: pre-commit install failed" >&2
    fi
  fi
}

if $INSTALL_HAS_CORE; then
  ensure_pre_commit
fi

echo "────────────────────────────────────────────────────────"
echo "Done. Installed bundles: ${SELECTED_BUNDLES[*]}"
