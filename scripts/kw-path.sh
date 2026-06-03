#!/bin/sh
# Resolve the knowledge-wiki directory. Precedence:
#   1. $KNOWLEDGE_WIKI_DIR (env var)
#   2. config file: $CLAUDE_CONFIG_DIR/knowledge-wiki.path (fallback ~/.claude)
#   3. default: ~/personal/knowledge-wiki
# Prints the resolved absolute path. Used by setup.sh and the slash commands.
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge-wiki.path"
if [ -n "$KNOWLEDGE_WIKI_DIR" ]; then
  printf '%s\n' "$KNOWLEDGE_WIKI_DIR"
elif [ -f "$cfg" ]; then
  cat "$cfg"
else
  printf '%s\n' "$HOME/personal/knowledge-wiki"
fi
