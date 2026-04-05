#!/usr/bin/env python3
"""Patch ~/.claude/settings.json to register a Claude Code hook.

Usage: patch-hook-settings.py <hook_name>

Supported hooks: git-auto-pull, guard-trunk
"""
from __future__ import annotations

import json
import os
import sys

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
HOOKS_DIR = os.path.expanduser("~/.claude/hooks")

HOOK_REGISTRY: dict[str, dict] = {
    "git-auto-pull": {
        "managed": {"auto_pull.py"},
        "events": {
            "PreToolUse": [{
                "matcher": "Edit|Write|NotebookEdit",
                "hooks": [{"type": "command", "command": f"python3 {HOOKS_DIR}/auto_pull.py"}],
            }],
        },
    },
    "guard-trunk": {
        "managed": {"guard_trunk.py"},
        "events": {
            "PreToolUse": [{
                "matcher": "Edit|Write|NotebookEdit",
                "hooks": [{"type": "command", "command": f"python3 {HOOKS_DIR}/guard_trunk.py"}],
            }],
        },
    },
    "worknote-stop": {
        "managed": {"worknote_stop.sh"},
        "events": {
            "Stop": [{
                "matcher": "",
                "hooks": [{"type": "command", "command": f"bash {HOOKS_DIR}/worknote_stop.sh"}],
            }],
        },
    },
}


def patch(hook_name: str) -> None:
    config = HOOK_REGISTRY.get(hook_name)
    if not config:
        print(f"  WARNING: unknown hook '{hook_name}', skipping")
        return

    os.makedirs(os.path.dirname(SETTINGS_PATH), exist_ok=True)
    if not os.path.exists(SETTINGS_PATH):
        with open(SETTINGS_PATH, "w") as f:
            f.write("{}\n")

    with open(SETTINGS_PATH) as f:
        settings = json.load(f)

    managed = config["managed"]
    existing = settings.get("hooks", {})

    def is_managed(cmd: str) -> bool:
        return any(s in cmd for s in managed)

    def replace_list(old: list, new: list) -> list:
        filtered = [
            e for e in old
            if not any(is_managed(h.get("command", "")) for h in e.get("hooks", []))
        ]
        return filtered + new

    for event, entries in config["events"].items():
        existing[event] = replace_list(existing.get(event, []), entries)

    settings["hooks"] = existing

    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"  settings.json hooks registered for {hook_name}")


if __name__ == "__main__":
    patch(sys.argv[1])
