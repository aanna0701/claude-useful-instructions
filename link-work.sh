#!/usr/bin/env bash
# link-work.sh — Manage work/ symlinks across git worktrees
#
# Can be run from ANY worktree in the repo — auto-detects the docs worktree
# (the one containing work/items/).
#
# Usage:
#   link-work.sh                        # Link work/ to all worktrees
#   link-work.sh training               # Link to matching worktree (partial match)
#   link-work.sh --status               # Show symlink status across all worktrees
#   link-work.sh --clean                # Remove all work/ symlinks
#   link-work.sh --init <name> <branch> # Create new worktree + link work/ + gitignore
#   link-work.sh --self-install         # Install as `git work-link` alias

set -euo pipefail

# ─── Auto-detect repo from current directory ──────────────────────────────────
find_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

REPO_ROOT=$(find_repo_root)
if [[ -z "$REPO_ROOT" ]]; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# ─── Find the docs worktree (contains work/items/) ───────────────────────────
DOCS_WORKTREE=""
while IFS= read -r line; do
    wt_path="${line#worktree }"
    if [[ -d "$wt_path/work/items" && ! -L "$wt_path/work" ]]; then
        DOCS_WORKTREE="$wt_path"
        break
    fi
done < <(git -C "$REPO_ROOT" worktree list --porcelain | grep "^worktree ")

if [[ -z "$DOCS_WORKTREE" && "${1:-}" != "--init" && "${1:-}" != "--self-install" && "${1:-}" != "-h" && "${1:-}" != "--help" ]]; then
    echo "Error: No worktree found with work/items/ directory"
    echo "Hint: Create a work/items/ directory in your planning worktree first."
    exit 1
fi

WORK_SOURCE="${DOCS_WORKTREE:+$DOCS_WORKTREE/work}"

# ─── Helpers ──────────────────────────────────────────────────────────────────

get_targets() {
    local filter="${1:-}"
    while IFS= read -r line; do
        local wt_path="${line#worktree }"
        [[ "$wt_path" == "$DOCS_WORKTREE" ]] && continue
        if [[ -n "$filter" ]]; then
            local lower_path="${wt_path,,}"
            local lower_filter="${filter,,}"
            [[ "$lower_path" != *"$lower_filter"* ]] && continue
        fi
        echo "$wt_path"
    done < <(git -C "$REPO_ROOT" worktree list --porcelain | grep "^worktree ")
}

ensure_gitignore() {
    local wt="$1"
    if ! grep -qx "work/" "$wt/.gitignore" 2>/dev/null; then
        echo "" >> "$wt/.gitignore"
        echo "# Symlinked work plans from docs worktree" >> "$wt/.gitignore"
        echo "work/" >> "$wt/.gitignore"
    fi
}

get_branch() {
    local wt="$1"
    git -C "$REPO_ROOT" worktree list --porcelain \
        | awk -v wt="$wt" '/^worktree /{w=$2} /^branch /{if(w==wt) print $2}' \
        | sed 's|refs/heads/||'
}

# ─── Commands ─────────────────────────────────────────────────────────────────

cmd_status() {
    echo "Docs worktree: ${DOCS_WORKTREE:-<not found>}"
    echo "Work source:   ${WORK_SOURCE:-<not found>}"
    echo ""

    local items_count=0
    if [[ -d "${WORK_SOURCE:-}/items" ]]; then
        items_count=$(find "$WORK_SOURCE/items" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    fi
    echo "Work items:    $items_count"
    echo ""

    printf "%-40s %-20s %s\n" "WORKTREE" "BRANCH" "STATUS"
    printf "%-40s %-20s %s\n" "--------" "------" "------"

    while IFS= read -r line; do
        local wt="${line#worktree }"
        local name branch status_str
        name=$(basename "$wt")
        branch=$(get_branch "$wt")

        if [[ "$wt" == "$DOCS_WORKTREE" ]]; then
            status_str="[source] work/items/"
        elif [[ -L "$wt/work" ]]; then
            status_str="linked -> $(readlink "$wt/work")"
        elif [[ -d "$wt/work" ]]; then
            status_str="!! real directory (not symlink)"
        else
            status_str="-- not linked"
        fi
        printf "%-40s %-20s %s\n" "$name" "$branch" "$status_str"
    done < <(git -C "$REPO_ROOT" worktree list --porcelain | grep "^worktree ")
}

cmd_clean() {
    local count=0
    while IFS= read -r wt; do
        [[ -z "$wt" ]] && continue
        if [[ -L "$wt/work" ]]; then
            rm "$wt/work"
            echo "Removed: $(basename "$wt")/work"
            ((count++)) || true
        fi
    done < <(get_targets)
    echo "Cleaned $count symlink(s)."
}

cmd_link() {
    local filter="${1:-}"
    local count=0
    while IFS= read -r wt; do
        [[ -z "$wt" ]] && continue
        local name
        name=$(basename "$wt")

        if [[ -L "$wt/work" ]]; then
            echo "Skip: $name (already linked)"
            continue
        fi
        if [[ -d "$wt/work" ]]; then
            echo "Skip: $name (real work/ directory — remove manually if intended)"
            continue
        fi

        ln -s "$WORK_SOURCE" "$wt/work"
        ensure_gitignore "$wt"
        echo "Linked: $name/work -> $WORK_SOURCE"
        ((count++)) || true
    done < <(get_targets "$filter")

    if [[ $count -eq 0 ]]; then
        echo "No new links created. (Use --status to see current state)"
    else
        echo "Done. $count worktree(s) linked."
    fi
}

cmd_init() {
    local name="${1:?Usage: link-work.sh --init <name> <branch>}"
    local branch="${2:?Usage: link-work.sh --init <name> <branch>}"
    local parent_dir
    parent_dir=$(dirname "$(git -C "$REPO_ROOT" worktree list --porcelain | grep "^worktree " | head -1 | sed 's/^worktree //')")
    local wt_path="$parent_dir/$name"

    if [[ -d "$wt_path" ]]; then
        echo "Error: $wt_path already exists"
        exit 1
    fi

    echo "Creating worktree: $wt_path (branch: $branch)"
    git -C "$REPO_ROOT" worktree add "$wt_path" -b "$branch" 2>/dev/null \
        || git -C "$REPO_ROOT" worktree add "$wt_path" "$branch"

    if [[ -n "$WORK_SOURCE" && -d "$WORK_SOURCE" ]]; then
        ln -s "$WORK_SOURCE" "$wt_path/work"
        ensure_gitignore "$wt_path"
        echo "Linked: $name/work -> $WORK_SOURCE"
    fi

    echo ""
    echo "Ready. cd $wt_path"
}

cmd_self_install() {
    local script_path
    script_path=$(readlink -f "$0")
    git config --global alias.work-link "!bash $script_path"
    echo "Installed. Use: git work-link [args]"
    echo ""
    echo "Examples:"
    echo "  git work-link                         # Link all worktrees"
    echo "  git work-link training                # Link specific worktree"
    echo "  git work-link --status                # Show status"
    echo "  git work-link --init MyNew feature-x  # Create worktree + link"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
    --status|-s)
        cmd_status
        ;;
    --clean|-c)
        cmd_clean
        ;;
    --init|-i)
        shift
        cmd_init "$@"
        ;;
    --self-install)
        cmd_self_install
        ;;
    --help|-h)
        echo "Usage: link-work.sh [command|filter]"
        echo ""
        echo "Commands:"
        echo "  (no args)                  Link work/ to all worktrees"
        echo "  <filter>                   Link to matching worktrees (partial match)"
        echo "  --status, -s               Show symlink status"
        echo "  --clean, -c                Remove all work/ symlinks"
        echo "  --init, -i <name> <branch> Create new worktree with work/ linked"
        echo "  --self-install             Install as git alias: git work-link"
        echo "  --help, -h                 Show this help"
        ;;
    *)
        cmd_link "${1:-}"
        ;;
esac
