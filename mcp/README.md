# wiki-mcp

An **agent-agnostic** MCP server for a Karpathy-style LLM knowledge wiki. It is
not tied to any single client — any MCP-capable agent (Claude Desktop, Claude
Code, Cursor, Gemini CLI, Codex, opencode, Antigravity, …) can use it.

It exposes:

- **Prompts** (shown as slash commands by the client): `capture`,
  `wiki-ingest`, `wiki-query`, `wiki-lint` — the same four commands as the rest
  of the kit, loaded from the shared `commands-src/` bodies.
- **Tools** scoped to the wiki directory, so a sandboxed client (e.g. Claude
  Desktop) can read and maintain the wiki by itself: `wiki_info`, `list_pages`,
  `read_page`, `write_page`, `append_log`, `search_wiki`, `git_commit`.

## Wiki location
Resolved the same way as the rest of the kit:
1. `$KNOWLEDGE_WIKI_DIR`
2. `$CLAUDE_CONFIG_DIR/knowledge-wiki.path`
3. default `~/personal/knowledge-wiki`

Pass `KNOWLEDGE_WIKI_DIR` in the MCP server's `env` to pin it explicitly.

## Run it
```bash
uv run --directory /path/to/llm-wiki-kit/mcp wiki-mcp     # stdio MCP server
```

## Register it with a client
Use the generic registrar (idempotent), which writes the correct config shape
per client:
```bash
scripts/register-mcp.py claude-desktop          # default
scripts/register-mcp.py cursor gemini antigravity opencode codex
scripts/register-mcp.py --wiki-dir ~/notes/wiki claude-desktop
```
Or add it by hand — most clients use the `mcpServers` JSON shape:
```json
{
  "mcpServers": {
    "wiki": {
      "command": "uv",
      "args": ["run", "--directory", "/path/to/llm-wiki-kit/mcp", "wiki-mcp"],
      "env": { "KNOWLEDGE_WIKI_DIR": "/path/to/your/wiki" }
    }
  }
}
```
