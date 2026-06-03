# llm-wiki-kit

Slash commands + setup for a **Karpathy-style LLM knowledge wiki** — a
self-maintaining, interlinked markdown knowledge base the LLM compiles and
curates for you. This repo is the *tooling* (a Claude Code plugin); your
*content* lives in a separate, configurable wiki directory.

## Commands
| Command | Does |
|---------|------|
| `/capture [focus]` | Ingest durable knowledge from the **current session** |
| `/wiki-ingest <path\|url>` | Ingest a **raw source** (doc, repo, web page) |
| `/wiki-query <question>` | Cited answer from the wiki; promote good answers to pages |
| `/wiki-lint [--fix]` | Health check: contradictions, stale facts, orphans, gaps |

## Configurable wiki path
Commands resolve the wiki directory at runtime, in this order:
1. `$KNOWLEDGE_WIKI_DIR`
2. `$CLAUDE_CONFIG_DIR/knowledge-wiki.path` (a file containing the path)
3. default `~/personal/knowledge-wiki`

`scripts/kw-path.sh` is the shared resolver.

## Install

### Option A — setup script (installs into your Claude config dir)
```bash
scripts/setup.sh                          # defaults
scripts/setup.sh --wiki-dir ~/notes/wiki  # custom wiki location
scripts/setup.sh --config-dir ~/.claude-work   # custom Claude config dir
```
It copies the commands into `<config-dir>/commands/`, writes
`<config-dir>/knowledge-wiki.path`, bootstraps the wiki directory (without
overwriting existing content), and adds a global instruction block to
`<config-dir>/CLAUDE.md` (idempotent, marker-guarded).

### Option B — as a Claude Code plugin
```bash
claude plugin marketplace add <owner>/llm-wiki-kit   # or a local path
claude plugin install llm-wiki-kit
```
Set `KNOWLEDGE_WIKI_DIR` or run `scripts/setup.sh --wiki-dir ...` once to point
at your wiki.

## Layout of the wiki it manages
```
raw/        immutable sources (read-only)
wiki/<topic>/   generic, reusable knowledge
wiki/<org>/     org/project-specific knowledge (links to topic pages)
outputs/    synthesized reports
index.md    catalog · log.md  append-only journal · CLAUDE.md  the schema
```

Based on Andrej Karpathy's "LLM Wiki" idea.
