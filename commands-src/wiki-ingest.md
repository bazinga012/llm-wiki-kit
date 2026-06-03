---
name: wiki-ingest
description: Ingest a raw source (file, repo, or URL) into your LLM knowledge wiki
argument-hint: "<path or URL> [optional: what to focus on]"
claude-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), WebFetch
---
Ingest a **raw source document** into the knowledge wiki at `{{WIKI}}`,
following Karpathy's LLM-Wiki ingest flow.

Source: {{ARGS}}

Wiki conventions (consult `{{WIKI}}/AGENTS.md` only if you hit an edge case):
- One concept per page, `kebab-case.md`. Generic/reusable knowledge →
  `{{WIKI}}/wiki/<topic>/` (new topic folder if needed); org/project-specific →
  that org's folder, **linking** to the generic topic page rather than duplicating.
- Page = frontmatter (`title, created, updated, sources, tags`) + `## What it is`
  + `## Details` + `## See also` (bidirectional relative links). Set `sources:` to
  the `raw/` path/URL. Dates absolute (`YYYY-MM-DD`). `{{WIKI}}/raw/` is read-only.

Steps:
1. Acquire the source: local file → read it; URL → fetch it; repo → read
   README/key docs. Save a durable markdown copy/clip into `{{WIKI}}/raw/`
   (convert PDFs/HTML to md; large binaries are gitignored — keep extracted
   text). Name it `{{WIKI}}/raw/<YYYY-MM-DD>-<slug>.md`.
2. Skim `{{WIKI}}/index.md` to see existing pages (place correctly, avoid dupes).
3. Compile into the wiki per the conventions above — one source often touches
   several pages. Create/update pages and fix backlinks both directions.
4. Update `{{WIKI}}/index.md`; append an `INGEST:` line to `{{WIKI}}/log.md`.
5. Show a concise summary (pages + raw artifact), then commit in `{{WIKI}}`. No
   push unless asked.
