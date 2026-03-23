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
#   --uninstall     Remove installed files (respects bundle flags)
#
# Examples:
#   ./install.sh                                  # Install all to ~/.claude
#   ./install.sh --core --docs                    # Install core + docs only
#   ./install.sh --exclude career --exclude vla   # Install all except career and vla
#   ./install.sh --interactive ~/proj             # Interactive selection
#   ./install.sh --uninstall ~/proj               # Uninstall all from ~/proj
#   ./install.sh --uninstall --collab ~/proj      # Uninstall collab bundle only

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
  "script:codex-run.sh"
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
UNINSTALL=false

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
    --uninstall)     UNINSTALL=true; shift ;;
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

# ── Uninstall functions ────────────────────────────────────────────────────
remove_file() {
  local path="$1"
  if [ -f "$path" ]; then
    rm -v "$path"
  fi
}

remove_dir_if_empty() {
  local dir="$1"
  [ -d "$dir" ] && rmdir --ignore-fail-on-non-empty -p "$dir" 2>/dev/null || true
}

remove_skill_dir() {
  local skill_name="$1"
  local dst="$CLAUDE_DIR/skills/$skill_name"
  if [ -d "$dst" ]; then
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

remove_work_dir() {
  # Remove work/ directory and symlinks from worktrees
  local work_dir="$PROJECT_ROOT/work"
  if [ -L "$work_dir" ]; then
    rm -v "$work_dir"
    echo "  Removed work/ symlink"
  elif [ -d "$work_dir" ]; then
    read -rp "  Remove work/ directory (contains work items)? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm -rv "$work_dir"
    else
      echo "  Skipped work/ directory"
    fi
  fi

  # Clean symlinks in sibling worktrees
  local git_common_dir
  git_common_dir=$(git -C "$PROJECT_ROOT" rev-parse --git-common-dir 2>/dev/null || true)
  if [ -n "$git_common_dir" ]; then
    local worktree_list
    worktree_list=$(git -C "$PROJECT_ROOT" worktree list --porcelain 2>/dev/null | grep "^worktree " | sed 's/^worktree //')
    while IFS= read -r wt_path; do
      [ -z "$wt_path" ] && continue
      [ "$wt_path" = "$PROJECT_ROOT" ] && continue
      if [ -L "$wt_path/work" ]; then
        rm -v "$wt_path/work"
        echo "  Removed work/ symlink from $(basename "$wt_path")"
      fi
    done <<< "$worktree_list"
  fi
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
      commands)  remove_file "$CLAUDE_DIR/commands/$path" ;;
      agents)    remove_file "$CLAUDE_DIR/agents/$path" ;;
      skills)    remove_skill_dir "$path" ;;
      templates) remove_template_dir "$path" ;;
      root-file) remove_root_file "$path" ;;
      script)    remove_file "$PROJECT_ROOT/$path" ;;
      hook)      remove_hook "$path" ;;
      mcp)       remove_mcp_dir "$path"; HAS_COLLAB=true ;;
    esac
  done

  # Remove work/ dir if collab bundle is being uninstalled
  if $HAS_COLLAB; then
    remove_work_dir
  fi

  # Clean up empty .claude subdirectories
  for subdir in rules commands agents skills templates; do
    remove_dir_if_empty "$CLAUDE_DIR/$subdir"
  done
  remove_dir_if_empty "$CLAUDE_DIR"

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
