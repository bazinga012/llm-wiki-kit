"""Agent-agnostic MCP server for a Karpathy-style LLM knowledge wiki.

Exposes the four wiki operations as MCP **prompts** (so any MCP client surfaces
them as slash commands) and a small set of **tools** scoped to the wiki
directory, so a client like Claude Desktop — which has no local file access of
its own — can read and maintain the wiki on its own.

Nothing here is specific to any one agent: the wiki path comes from the
environment (or the shared path file), and the prompts/tools are plain MCP.
"""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# --- resolve the wiki directory (agent-agnostic) -------------------------
def _resolve_wiki() -> Path:
    env = os.environ.get("KNOWLEDGE_WIKI_DIR")
    if env:
        return Path(env).expanduser()
    cfg_dir = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
    path_file = cfg_dir / "knowledge-wiki.path"
    if path_file.is_file():
        p = path_file.read_text().strip()
        if p:
            return Path(p).expanduser()
    return Path.home() / "personal" / "knowledge-wiki"


WIKI = _resolve_wiki().resolve()


# --- locate the neutral command bodies (single source of truth) ----------
def _resolve_prompts_dir() -> Path:
    override = os.environ.get("WIKI_MCP_PROMPTS_DIR")
    if override:
        return Path(override).expanduser()
    # repo checkout: <repo>/commands-src (keeps DRY when run via `uv run`)
    repo_src = Path(__file__).resolve().parents[2] / "commands-src"
    if repo_src.is_dir():
        return repo_src
    # bundled into the wheel by hatchling force-include
    return Path(__file__).resolve().parent / "prompts"


PROMPTS_DIR = _resolve_prompts_dir()


def _strip_frontmatter(text: str) -> str:
    m = re.match(r"^---\n.*?\n---\n?(.*)$", text, re.S)
    return m.group(1) if m else text


def _command_body(name: str, args: str) -> str:
    """Load commands-src/<name>.md, drop frontmatter, bake the wiki path and args."""
    f = PROMPTS_DIR / f"{name}.md"
    body = _strip_frontmatter(f.read_text())
    body = body.replace("{{WIKI}}", str(WIKI)).replace("{{ARGS}}", args or "")
    return body.strip() + "\n"


# --- path safety ----------------------------------------------------------
def _safe(rel: str) -> Path:
    """Resolve a wiki-relative path, refusing anything outside the wiki dir."""
    p = (WIKI / rel).resolve()
    if p != WIKI and WIKI not in p.parents:
        raise ValueError(f"path escapes the wiki directory: {rel}")
    return p


mcp = FastMCP("wiki")


# =========================== PROMPTS =====================================
# Each returns the corresponding command body with the wiki path baked in and
# the user's argument substituted. Clients show these as slash commands.

@mcp.prompt(name="capture", description="Capture durable knowledge from this session into the LLM knowledge wiki")
def capture(focus: str = "") -> str:
    return _command_body("capture", focus)


@mcp.prompt(name="wiki-ingest", description="Ingest a raw source (file, repo, or URL) into the LLM knowledge wiki")
def wiki_ingest(source: str = "") -> str:
    return _command_body("wiki-ingest", source)


@mcp.prompt(name="wiki-query", description="Answer a question from the LLM knowledge wiki with citations")
def wiki_query(question: str = "") -> str:
    return _command_body("wiki-query", question)


@mcp.prompt(name="wiki-lint", description="Health-check the LLM knowledge wiki (contradictions, stale, orphans, gaps)")
def wiki_lint(mode: str = "") -> str:
    return _command_body("wiki-lint", mode)


# ============================ TOOLS ======================================

@mcp.tool()
def wiki_info() -> str:
    """Return the wiki's absolute path and its schema/operating manual (AGENTS.md)."""
    schema = ""
    for name in ("AGENTS.md", "CLAUDE.md"):
        f = WIKI / name
        if f.is_file():
            schema = f.read_text()
            break
    return f"Wiki directory: {WIKI}\n\n{schema}".strip()


@mcp.tool()
def list_pages(subdir: str = ".", pattern: str = "**/*.md") -> str:
    """List files in the wiki matching a glob (default: all markdown). Paths are wiki-relative."""
    base = _safe(subdir)
    if not base.exists():
        return f"(no such path: {subdir})"
    hits = sorted(str(p.relative_to(WIKI)) for p in base.glob(pattern) if p.is_file())
    return "\n".join(hits) if hits else "(no matches)"


@mcp.tool()
def read_page(path: str) -> str:
    """Read a file from the wiki (wiki-relative path)."""
    p = _safe(path)
    if not p.is_file():
        return f"(no such file: {path})"
    return p.read_text()


@mcp.tool()
def write_page(path: str, content: str) -> str:
    """Create or overwrite a file in the wiki (wiki-relative path). Creates parent dirs."""
    p = _safe(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    return f"wrote {path} ({len(content)} bytes)"


@mcp.tool()
def append_log(line: str) -> str:
    """Append a single line to the wiki's log.md journal."""
    p = _safe("log.md")
    with p.open("a") as fh:
        fh.write(line.rstrip("\n") + "\n")
    return f"appended to log.md: {line.strip()}"


@mcp.tool()
def search_wiki(query: str, regex: bool = False, pattern: str = "**/*.md") -> str:
    """Search wiki files for a string (or regex). Returns 'relpath:lineno: line' matches."""
    try:
        rx = re.compile(query if regex else re.escape(query), re.I)
    except re.error as e:
        return f"(bad regex: {e})"
    out: list[str] = []
    for p in sorted(WIKI.glob(pattern)):
        if not p.is_file():
            continue
        try:
            for i, line in enumerate(p.read_text().splitlines(), 1):
                if rx.search(line):
                    out.append(f"{p.relative_to(WIKI)}:{i}: {line.strip()}")
                    if len(out) >= 200:
                        out.append("(truncated at 200 matches)")
                        return "\n".join(out)
        except (UnicodeDecodeError, OSError):
            continue
    return "\n".join(out) if out else "(no matches)"


@mcp.tool()
def git_commit(message: str) -> str:
    """Stage all changes in the wiki and commit them (no push). No-op if not a git repo or nothing to commit."""
    if not (WIKI / ".git").exists():
        return "(wiki is not a git repository; skipped commit)"
    subprocess.run(["git", "-C", str(WIKI), "add", "-A"], check=False, capture_output=True)
    r = subprocess.run(
        ["git", "-C", str(WIKI), "commit", "-m", message],
        check=False, capture_output=True, text=True,
    )
    return (r.stdout + r.stderr).strip() or "committed"


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
