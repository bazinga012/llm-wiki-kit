---
name: capture
description: Capture durable knowledge from this session into your LLM knowledge wiki
argument-hint: "[optional: topic or what to focus on]"
claude-tools: Read, Write, Edit, Glob, Grep, Bash(git:*)
---
Ingest durable knowledge from **our current conversation** into the knowledge
wiki at `{{WIKI}}` — you already have this session in context, so mine it
directly; no transcript file needed.

Focus (optional): {{ARGS}}

Steps:
1. Read `{{WIKI}}/AGENTS.md` for the schema and conventions.
2. Scan this conversation for **durable, reusable** findings: non-obvious fixes,
   diagnostic procedures, infra facts, hard-won gotchas, decisions with rationale.
   **Skip** transient context, anything already in a repo's code/git history, and
   trivia. Curate aggressively — a few good pages beat a dump.
3. Ingest per the wiki's rules: generic knowledge → `{{WIKI}}/wiki/<topic>/` (new
   topic folder if needed); company/project-specific → the org folder, **linking**
   to the generic topic page instead of duplicating. Create/update pages
   (frontmatter + summary + details + See also), fixing backlinks both directions.
4. Update `{{WIKI}}/index.md` and append an `INGEST:` line to `{{WIKI}}/log.md`.
5. Show a concise summary (page paths + one line each), then commit in `{{WIKI}}`.
   Do not push unless asked.

If nothing clears the "durable + reusable" bar, say so and make no changes.
