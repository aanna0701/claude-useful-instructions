#!/usr/bin/env bash
# install.sh — Copy Claude settings (commands, agents, rules, skills) into <TARGET>/.claude/
# Usage: ./install.sh [OPTIONS] [TARGET_DIR]
#   TARGET_DIR: project root to install into (default: ~, i.e. ~/.claude)
#
# Options:
#   --all           Install all bundles (default if no bundle flags given)
#   --core          Core utilities (coding-style, smart-git-commit-push, optimize-tokens)
#   --docs          Documentation & diagrams (diataxis, write-doc, init-docs, sync-docs, doc/diagram agents)
#   --data-pipeline Data pipeline architect skill
#   --career        Career document tools (career-docs skill, career agents)
#   --vla           VLA robotics project (vla-code-standards, vla agents)
#   --collab        Claude-Codex collaboration (work items, AGENTS.md, CLAUDE.md)
#   --exclude NAME  Exclude a bundle (repeatable, e.g. --exclude vla --exclude career)
#   --interactive   Interactive mode: choose bundles from a menu
#   --list          List available bundles and exit
#
# Examples:
#   ./install.sh                                  # Install all to ~/.claude
#   ./install.sh --core --docs                    # Install core + docs only
#   ./install.sh --exclude career --exclude vla   # Install all except career and vla
#   ./install.sh --interactive ~/proj             # Interactive selection

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Bundle definitions ──────────────────────────────────────────────────────
# Each bundle lists its files relative to REPO_DIR.
# Format: "type:relative_path" where type is rules|commands|agents|skills

BUNDLE_CORE=(
  "rules:coding-style.md"
  "commands:smart-git-commit-push.md"
  "commands:optimize-tokens.md"
)

BUNDLE_DOCS=(
  "skills:diataxis-doc-system"
  "commands:write-doc.md"
  "commands:init-docs.md"
  "commands:sync-docs.md"
  "agents:doc-writer-tutorial.md"
  "agents:doc-writer-howto.md"
  "agents:doc-writer-explain.md"
  "agents:doc-writer-reference.md"
  "agents:doc-writer-task.md"
  "agents:doc-writer-contract.md"
  "agents:doc-writer-checklist.md"
  "agents:doc-writer-review.md"
  "agents:doc-reviewer.md"
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
)

BUNDLE_VLA=(
  "rules:vla-code-standards.md"
  "agents:vla-capture.md"
  "agents:vla-data.md"
  "agents:vla-eval.md"
  "agents:vla-infra.md"
  "agents:vla-model.md"
  "agents:vla-train.md"
)

BUNDLE_COLLAB=(
  "rules:collab-workflow.md"
  "commands:work-plan.md"
  "commands:work-review.md"
  "commands:work-status.md"
  "skills:collab-workflow"
  "templates:work-item"
  "root-file:AGENTS.md"
  "root-file:CLAUDE.md"
  "script:codex-dispatch.sh"
  "script:gemini-setup.sh"
  "script:link-work.sh"
  "hook:post-checkout-work-link"
  "mcp:gemini-review"
)

BUNDLE_NAMES=("core" "docs" "data-pipeline" "career" "vla" "collab")
BUNDLE_DESCRIPTIONS=(
  "Core utilities (coding-style, smart-git-commit-push, optimize-tokens)"
  "Documentation & diagrams (diataxis framework, doc agents, diagram-architect)"
  "Data pipeline architect"
  "Career document tools (cover letters, Korean)"
  "VLA robotics project (vla agents, code standards)"
  "Claude-Codex collaboration (work items, AGENTS.md, CLAUDE.md)"
)

# ── Parse arguments ─────────────────────────────────────────────────────────
SELECTED_BUNDLES=()
EXCLUDED_BUNDLES=()
TARGET_DIR=""
INTERACTIVE=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)           SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}"); shift ;;
    --core)          SELECTED_BUNDLES+=("core"); shift ;;
    --docs)          SELECTED_BUNDLES+=("docs"); shift ;;
    --data-pipeline) SELECTED_BUNDLES+=("data-pipeline"); shift ;;
    --career)        SELECTED_BUNDLES+=("career"); shift ;;
    --vla)           SELECTED_BUNDLES+=("vla"); shift ;;
    --collab)        SELECTED_BUNDLES+=("collab"); shift ;;
    --exclude)       shift; EXCLUDED_BUNDLES+=("$1"); shift ;;
    --interactive)   INTERACTIVE=true; shift ;;
    --list)          LIST_ONLY=true; shift ;;
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
  SELECTED_BUNDLES=("${BUNDLE_NAMES[@]}")
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

# ── Resolve target directory ────────────────────────────────────────────────
if [ -z "$TARGET_DIR" ]; then
  PROJECT_ROOT="$HOME"
else
  PROJECT_ROOT="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"
fi

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
    vla)           printf '%s\n' "${BUNDLE_VLA[@]}" ;;
    collab)        printf '%s\n' "${BUNDLE_COLLAB[@]}" ;;
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
      install_file "$REPO_DIR/commands/$path" "$CLAUDE_DIR/commands/$path"
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
    script)
      install_file "$REPO_DIR/$path" "$PROJECT_ROOT/$path"
      chmod +x "$PROJECT_ROOT/$path"
      ;;
    hook)
      install_hook "$path"
      ;;
    mcp)
      install_mcp_dir "$path"
      ;;
  esac
done

echo "────────────────────────────────────────────────────────"
echo "Done. Installed bundles: ${SELECTED_BUNDLES[*]}"
