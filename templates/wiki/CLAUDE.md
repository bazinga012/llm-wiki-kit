# knowledge-wiki — schema & operating manual

An LLM-maintained personal knowledge base, after Andrej Karpathy's "LLM Wiki"
idea. **You (the LLM) own the `wiki/` and `outputs/` layers and do all the
bookkeeping. The human curates `raw/` sources and asks questions.**

## Layout

```
raw/        Immutable source material. READ ONLY — never edit a file here.
wiki/       LLM-authored pages. One concept/entity per file. Organized by TOPIC.
  <topic>/  Generic, reusable knowledge in well-defined topic folders
            (networking/, databases/, security/, llm-agents/, ...).
  <org>/    Company/project-specific knowledge (e.g. a folder per org).
outputs/    Synthesized answers, reports, analyses produced by queries.
index.md    Catalog of every wiki page, one-line summary, grouped by topic.
log.md      Append-only journal of ingests, queries, and lint passes.
```

### Where does a page go?
- **Generic knowledge → a topic folder**, never buried in an org folder. A
  reusable mechanism (e.g. a networking fix) goes under its topic.
- **Org/project-specific facts → that org's folder.** When an org page leans on
  a generic mechanism, **link** to the topic page rather than duplicating it.
- New topic? Create a new `wiki/<topic>/` folder and add it to `index.md`.

## Page format

```markdown
---
title: Human-readable title
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [raw/foo.md, https://...]   # provenance; omit if none yet
tags: [topic, subtopic]
---

## What it is
One-paragraph summary an LLM can read first and decide relevance.

## Details
The substance. Be specific and verifiable.

## See also
- [related page](../topic/other-page.md) — why it's related
```

**Backlinks** are relative markdown links; keep them bidirectional. Filenames
are `kebab-case.md`.

## Operations
- **Ingest** (`/capture`, `/wiki-ingest`) — read source → create/update pages →
  fix cross-links → update `index.md` → append `INGEST:` to `log.md`.
- **Query** (`/wiki-query`) — search pages → cited answer → promote durable
  answers to pages → append `QUERY:` to `log.md`.
- **Lint** (`/wiki-lint`) — health check: contradictions, stale facts, orphans,
  broken/missing links, provenance & coverage gaps → append `LINT:` to `log.md`.

## Conventions
- Dates absolute (`YYYY-MM-DD`), never "today/last week".
- Prefer verifiable specifics (commands, IDs, versions) over vague summaries.
- Don't duplicate — link. `raw/` is sacred: read, quote, cite — never modify.
