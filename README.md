# llm-wiki-kit

Slash commands + setup for a **Karpathy-style LLM knowledge wiki** — a
self-maintaining, interlinked markdown knowledge base the LLM compiles and
curates for you. This repo is the *tooling*; your *content* lives in a separate,
configurable wiki directory.

**Cross-agent.** The same commands and the same wiki work across Claude Code,
Gemini CLI, Codex CLI, opencode, Cursor, and Antigravity — knowledge always
lands in one shared, agent-agnostic wiki directory, no matter which agent you
ran the command from.

## Commands
| Command | Does |
|---------|------|
| `/capture [focus]` | Ingest durable knowledge from the **current session** |
| `/wiki-ingest <path\|url>` | Ingest a **raw source** (doc, repo, web page) |
| `/wiki-query <question>` | Cited answer from the wiki; promote good answers to pages |
| `/wiki-lint [--fix]` | Health check: contradictions, stale facts, orphans, gaps |

## Install — `setup.sh`
```bash
scripts/setup.sh                                  # autodetect installed agents
scripts/setup.sh --agents all                     # install for all six
scripts/setup.sh --agents claude,gemini,codex     # pick a subset
scripts/setup.sh --wiki-dir ~/notes/wiki          # custom shared wiki location
```
For each selected agent it: renders the commands into that agent's command
directory, appends a knowledge-wiki instruction block to the agent's memory file
(idempotent, marker-guarded), bootstraps the shared wiki (without overwriting
existing content), and records the wiki path.

With no `--agents`, it autodetects every agent whose config directory exists
(falling back to `claude`).

### Per-agent targets
| Agent | Command dir | Format | Args | Memory file | Root override |
|-------|-------------|--------|------|-------------|---------------|
| Claude Code | `commands/*.md` | md + frontmatter | `$ARGUMENTS` | `CLAUDE.md` | `CLAUDE_CONFIG_DIR` |
| Gemini CLI | `commands/*.toml` | TOML | `{{args}}` | `GEMINI.md` | `GEMINI_DIR` |
| Codex CLI | `prompts/*.md` | md | `$ARGUMENTS` | `AGENTS.md` | `CODEX_HOME` |
| opencode | `command/*.md` | md + frontmatter | `$ARGUMENTS` | `AGENTS.md` | `OPENCODE_CONFIG` |
| Cursor | `commands/*.md` | md | inline hint¹ | `rules/llm-wiki-kit.mdc`² | `CURSOR_DIR` |
| Antigravity | `config/global_workflows/*.md`³ | md | inline hint¹ | shared `GEMINI.md`⁴ | `ANTIGRAVITY_DIR` |

¹ Cursor/Antigravity insert-and-edit the prompt rather than expanding an args
token, so the command ships with an editable `<placeholder>` instead.
² Cursor rules are project-scoped; for a truly global rule, paste the snippet
into Cursor → Settings → Rules (User Rules).
³ Antigravity is a slash-command = **workflow**. User-global workflows live in
the single shared `~/.gemini/config/global_workflows/` (used by both the
`antigravity` and `antigravity-ide` variants). Per-project workflows/rules go in
a repo's `.agent/workflows/` & `.agent/rules/`.
⁴ Antigravity surfaces `~/.gemini/GEMINI.md` as a global Rule, so the kit's
instruction snippet installs there (shared with Gemini CLI).

## Claude Desktop & other MCP clients (`mcp/`)
Claude Desktop has no file-based commands and is sandboxed, so it's wired up via
a **standalone, agent-agnostic MCP server** in `mcp/`. It exposes the same four
commands as MCP **prompts** (shown in the client's `/` menu) plus **tools**
scoped to the wiki dir (`read_page`, `write_page`, `list_pages`, `search_wiki`,
`append_log`, `git_commit`, `wiki_info`) so a sandboxed client can maintain the
wiki on its own. Nothing in it is Claude-specific — any MCP client can use it.

```bash
scripts/register-mcp.py claude-desktop                 # default
scripts/register-mcp.py all                            # every supported client
scripts/register-mcp.py cursor gemini antigravity opencode codex
```
The registrar merges a `wiki` server entry into each client's config in the
right shape (`mcpServers` JSON for Claude Desktop/Cursor/Gemini/Antigravity, the
`mcp` block for opencode, `[mcp_servers.wiki]` TOML for Codex), idempotently and
with a `.bak`. Restart the client afterwards. See `mcp/README.md` for details.

> The CLI/IDE agents above already get **native** commands via `setup.sh`; the
> MCP server is mainly for Claude Desktop, but works as an alternative anywhere.

## Configurable wiki path
The shared wiki directory is resolved (by `setup.sh` and by the Claude plugin's
runtime resolver) in this order:
1. `$KNOWLEDGE_WIKI_DIR`
2. `$CLAUDE_CONFIG_DIR/knowledge-wiki.path` (written by setup)
3. default `~/personal/knowledge-wiki`

`setup.sh` **bakes the resolved absolute path** into each agent's commands so it
works even on agents without shell injection. Move the wiki → re-run `setup.sh`.

## Claude Code plugin (optional)
Claude users can alternatively install via the plugin marketplace, which uses a
runtime path resolver instead of a baked path:
```bash
claude plugin marketplace add <owner>/llm-wiki-kit   # or a local path
claude plugin install llm-wiki-kit
```
Then run `scripts/setup.sh --wiki-dir ...` once (or set `KNOWLEDGE_WIKI_DIR`) to
bootstrap and point at your wiki.

## How it's built (single source of truth)
- `commands-src/*.md` — agent-neutral command bodies with `{{WIKI}}` and
  `{{ARGS}}` tokens. **Edit commands here.**
- `scripts/render.sh <agent> <wiki_dir> <src>` — renders one source into a given
  agent's format. Adding an agent = extending its case statements.
- `scripts/setup.sh` — resolves the wiki path, then renders + installs for each
  selected agent.
- `commands/*.md` — the committed Claude **plugin** payload, regenerated from
  `commands-src/` via `render.sh claude @dynamic` (runtime resolver). Regenerate
  after editing a source.

## Layout of the wiki it manages
```
raw/        immutable sources (read-only)
wiki/<topic>/   generic, reusable knowledge
wiki/<org>/     org/project-specific knowledge (links to topic pages)
outputs/    synthesized reports
index.md    catalog · log.md  append-only journal
AGENTS.md   the canonical schema (CLAUDE.md / GEMINI.md are thin pointers to it)
```

Based on Andrej Karpathy's "LLM Wiki" idea.
