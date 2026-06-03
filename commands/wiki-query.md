---
description: Answer a question from your LLM knowledge wiki with citations
argument-hint: "<your question>"
allowed-tools: Bash(sh:*), Read, Write, Edit, Glob, Grep, Bash(git:*)
---
Knowledge wiki directory (resolved): !`sh -c 'c="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge-wiki.path"; if [ -n "$KNOWLEDGE_WIKI_DIR" ]; then echo "$KNOWLEDGE_WIKI_DIR"; elif [ -f "$c" ]; then cat "$c"; else echo "$HOME/personal/knowledge-wiki"; fi'`

Use the path shown above as **WIKI**.

Answer a question using the knowledge wiki at `WIKI`, following Karpathy's
LLM-Wiki query flow.

Question: $ARGUMENTS

Steps:
1. Read `WIKI/index.md` to locate relevant pages, then read those pages (and
   any `WIKI/raw/` sources they cite if more depth is needed).
2. Synthesize a direct answer. **Cite** every claim with the wiki page it came
   from (relative path). If the wiki doesn't cover it, say so plainly — do not
   invent; suggest `/wiki-ingest` on a relevant source.
3. If the answer is durable, reusable, and not already a page, **offer to
   promote it**: create/update the right page (generic → topic folder,
   org-specific → org folder), and/or save a report under
   `WIKI/outputs/<YYYY-MM-DD>-<slug>.md`.
4. If you write anything, update `WIKI/index.md`, append a `QUERY:` line to
   `WIKI/log.md`, show a summary, and commit (no push unless asked). A pure
   read-only answer needs no commit.
