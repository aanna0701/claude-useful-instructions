#!/usr/bin/env python3
"""Parse branch-map.yaml for hub-and-spoke auto-sync workflow.

Usage:
  parse-branch-map.py merge-target <branch_map> <trigger>
  parse-branch-map.py children     <branch_map> <trigger> <sync_source>
  parse-branch-map.py grandchildren <branch_map> <trigger> <child>
"""
from __future__ import annotations

import subprocess
import sys

import yaml


def _load(path: str) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def merge_target(data: dict, trigger: str) -> str:
    """Return merge target: explicit config or working_parent fallback."""
    branches = data.get("branches", {}) or {}
    if trigger in branches and branches[trigger].get("merge_target"):
        return branches[trigger]["merge_target"]
    wp = data.get("working_parent", "")
    if wp and trigger != wp:
        return wp
    return ""


def children(data: dict, trigger: str, sync_source: str) -> str:
    """Return space-separated child branches (explicit + auto-detected)."""
    branches = data.get("branches", {}) or {}
    feature_prefix = data.get("branch_rules", {}).get("feature_prefix", "feat")

    explicit = set()
    explicit_parents: dict[str, str] = {}
    for name, cfg in branches.items():
        parent = cfg.get("parent", "")
        explicit_parents[name] = parent
        if parent == sync_source and name != trigger:
            explicit.add(name)

    # Auto-detect remote feature branches when syncing from hub
    auto: set[str] = set()
    wp = data.get("working_parent", "")
    if sync_source == wp:
        result = subprocess.run(
            ["git", "branch", "-r", "--format=%(refname:short)"],
            capture_output=True, text=True,
        )
        prefixes = ("origin/feature-", "origin/feat/", f"origin/{feature_prefix}/")
        for line in result.stdout.strip().split("\n"):
            line = line.strip()
            if not line or not any(line.startswith(p) for p in prefixes):
                continue
            branch = line.removeprefix("origin/")
            if branch in (trigger, sync_source):
                continue
            if branch in explicit_parents and explicit_parents[branch] != sync_source:
                continue
            auto.add(branch)

    return " ".join(sorted(explicit | auto))


def grandchildren(data: dict, trigger: str, child: str) -> str:
    """Return space-separated grandchild branches (explicit only)."""
    branches = data.get("branches", {}) or {}
    result = []
    for name, cfg in branches.items():
        if cfg.get("parent", "") == child and name != trigger:
            result.append(name)
    return " ".join(sorted(result))


def main() -> None:
    cmd = sys.argv[1]
    branch_map = sys.argv[2]

    try:
        data = _load(branch_map)
    except FileNotFoundError:
        sys.exit(0)

    if cmd == "merge-target":
        print(merge_target(data, trigger=sys.argv[3]))
    elif cmd == "children":
        print(children(data, trigger=sys.argv[3], sync_source=sys.argv[4]))
    elif cmd == "grandchildren":
        print(grandchildren(data, trigger=sys.argv[3], child=sys.argv[4]))


if __name__ == "__main__":
    main()
