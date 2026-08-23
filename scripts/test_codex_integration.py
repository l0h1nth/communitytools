#!/usr/bin/env python3
"""Smoke-test the repository's Codex wiring without starting Codex or MCP."""

from __future__ import annotations

import json
import re
import sys
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FRONTMATTER = re.compile(
    r"\A---\s*\n(?P<body>.*?)\n---\s*\n", re.DOTALL
)


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def check_skill_mirror() -> None:
    canonical_root = ROOT / "skills"
    mirror_root = ROOT / ".agents" / "skills"
    canonical = sorted(
        path.name for path in canonical_root.iterdir() if path.is_dir()
    )
    mirrored = sorted(path.name for path in mirror_root.iterdir())
    require(canonical == mirrored, "Codex skill mirror is out of sync")

    for name in canonical:
        source = canonical_root / name / "SKILL.md"
        mirror = mirror_root / name
        require(source.is_file(), f"missing SKILL.md for {name}")
        require(mirror.is_symlink(), f"{mirror} is not a symlink")
        require(mirror.resolve() == (canonical_root / name).resolve(),
                f"mirror target is wrong for {name}")
        text = source.read_text(encoding="utf-8")
        match = FRONTMATTER.match(text)
        require(match is not None, f"invalid frontmatter for {name}")
        body = match.group("body")
        require(re.search(r"(?m)^name:\s*[^\s]+\s*$", body) is not None,
                f"frontmatter name missing for {name}")
        require(re.search(r"(?m)^description:\s*.+$", body) is not None,
                f"frontmatter description missing for {name}")


def check_plugin() -> None:
    manifest_path = ROOT / ".codex-plugin" / "plugin.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for key in ("name", "version", "description", "author", "interface"):
        require(key in manifest, f"plugin manifest missing {key}")
    require((ROOT / manifest["skills"]).is_dir(),
            "plugin skill path does not exist")


def check_project_config() -> None:
    config = tomllib.loads(
        (ROOT / ".codex" / "config.toml").read_text(encoding="utf-8")
    )
    server = config.get("mcp_servers", {}).get("transilience_vuln")
    require(server is not None, "transilience_vuln MCP server is not configured")
    require(server["command"] == "python3", "MCP command should be python3")
    require(server["args"] == ["mcp/transilience-vuln/server.py"],
            "MCP server path changed unexpectedly")
    require("TRANSILIENCE_API_KEY" in server["env_vars"],
            "MCP config must inherit TRANSILIENCE_API_KEY")

    agents_root = ROOT / ".codex" / "agents"
    agent_names = sorted(path.stem for path in agents_root.glob("*.toml"))
    require(agent_names == ["coordinator", "executor", "skeptic", "validator"],
            "named Codex agents are incomplete")
    for path in agents_root.glob("*.toml"):
        agent = tomllib.loads(path.read_text(encoding="utf-8"))
        for key in ("name", "description", "developer_instructions"):
            require(key in agent, f"{path.name} missing {key}")


def main() -> int:
    require((ROOT / "AGENTS.md").is_file(), "root AGENTS.md is missing")
    check_skill_mirror()
    check_plugin()
    check_project_config()
    print("Codex integration checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
