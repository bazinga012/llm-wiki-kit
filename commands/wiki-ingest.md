---
description: Ingest a raw source (file, repo, or URL) into your LLM knowledge wiki
argument-hint: "<path or URL> [optional: what to focus on]"
allowed-tools: Bash(sh:*), Read, Write, Edit, Glob, Grep, Bash(git:*), WebFetch
---
Knowledge wiki directory (resolved): !`sh -c 'c="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge-wiki.path"; if [ -n "$KNOWLEDGE_WIKI_DIR" ]; then echo "$KNOWLEDGE_WIKI_DIR"; elif [ -f "$c" ]; then cat "$c"; else echo "$HOME/personal/knowledge-wiki"; fi'`

Use the path shown above as **WIKI**.

Ingest a **raw source document** into the knowledge wiki at `WIKI`,
following Karpathy's LLM-Wiki ingest flow.

Source: $ARGUMENTS

Steps:
1. Read `WIKI/AGENTS.md` for the schema and conventions.
2. Acquire the source: local file → read it; URL → fetch it; repo → read
   README/key docs. Save a durable markdown copy/clip into `WIKI/raw/`
   (convert PDFs/HTML to md; large binaries are gitignored — keep extracted
   text). Name it `WIKI/raw/<YYYY-MM-DD>-<slug>.md`.
3. Compile into the wiki: identify the concepts the source covers (one source
   often touches several pages). Create/update pages — generic/reusable →
   `WIKI/wiki/<topic>/` (new topic folder if needed); company/project-specific →
   the org folder, **linking** to the generic topic page rather than duplicating.
   Set `sources:` to the `raw/` path/URL. Fix backlinks both directions.
4. Update `WIKI/index.md`; append an `INGEST:` line to `WIKI/log.md`.
5. Show a concise summary (pages + raw artifact), then commit in `WIKI`. No
   push unless asked.
