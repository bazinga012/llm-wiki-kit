## Knowledge wiki
A persistent, LLM-maintained knowledge base lives at the path resolved by
`KNOWLEDGE_WIKI_DIR` → `$CLAUDE_CONFIG_DIR/knowledge-wiki.path` → default
`~/personal/knowledge-wiki` (Karpathy "LLM Wiki" pattern). It holds durable,
cross-session knowledge: generic/reusable facts in topic folders
(`wiki/<topic>/`), org/project-specific facts in their own folders. Its own
`CLAUDE.md` defines the full ingest / query / lint workflow.

Commands: `/capture` (ingest current session) · `/wiki-ingest <path|url>`
(ingest a raw source) · `/wiki-query <question>` (cited answer; promote to a
page) · `/wiki-lint` (health check).

When a session produces a **durable, reusable** finding — a non-obvious fix, a
diagnostic procedure, an infra fact, a hard-won gotcha — proactively offer to
capture it. Generic knowledge → a topic folder, never buried in an org folder;
link org pages to the generic topic page instead of duplicating.

Do NOT capture: transient/one-off context, anything already in a repo's code or
git history, or trivia. Curate, don't dump.
