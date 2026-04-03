#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"

echo "Claude Code Agents — Installer"
echo "================================"
echo ""
echo "Where do you want to install the agents?"
echo ""
echo "  1) Project-level  (.claude/agents/ in current directory)"
echo "     → Available only in this project. Check into git to share with your team."
echo ""
echo "  2) Global/User-level  (~/.claude/agents/)"
echo "     → Available in ALL your projects."
echo ""
read -rp "Choose [1/2]: " choice

case "$choice" in
  1)
    DEST=".claude/agents"
    echo ""
    echo "Installing to $DEST ..."
    ;;
  2)
    DEST="$HOME/.claude/agents"
    echo ""
    echo "Installing to $DEST ..."
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

mkdir -p "$DEST"

count=0
for agent_file in "$AGENTS_SRC"/*.md; do
  filename=$(basename "$agent_file")
  cp "$agent_file" "$DEST/$filename"
  echo "  ✓ $filename"
  count=$((count + 1))
done

echo ""
echo "Done. Installed $count agents to $DEST"
echo ""
echo "Restart Claude Code or run /agents to see them."
echo ""
echo "Quick start:"
echo "  1. Ask Claude: \"Use the architect agent to design a [your project idea]\""
echo "  2. Then: \"Use the planner agent to create tasks\""
echo "  3. Then work through tasks in order (tdd-test-writer → specialist → code-reviewer → git-committer)"
