#!/usr/bin/env bash
# merge-lock.sh — flock-based serialization for merge operations.
#
# Usage:
#   source lib/merge-lock.sh
#   acquire_merge_lock || { echo "Another merge in progress"; exit 1; }
#   # ... do merge ...
#   release_merge_lock

_MERGE_LOCK_DIR="work/locks"
_MERGE_LOCK_FILE="$_MERGE_LOCK_DIR/merge.lock"
_MERGE_LOCK_FD=""

acquire_merge_lock() {
  mkdir -p "$_MERGE_LOCK_DIR"
  exec {_MERGE_LOCK_FD}>"$_MERGE_LOCK_FILE"
  if ! flock -n "$_MERGE_LOCK_FD"; then
    echo "    ⚠ Another merge is in progress (lock: $_MERGE_LOCK_FILE). Waiting up to 60s..."
    if ! flock -w 60 "$_MERGE_LOCK_FD"; then
      echo "    ✗ Could not acquire merge lock after 60s. Aborting."
      exec {_MERGE_LOCK_FD}>&-
      _MERGE_LOCK_FD=""
      return 1
    fi
  fi
  echo "$$" >&"$_MERGE_LOCK_FD"
  return 0
}

release_merge_lock() {
  if [ -n "$_MERGE_LOCK_FD" ]; then
    flock -u "$_MERGE_LOCK_FD" 2>/dev/null || true
    exec {_MERGE_LOCK_FD}>&- 2>/dev/null || true
    _MERGE_LOCK_FD=""
  fi
}

# Auto-release on exit if sourced
trap 'release_merge_lock' EXIT
