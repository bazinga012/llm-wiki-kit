#!/usr/bin/env python3
"""Register the standalone wiki MCP server with one or more MCP clients.

The server itself (mcp/) is agent-agnostic; this just writes the right config
shape per client and is idempotent (re-running updates the entry in place).

Usage:
    scripts/register-mcp.py [--wiki-dir PATH] [--name NAME] CLIENT [CLIENT ...]

Clients: claude-desktop cursor gemini antigravity opencode codex  (or "all")
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MCP_DIR = REPO / "mcp"
HOME = Path.home()

CLIENTS = ["claude-desktop", "cursor", "gemini", "antigravity", "opencode", "codex"]


def resolve_wiki(explicit: str | None) -> str:
    if explicit:
        return str(Path(explicit).expanduser())
    env = os.environ.get("KNOWLEDGE_WIKI_DIR")
    if env:
        return str(Path(env).expanduser())
    cfg = Path(os.environ.get("CLAUDE_CONFIG_DIR", HOME / ".claude")) / "knowledge-wiki.path"
    if cfg.is_file() and cfg.read_text().strip():
        return cfg.read_text().strip()
    return str(HOME / "personal" / "knowledge-wiki")


def config_path(client: str) -> Path:
    return {
        "claude-desktop": HOME / "Library/Application Support/Claude/claude_desktop_config.json",
        "cursor": HOME / ".cursor/mcp.json",
        "gemini": HOME / ".gemini/settings.json",
        "antigravity": HOME / ".gemini/config/mcp_config.json",
        "opencode": HOME / ".config/opencode/opencode.json",
        "codex": HOME / ".codex/config.toml",
    }[client]


def load_json(p: Path) -> dict:
    if p.is_file() and p.read_text().strip():
        return json.loads(p.read_text())
    return {}


def backup(p: Path) -> None:
    if p.is_file():
        shutil.copy2(p, p.with_suffix(p.suffix + ".bak"))


def write_json(p: Path, data: dict) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    backup(p)
    p.write_text(json.dumps(data, indent=2) + "\n")


def register_json_mcpservers(client: str, p: Path, name: str, uv: str, wiki: str) -> None:
    """Shape shared by Claude Desktop, Cursor, Gemini, Antigravity."""
    data = load_json(p)
    servers = data.setdefault("mcpServers", {})
    servers[name] = {
        "command": uv,
        "args": ["run", "--directory", str(MCP_DIR), "wiki-mcp"],
        "env": {"KNOWLEDGE_WIKI_DIR": wiki},
    }
    write_json(p, data)


def register_opencode(p: Path, name: str, uv: str, wiki: str) -> None:
    data = load_json(p)
    data.setdefault("$schema", "https://opencode.ai/config.json")
    mcp = data.setdefault("mcp", {})
    mcp[name] = {
        "type": "local",
        "command": [uv, "run", "--directory", str(MCP_DIR), "wiki-mcp"],
        "environment": {"KNOWLEDGE_WIKI_DIR": wiki},
        "enabled": True,
    }
    write_json(p, data)


def register_codex(p: Path, name: str, uv: str, wiki: str) -> None:
    block = (
        f"[mcp_servers.{name}]\n"
        f'command = "{uv}"\n'
        f'args = ["run", "--directory", "{MCP_DIR}", "wiki-mcp"]\n'
        f'env = {{ KNOWLEDGE_WIKI_DIR = "{wiki}" }}\n'
    )
    text = p.read_text() if p.is_file() else ""
    # drop any existing [mcp_servers.<name>] section (until next [section] or EOF)
    text = re.sub(
        rf"(?ms)^\[mcp_servers\.{re.escape(name)}\]\s*\n.*?(?=^\[|\Z)", "", text
    ).rstrip()
    new = (text + "\n\n" + block) if text else block
    p.parent.mkdir(parents=True, exist_ok=True)
    backup(p)
    p.write_text(new.lstrip("\n"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("clients", nargs="+", help='one or more of: %s (or "all")' % " ".join(CLIENTS))
    ap.add_argument("--wiki-dir", help="wiki directory to pin (default: resolved like the kit)")
    ap.add_argument("--name", default="wiki", help="MCP server name (default: wiki)")
    args = ap.parse_args()

    uv = shutil.which("uv") or "uv"
    wiki = resolve_wiki(args.wiki_dir)
    clients = CLIENTS if args.clients == ["all"] else args.clients

    print(f"server : uv run --directory {MCP_DIR} wiki-mcp")
    print(f"wiki   : {wiki}")
    print(f"name   : {args.name}\n")

    rc = 0
    for c in clients:
        if c not in CLIENTS:
            print(f"  [skip] unknown client: {c}"); rc = 1; continue
        p = config_path(c)
        try:
            if c in ("claude-desktop", "cursor", "gemini", "antigravity"):
                register_json_mcpservers(c, p, args.name, uv, wiki)
            elif c == "opencode":
                register_opencode(p, args.name, uv, wiki)
            elif c == "codex":
                register_codex(p, args.name, uv, wiki)
            print(f"  [{c}] -> {p}")
        except Exception as e:  # noqa: BLE001
            print(f"  [{c}] FAILED: {e}"); rc = 1
    print("\nRestart the client(s) to load the wiki MCP server.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
