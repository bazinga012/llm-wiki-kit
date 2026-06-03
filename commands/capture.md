---
description: Capture durable knowledge from this session into your LLM knowledge wiki
argument-hint: "[optional: topic or what to focus on]"
allowed-tools: Bash(sh:*), Read, Write, Edit, Glob, Grep, Bash(git:*)
---
Knowledge wiki directory (resolved): !`sh -c 'c="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge-wiki.path"; if [ -n "$KNOWLEDGE_WIKI_DIR" ]; then echo "$KNOWLEDGE_WIKI_DIR"; elif [ -f "$c" ]; then cat "$c"; else echo "$HOME/personal/knowledge-wiki"; fi'`

Use the path shown above as **WIKI**.

Ingest durable knowledge from **our current conversation** into the knowledge
wiki at `WIKI` — you already have this session in context, so mine it
directly; no transcript file needed.

Focus (optional): $ARGUMENTS

Wiki conventions (consult `WIKI/AGENTS.md` only if you hit an edge case):
- One concept per page, `kebab-case.md`. Generic/reusable knowledge →
  `WIKI/wiki/<topic>/` (new topic folder if needed); org/project-specific →
  that org's folder, **linking** to the generic topic page rather than duplicating.
- Page = frontmatter (`title, created, updated, sources, tags`) + `## What it is`
  + `## Details` + `## See also` (bidirectional relative links). Dates absolute
  (`YYYY-MM-DD`). Prefer verifiable specifics. `WIKI/raw/` is read-only.

Steps:
1. Skim `WIKI/index.md` (the page catalog) to see existing topics/pages, so
   you place new knowledge correctly and avoid duplicates. Open a specific page
   only if you're updating it.
2. Scan this conversation for **durable, reusable** findings: non-obvious fixes,
   diagnostic procedures, infra facts, hard-won gotchas, decisions with rationale.
   **Skip** transient context, anything already in a repo's code/git history, and
   trivia. Curate aggressively — a few good pages beat a dump.
3. Create/update pages per the conventions above, fixing backlinks both directions.
4. Update `WIKI/index.md` and append an `INGEST:` line to `WIKI/log.md`.
5. Show a concise summary (page paths + one line each), then commit in `WIKI`.
   Do not push unless asked.

If nothing clears the "durable + reusable" bar, say so and make no changes.
