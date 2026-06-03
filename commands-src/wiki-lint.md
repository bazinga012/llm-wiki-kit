---
name: wiki-lint
description: Health-check your LLM knowledge wiki (contradictions, stale, orphans, gaps)
argument-hint: "[optional: --fix to apply safe fixes]"
claude-tools: Read, Write, Edit, Glob, Grep, Bash(git:*)
---
Run a health check ("lint") over the knowledge wiki at `{{WIKI}}`, following
Karpathy's LLM-Wiki lint flow.

Mode: {{ARGS}}  (default = report only; `--fix` = also apply safe fixes)

Conventions to check against (full schema in `{{WIKI}}/AGENTS.md` if needed):
one concept per `kebab-case.md` page; generic knowledge under `wiki/<topic>/`,
org/project-specific in its org folder linking to the topic page; pages carry
frontmatter (`title, created, updated, sources, tags`) + `## What it is` +
`## Details` + `## See also`; bidirectional relative links; absolute dates.

Steps:
1. Read `{{WIKI}}/index.md` and walk `{{WIKI}}/wiki/`.
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
4. Append a `LINT:` line to `{{WIKI}}/log.md`. If you changed files, show a
   summary and commit (no push unless asked).
