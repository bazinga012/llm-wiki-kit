#!/usr/bin/env bash
# llm-wiki-kit setup — installs the wiki commands into your Claude config dir,
# bootstraps a wiki directory, and records the configurable wiki path.
# Idempotent: safe to re-run. Never overwrites existing wiki content.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- resolve config dir + defaults ---------------------------------------
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
WIKI_DIR="${KNOWLEDGE_WIKI_DIR:-$HOME/personal/knowledge-wiki}"

usage() {
  cat <<EOF
Usage: scripts/setup.sh [--wiki-dir PATH] [--config-dir PATH] [--no-git]

  --wiki-dir PATH     Where the wiki content lives (default: \$KNOWLEDGE_WIKI_DIR
                      or ~/personal/knowledge-wiki)
  --config-dir PATH   Claude config dir to install commands into (default:
                      \$CLAUDE_CONFIG_DIR or ~/.claude)
  --no-git            Don't 'git init' a fresh wiki
EOF
}

DO_GIT=1
while [ $# -gt 0 ]; do
  case "$1" in
    --wiki-dir)   WIKI_DIR="$2"; shift 2 ;;
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    --no-git)     DO_GIT=0; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

# expand a leading ~ if passed literally
WIKI_DIR="${WIKI_DIR/#\~/$HOME}"
CONFIG_DIR="${CONFIG_DIR/#\~/$HOME}"

echo "==> kit:        $KIT_DIR"
echo "==> config dir: $CONFIG_DIR"
echo "==> wiki dir:   $WIKI_DIR"

# --- 1. install commands --------------------------------------------------
mkdir -p "$CONFIG_DIR/commands"
for f in "$KIT_DIR"/commands/*.md; do
  cp "$f" "$CONFIG_DIR/commands/$(basename "$f")"
done
echo "==> installed commands: $(cd "$KIT_DIR"/commands && echo *.md)"

# --- 2. record the configurable wiki path --------------------------------
printf '%s\n' "$WIKI_DIR" > "$CONFIG_DIR/knowledge-wiki.path"
echo "==> wrote $CONFIG_DIR/knowledge-wiki.path"

# --- 3. bootstrap the wiki (only fills in missing skeleton files) --------
mkdir -p "$WIKI_DIR/raw" "$WIKI_DIR/outputs" "$WIKI_DIR/wiki"
[ -f "$WIKI_DIR/CLAUDE.md" ]  || cp "$KIT_DIR/templates/wiki/CLAUDE.md"  "$WIKI_DIR/CLAUDE.md"
[ -f "$WIKI_DIR/index.md" ]   || cp "$KIT_DIR/templates/wiki/index.md"  "$WIKI_DIR/index.md"
[ -f "$WIKI_DIR/log.md" ]     || cp "$KIT_DIR/templates/wiki/log.md"    "$WIKI_DIR/log.md"
[ -f "$WIKI_DIR/.gitignore" ] || cp "$KIT_DIR/templates/wiki/gitignore" "$WIKI_DIR/.gitignore"
if [ "$DO_GIT" -eq 1 ] && [ ! -d "$WIKI_DIR/.git" ]; then
  ( cd "$WIKI_DIR" && git init -q )
  echo "==> git init'd $WIKI_DIR"
fi
echo "==> wiki bootstrapped (existing files left untouched)"

# --- 4. ensure the global instruction is in the config CLAUDE.md ---------
GLOBAL_MD="$CONFIG_DIR/CLAUDE.md"
MARKER_BEGIN="<!-- llm-wiki-kit:begin -->"
MARKER_END="<!-- llm-wiki-kit:end -->"
SNIPPET="$KIT_DIR/templates/global-claude-snippet.md"
touch "$GLOBAL_MD"
if grep -qF "$MARKER_BEGIN" "$GLOBAL_MD" 2>/dev/null; then
  echo "==> global instruction already present in $GLOBAL_MD (left as-is)"
else
  { echo ""; echo "$MARKER_BEGIN"; cat "$SNIPPET"; echo "$MARKER_END"; } >> "$GLOBAL_MD"
  echo "==> appended global instruction to $GLOBAL_MD"
fi

echo ""
echo "Done. Restart your Claude session to load the commands, then try:"
echo "  /wiki-query <a question your wiki can answer>"
