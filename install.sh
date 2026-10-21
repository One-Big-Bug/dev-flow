#!/usr/bin/env bash
# dev-flow installer: copy skills/ and commands/ into ~/.claude/
# Backup-then-copy: a failed copy never destroys the previously installed skill.
set -euo pipefail
DEST="${HOME}/.claude"
SRC="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "${DEST}/skills" "${DEST}/commands"

echo "Installing dev-flow from ${SRC}"
for d in "${SRC}"/skills/*/; do
  name="$(basename "$d")"
  bak="${DEST}/skills/${name}.bak"
  rm -rf "$bak"
  if [ -d "${DEST}/skills/${name}" ]; then
    mv "${DEST}/skills/${name}" "$bak"
  fi
  if cp -r "$d" "${DEST}/skills/${name}"; then
    rm -rf "$bak"
  else
    if [ -d "$bak" ]; then
      rm -rf "${DEST}/skills/${name}"
      mv "$bak" "${DEST}/skills/${name}"
      echo "  FAILED: ${name} — previous version restored"
    else
      echo "  FAILED: ${name}"
    fi
    exit 1
  fi
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
