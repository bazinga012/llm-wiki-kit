## Knowledge wiki
A persistent, agent-maintained knowledge base lives at `{{WIKI}}` (Karpathy
"LLM Wiki" pattern). It holds durable, cross-session knowledge: generic/reusable
facts in topic folders (`wiki/<topic>/`), org/project-specific facts in their own
folders. Its `AGENTS.md` defines the full ingest / query / lint workflow. The
wiki is shared across agents — the same files are read and written whether you
run via Claude Code, Gemini CLI, Codex, opencode, Cursor, or Antigravity.

Commands: `/capture` (ingest current session) · `/wiki-ingest <path|url>`
(ingest a raw source) · `/wiki-query <question>` (cited answer; promote to a
page) · `/wiki-lint` (health check).

When a session produces a **durable, reusable** finding — a non-obvious fix, a
diagnostic procedure, an infra fact, a hard-won gotcha — proactively offer to
capture it. Generic knowledge → a topic folder, never buried in an org folder;
link org pages to the generic topic page instead of duplicating.

Do NOT capture: transient/one-off context, anything already in a repo's code or
git history, or trivia. Curate, don't dump.
