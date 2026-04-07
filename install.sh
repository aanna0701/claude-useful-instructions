#!/usr/bin/env bash
# install.sh — Copy Claude settings (commands, agents, rules, skills) into <TARGET>/.claude/
# Usage: ./install.sh [OPTIONS] [TARGET_DIR]
#   TARGET_DIR: project root to install into (default: ~, i.e. ~/.claude)
#
# Options:
#   --all           Install all bundles (default if no bundle flags given)
#   --core          Core utilities (smart-git-commit-push, optimize-tokens)
#   --docs          Documentation & diagrams (diataxis, write-doc, init-docs, sync-docs, doc/diagram agents)
#   --data-pipeline Data pipeline architect skill
#   --career        Career document tools (career-docs skill, career agents)
#   --dl            PyTorch DL standards + agents (capture, data, model, train, eval, infra)
#   --collab        Claude-Codex collaboration (work items, branch-map, AGENTS.md, CLAUDE.md)
#   --ppt-generation PPT template-based generation (fill content into base PPT)
#   --exclude NAME  Exclude a bundle (repeatable, e.g. --exclude dl --exclude career)
#   --interactive   Interactive mode: choose bundles from a menu
#   --list          List available bundles and exit
#   --uninstall     Remove installed files (respects bundle flags)
#   -y, --yes       Skip confirmation prompts (e.g. work/ directory removal)
#
# Examples:
#   ./install.sh                                  # Install all to ~/.claude
#   ./install.sh --core --docs                    # Install core + docs only
#   ./install.sh --exclude career --exclude dl    # Install all except career and dl
#   ./install.sh --interactive ~/proj             # Interactive selection
#   ./install.sh --uninstall ~/proj               # Uninstall all from ~/proj
#   ./install.sh --uninstall --collab ~/proj      # Uninstall collab bundle only

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Bundle definitions ──────────────────────────────────────────────────────
# Each bundle lists its files relative to REPO_DIR.
# Format: "type:relative_path" where type is rules|commands|agents|skills

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
  "claude-hook:guard-trunk"
  "claude-hook:auto-pr"
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
  "rules:branch-map-policy.md"
  "rules:collab-workflow.md"
  "rules:review-merge-policy.md"
  "commands:branch-init.md"
  "commands:branch-status.md"
  "commands:work-plan.md"
  "commands:work-review.md"
  "commands:work-impl.md"
  "commands:work-revise.md"
  "commands:work-status.md"
  "commands:gha-branch-sync.md"
  "skills:collab-workflow"
  "agents:ci-audit-agent.md"
  "agents:issue-creator.md"
  "agents:work-reviser.md"
  "agents:pr-reviewer.md"
  "agents:cursor-prompt-builder.md"
  "commands:work-scaffold.md"
  "commands:work-verify.md"
  "templates:branch-map"
  "templates:work-item"
  "templates:cursor"
  "cursor-rule:collab-pipeline.mdc"
  "agent-rule:collab-pipeline.md"
  "workflow:branch-auto-sync.yml"
  "root-file:AGENTS.md"
  "root-file:CLAUDE.md"
  "script:codex-run.sh"
  "script:lib/codex-run-work.sh"
  "script:lib/codex-run-git.sh"
  "script:lib/codex-run-boundary.sh"
  "script:lib/codex-run-runner.sh"
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

BUNDLE_NAMES=("core" "docs" "data-pipeline" "career" "dl" "collab" "presentation" "worknote" "ppt-generation")
BUNDLE_DESCRIPTIONS=(
  "Core utilities (smart-git-commit-push, optimize-tokens, debug-guide, guard-trunk, auto-pr)"
  "Documentation & diagrams (diataxis framework, doc agents, diagram-architect)"
  "Data pipeline architect"
  "Career document tools (cover letters, Korean)"
  "PyTorch DL standards + agents (capture, data, model, train, eval, infra)"
  "Claude-Codex collaboration (work items, branch-map, AGENTS.md, CLAUDE.md)"
  "HTML presentation generator (16:9 dark theme slides + PDF export)"
  "Work journal with Notion sync (daily log, review, planning)"
  "PPT template-based generation (fill content into base PPT without changing design)"
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

# ── Resolve target directory ────────────────────────────────────────────────
if [ -z "$TARGET_DIR" ]; then
  if $INSTALL_HAS_COLLAB; then
    echo "ERROR: --collab needs a project directory." >&2
    echo "" >&2
    echo "  The collab bundle installs project-specific files (AGENTS.md, codex-run.sh," >&2
    echo "  work/ directory, .github/workflows/) that belong in a project root, not ~/" >&2
    echo "" >&2
    echo "  Usage:" >&2
    echo "    ./install.sh --collab /path/to/project" >&2
    echo "" >&2
    echo "  Global bundles (--core, --docs, etc.) can be installed without a path." >&2
    exit 1
  fi
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
    dl)            printf '%s\n' "${BUNDLE_DL[@]}" ;;
    collab)        printf '%s\n' "${BUNDLE_COLLAB[@]}" ;;
    presentation)  printf '%s\n' "${BUNDLE_PRESENTATION[@]}" ;;
    worknote)        printf '%s\n' "${BUNDLE_WORKNOTE[@]}" ;;
    ppt-generation)  printf '%s\n' "${BUNDLE_PPT_GENERATION[@]}" ;;
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

  # Also install into Antigravity standard path (.agent/skills) if project-level
  if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
    local dst_ag="$PROJECT_ROOT/.agent/skills/$skill_name"
    mkdir -p "$dst_ag"
    find "$src" -type d | while read -r dir; do
      relative="${dir#$src}"
      [ -n "$relative" ] && mkdir -p "$dst_ag/$relative" || true
    done
    find "$src" -type f | while read -r file; do
      relative="${file#$src}"
      install_file "$file" "$dst_ag/$relative"
    done
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

install_claude_hook() {
  local hook_name="$1"
  local src="$REPO_DIR/hooks/$hook_name"
  local dst_dir="$HOME/.claude/hooks"

  [ -d "$src" ] || { echo "WARNING: Claude hook dir not found: $src" >&2; return 0; }

  mkdir -p "$dst_dir"

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
  if [ -d "$dst" ]; then
    rm -rv "$dst"
  fi
  local dst_ag="$PROJECT_ROOT/.agent/skills/$skill_name"
  if [ -d "$dst_ag" ]; then
    rm -rv "$dst_ag"
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

  for f in "$src"/*.py "$src"/*.sh "$src"/*.json.example; do
    [ -f "$f" ] || continue
    local filename
    filename="$(basename "$f")"
    if [ -f "$dst_dir/$filename" ]; then
      rm -v "$dst_dir/$filename"
    fi
  done

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
  mkdir -p "$PROJECT_ROOT/work/batches"
  mkdir -p "$PROJECT_ROOT/work/locks"
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
      workflow)     remove_file "$PROJECT_ROOT/.github/workflows/$path" ;;
      root-file)   remove_root_file "$path" ;;
      cursor-rule) remove_file "$PROJECT_ROOT/.cursor/rules/$path" ;;
      agent-rule)  remove_file "$PROJECT_ROOT/.agent/workflows/$path" ;;
      script)      remove_file "$PROJECT_ROOT/$path" ;;
      hook)        remove_hook "$path" ;;
      claude-hook) remove_claude_hook "$path" ;;
      mcp)         remove_mcp_dir "$path" ;;
    esac
  done

  if printf '%s\n' "${SELECTED_BUNDLES[@]}" | grep -qx "collab"; then
    HAS_COLLAB=true
  fi

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
      if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
        mkdir -p "$PROJECT_ROOT/.cursor/rules"
        install_file "$REPO_DIR/templates/cursor/$path" "$PROJECT_ROOT/.cursor/rules/$path"
      else
        echo "  SKIP cursor-rule:$path (requires per-project install with --collab /path/to/project)"
      fi
      ;;
    agent-rule)
      if [ -n "$PROJECT_ROOT" ] && [ "$PROJECT_ROOT" != "$HOME" ]; then
        mkdir -p "$PROJECT_ROOT/.agent/workflows"
        install_file "$REPO_DIR/templates/agent-rules/$path" "$PROJECT_ROOT/.agent/workflows/$path"
      else
        echo "  SKIP agent-rule:$path (requires per-project install with --collab /path/to/project)"
      fi
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
    mcp)
      install_mcp_dir "$path"
      ;;
  esac
done

if $INSTALL_HAS_COLLAB; then
  ensure_collab_scaffold
fi

echo "────────────────────────────────────────────────────────"
echo "Done. Installed bundles: ${SELECTED_BUNDLES[*]}"
