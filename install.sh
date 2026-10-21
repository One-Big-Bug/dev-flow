#!/usr/bin/env bash
# dev-flow installer: copy skills/ and commands/ into ~/.claude/
set -euo pipefail
DEST="${HOME}/.claude"
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dev-flow from ${SRC}"
for d in "${SRC}"/skills/*/; do
  name="$(basename "$d")"
  rm -rf "${DEST}/skills/${name}"
  cp -r "$d" "${DEST}/skills/${name}"
  echo "  skill:   ${name}"
done
for f in "${SRC}"/commands/*.md; do
  cp "$f" "${DEST}/commands/$(basename "$f")"
  echo "  command: $(basename "$f")"
done

echo ""
echo "Done. Remaining manual steps:"
echo "  1. Merge CLAUDE-workflow.md into ${DEST}/CLAUDE.md (if not already present)"
echo "  2. Restart Claude Code session to load skills and commands"
echo "  3. Verify: run /plan-doctor in a project (PWF hook chain self-check)"
