#!/usr/bin/env bash
# llm-wiki-kit setup — install the wiki commands into one or more AI coding
# agents, bootstrap a shared wiki directory, and record the wiki path.
# The wiki content is agent-agnostic: every agent reads/writes the same files.
# Idempotent: safe to re-run. Never overwrites existing wiki content.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$KIT_DIR/scripts/render.sh"

# --- defaults -------------------------------------------------------------
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"   # Claude config dir (also holds knowledge-wiki.path)
WIKI_DIR="${KNOWLEDGE_WIKI_DIR:-}"
AGENTS_ARG=""                                       # empty => autodetect
DO_GIT=1

ALL_AGENTS="claude gemini codex opencode cursor antigravity"

usage() {
  cat <<EOF
Usage: scripts/setup.sh [--agents LIST] [--wiki-dir PATH] [--config-dir PATH] [--no-git]

  --agents LIST     Comma/space list of agents to install for, or "all".
                    Choices: $ALL_AGENTS
                    Default: autodetect (every agent whose config dir exists;
                    falls back to claude if none are found).
  --wiki-dir PATH   Where the shared wiki content lives
                    (default: \$KNOWLEDGE_WIKI_DIR, else \$CLAUDE_CONFIG_DIR/knowledge-wiki.path,
                    else ~/personal/knowledge-wiki)
  --config-dir PATH Claude config dir (default: \$CLAUDE_CONFIG_DIR or ~/.claude)
  --no-git          Don't 'git init' a fresh wiki

Per-agent config roots can be overridden via env vars: CLAUDE_CONFIG_DIR,
GEMINI_DIR, CODEX_HOME, OPENCODE_CONFIG, CURSOR_DIR. Antigravity shares the
Gemini home (~/.gemini); override its base with ANTIGRAVITY_DIR. It installs
workflows into <base>/config/global_workflows (shared by all Antigravity
variants) and its rule into <base>/GEMINI.md.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agents)     AGENTS_ARG="$2"; shift 2 ;;
    --wiki-dir)   WIKI_DIR="$2"; shift 2 ;;
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    --no-git)     DO_GIT=0; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

# resolve wiki dir: flag > $KNOWLEDGE_WIKI_DIR > config file > default
if [ -z "$WIKI_DIR" ]; then
  if [ -f "$CONFIG_DIR/knowledge-wiki.path" ]; then
    WIKI_DIR="$(cat "$CONFIG_DIR/knowledge-wiki.path")"
  else
    WIKI_DIR="$HOME/personal/knowledge-wiki"
  fi
fi
WIKI_DIR="${WIKI_DIR/#\~/$HOME}"
CONFIG_DIR="${CONFIG_DIR/#\~/$HOME}"

# --- per-agent metadata ---------------------------------------------------
# Antigravity (both the "antigravity" and "antigravity-ide" variants) shares the
# Gemini home (~/.gemini). It reads user-global slash commands as "workflows"
# from a single shared dir: ~/.gemini/config/global_workflows (markdown files,
# `description` frontmatter + body). Global rules come from ~/.gemini/GEMINI.md.
ANTIGRAVITY_BASE="${ANTIGRAVITY_DIR:-${GEMINI_DIR:-$HOME/.gemini}}"
ANTIGRAVITY_CONFIG="$ANTIGRAVITY_BASE/config"

agent_root() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ;;
    gemini)   echo "${GEMINI_DIR:-$HOME/.gemini}" ;;
    codex)    echo "${CODEX_HOME:-$HOME/.codex}" ;;
    opencode) echo "${OPENCODE_CONFIG:-$HOME/.config/opencode}" ;;
    cursor)   echo "${CURSOR_DIR:-$HOME/.cursor}" ;;
  esac
}
agent_ext() { case "$1" in gemini) echo "toml" ;; *) echo "md" ;; esac; }

# Command target dir(s), absolute, newline-separated (an agent may have several).
agent_cmd_targets() {
  case "$1" in
    claude)   echo "$(agent_root claude)/commands" ;;
    gemini)   echo "$(agent_root gemini)/commands" ;;
    codex)    echo "$(agent_root codex)/prompts" ;;
    opencode) echo "$(agent_root opencode)/command" ;;
    cursor)   echo "$(agent_root cursor)/commands" ;;
    antigravity) echo "$ANTIGRAVITY_CONFIG/global_workflows" ;;
  esac
}

# Instruction-snippet target file, absolute (empty => skip).
agent_mem_file() {
  case "$1" in
    claude)   echo "$(agent_root claude)/CLAUDE.md" ;;
    gemini)   echo "$(agent_root gemini)/GEMINI.md" ;;
    codex)    echo "$(agent_root codex)/AGENTS.md" ;;
    opencode) echo "$(agent_root opencode)/AGENTS.md" ;;
    cursor)   echo "$(agent_root cursor)/rules/llm-wiki-kit.mdc" ;;
    antigravity) echo "$ANTIGRAVITY_BASE/GEMINI.md" ;;  # shared Gemini home
  esac
}

agent_present() {  # for autodetect
  case "$1" in
    antigravity)
      [ -d "$ANTIGRAVITY_CONFIG" ] && return 0
      [ -d "$ANTIGRAVITY_BASE/antigravity" ] || [ -d "$ANTIGRAVITY_BASE/antigravity-ide" ] ;;
    *) [ -d "$(agent_root "$1")" ] ;;
  esac
}

# --- decide which agents to target ---------------------------------------
selected=""
if [ -n "$AGENTS_ARG" ]; then
  if [ "$AGENTS_ARG" = "all" ]; then
    selected="$ALL_AGENTS"
  else
    selected="$(printf '%s' "$AGENTS_ARG" | tr ',' ' ')"
  fi
else
  for a in $ALL_AGENTS; do
    agent_present "$a" && selected="$selected $a"
  done
  [ -n "${selected// /}" ] || selected="claude"   # fallback
fi

echo "==> kit:      $KIT_DIR"
echo "==> wiki dir: $WIKI_DIR"
echo "==> agents:   $(echo $selected)"

# --- snippet with the wiki path baked in ---------------------------------
SNIPPET_BAKED="$(sed "s|{{WIKI}}|$(printf '%s' "$WIKI_DIR" | sed 's/[&|\]/\\&/g')|g" \
                  "$KIT_DIR/templates/agent-snippet.md")"
# The managed block leads with a readable heading (some agents — e.g. Antigravity
# — surface a memory file's first line as a rule title, so we don't want a raw
# marker comment there) and is closed by a trailing HTML comment we can find on
# re-runs. We also strip the old begin/end-marker form for clean migration.
MEM_END="<!-- /llm-wiki-kit -->"

strip_managed() {  # remove any existing llm-wiki-kit block from $1, trim trailing blanks
  f="$1"; [ -f "$f" ] || return 0
  awk '
    /<!-- llm-wiki-kit:begin -->/ {skip=1; next}                 # old form: begin
    skip && /<!-- llm-wiki-kit:end -->/ {skip=0; next}           # old form: end
    /^## Knowledge wiki \(llm-wiki-kit\)/ {skip2=1}              # new form: heading
    skip2 && /<!-- \/llm-wiki-kit -->/ {skip2=0; next}           # new form: trailing
    skip || skip2 {next}
    {a[++n]=$0} NF{last=n}                                       # buffer kept lines; track last non-blank
    END {for (i=1;i<=last;i++) print a[i]}                       # drop trailing blank lines
  ' "$f" > "$f.lwk.tmp" && mv "$f.lwk.tmp" "$f"
}

install_for_agent() {
  agent="$1"; ext="$(agent_ext "$agent")"

  # 1. render + install commands into every target dir (bake the absolute path,
  #    so it works even on agents without shell injection).
  while IFS= read -r outdir; do
    [ -n "$outdir" ] || continue
    mkdir -p "$outdir"
    for src in "$KIT_DIR"/commands-src/*.md; do
      name="$(basename "${src%.md}")"
      bash "$RENDER" "$agent" "$WIKI_DIR" "$src" > "$outdir/$name.$ext"
    done
    echo "    [$agent] commands -> $outdir/*.$ext"
  done <<EOF
$(agent_cmd_targets "$agent")
EOF

  # 2. install the instruction snippet into the agent's memory file
  memfile="$(agent_mem_file "$agent")"
  [ -n "$memfile" ] || { echo "    [$agent] (no global instruction file)"; return; }
  mkdir -p "$(dirname "$memfile")"
  if [ "$agent" = "cursor" ]; then
    # Cursor rules are .mdc with their own frontmatter. We own this file.
    {
      printf -- '---\n'
      printf 'description: Knowledge wiki (llm-wiki-kit) — capture/query/lint commands\n'
      printf 'alwaysApply: true\n'
      printf -- '---\n'
      printf '%s\n' "$SNIPPET_BAKED"
    } > "$memfile"
    echo "    [$agent] rule    -> $memfile (note: Cursor rules are project-scoped)"
  else
    touch "$memfile"
    had=0; grep -qF "$MEM_END" "$memfile" 2>/dev/null && had=1
    grep -qF "<!-- llm-wiki-kit:begin -->" "$memfile" 2>/dev/null && had=1
    strip_managed "$memfile"   # remove old/previous block (self-updating)
    [ -s "$memfile" ] && echo "" >> "$memfile"   # blank separator only if file has content
    { printf '%s\n' "$SNIPPET_BAKED"; printf '%s\n' "$MEM_END"; } >> "$memfile"
    [ "$had" -eq 1 ] && echo "    [$agent] memory  -> $memfile (updated)" \
                      || echo "    [$agent] memory  -> $memfile (added)"
  fi
}

for a in $selected; do
  case " $ALL_AGENTS " in
    *" $a "*) install_for_agent "$a" ;;
    *) echo "    [skip] unknown agent: $a" >&2 ;;
  esac
done

# --- record the wiki path (used by the Claude plugin's runtime resolver) --
mkdir -p "$CONFIG_DIR"
printf '%s\n' "$WIKI_DIR" > "$CONFIG_DIR/knowledge-wiki.path"
echo "==> wrote $CONFIG_DIR/knowledge-wiki.path"

# --- bootstrap the shared wiki (only fills missing skeleton files) -------
mkdir -p "$WIKI_DIR/raw" "$WIKI_DIR/outputs" "$WIKI_DIR/wiki"
[ -f "$WIKI_DIR/AGENTS.md" ] || cp "$KIT_DIR/templates/wiki/AGENTS.md" "$WIKI_DIR/AGENTS.md"
[ -f "$WIKI_DIR/CLAUDE.md" ] || cp "$KIT_DIR/templates/wiki/CLAUDE.md" "$WIKI_DIR/CLAUDE.md"
[ -f "$WIKI_DIR/GEMINI.md" ] || cp "$KIT_DIR/templates/wiki/GEMINI.md" "$WIKI_DIR/GEMINI.md"
[ -f "$WIKI_DIR/index.md" ]  || cp "$KIT_DIR/templates/wiki/index.md"  "$WIKI_DIR/index.md"
[ -f "$WIKI_DIR/log.md" ]    || cp "$KIT_DIR/templates/wiki/log.md"    "$WIKI_DIR/log.md"
[ -f "$WIKI_DIR/.gitignore" ]|| cp "$KIT_DIR/templates/wiki/gitignore" "$WIKI_DIR/.gitignore"
if [ "$DO_GIT" -eq 1 ] && [ ! -d "$WIKI_DIR/.git" ]; then
  ( cd "$WIKI_DIR" && git init -q )
  echo "==> git init'd $WIKI_DIR"
fi
echo "==> wiki bootstrapped at $WIKI_DIR (existing files left untouched)"

echo ""
echo "Done. Restart your agent session(s) to load the commands, then try:"
echo "  /wiki-query <a question your wiki can answer>"
