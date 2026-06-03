---
description: Health-check your LLM knowledge wiki (contradictions, stale, orphans, gaps)
argument-hint: "[optional: --fix to apply safe fixes]"
allowed-tools: Bash(sh:*), Bash(git:*), Read, Write, Edit, Glob, Grep
---

Knowledge wiki directory (resolved): !`sh -c 'c="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge-wiki.path"; if [ -n "$KNOWLEDGE_WIKI_DIR" ]; then echo "$KNOWLEDGE_WIKI_DIR"; elif [ -f "$c" ]; then cat "$c"; else echo "$HOME/personal/knowledge-wiki"; fi'`

Use the path shown above as **WIKI**. Run a health check ("lint") over the wiki,
following Karpathy's LLM-Wiki lint flow.

Mode: $ARGUMENTS  (default = report only; `--fix` = also apply safe fixes)

Steps:
1. Read `WIKI/CLAUDE.md`, `WIKI/index.md`, and walk `WIKI/wiki/`.
2. Report findings, grouped:
   - **Contradictions** — pages that disagree on a fact.
   - **Stale** — facts whose dates/context suggest they may be outdated; flag for
     the human to verify (don't silently delete).
   - **Orphans** — pages with no inbound links; broken/missing cross-links;
     `index.md` entries not matching files (or files missing from index).
   - **Provenance gaps** — pages with empty `sources:` that should cite `raw/`.
   - **Coverage gaps** — concepts referenced but never written up.
   - **Convention drift** — missing frontmatter, non-kebab filenames, generic
     knowledge mislocated in an org folder.
3. If `--fix`: apply only **safe, mechanical** fixes (repair backlinks, sync
   `index.md`, normalize frontmatter/filenames, relocate clearly-generic pages).
   Leave contradictions and stale-fact resolution as recommendations.
4. Append a `LINT:` line to `WIKI/log.md`. If you changed files, show a summary
   and commit (no push unless asked).
