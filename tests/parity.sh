#!/usr/bin/env bash
# Parity harness: inject-plan.py must emit byte-identical stdout to
# inject-plan.sh (the reference implementation) for the same project state
# and context. See inject-plan.py header (twin contract).
#
# Usage:  bash tests/parity.sh            # run all cases
#         bash tests/parity.sh <n>        # run case <n> only
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="${ROOT}/skills/planning-with-files/scripts"

pick_python() {
  for c in python3 python py; do
    if command -v "$c" >/dev/null 2>&1; then
      if "$c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' 2>/dev/null; then
        command -v "$c"
        return 0
      fi
    fi
  done
  return 1
}
PY="$(pick_python)" || { echo "SKIP: no Python >= 3.8 on PATH"; exit 0; }

PASS=0; FAIL=0

# run_case <name> <fixture-fn> <context> [stdin-file]
# Runs both implementations inside a fresh fixture project and diffs stdout.
run_case() {
  local name="$1" fixture="$2" context="$3" stdin_file="${4:-/dev/null}"
  local dir; dir="$(mktemp -d)"
  local out_py out_sh rc_py rc_sh
  "$fixture" "$dir"
  ( cd "$dir" && env -i PATH="$PATH" HOME="$HOME" \
      "$PY" -I -B "${SCRIPTS}/inject-plan.py" "--context=${context}" \
      < "$stdin_file" > .out.py 2>/dev/null ); rc_py=$?
  ( cd "$dir" && env -i PATH="$PATH" HOME="$HOME" \
      sh "${SCRIPTS}/inject-plan.sh" "--context=${context}" \
      < "$stdin_file" > .out.sh 2>/dev/null ); rc_sh=$?
  if diff -q "$dir/.out.py" "$dir/.out.sh" >/dev/null 2>&1 && [ "$rc_py" = "$rc_sh" ]; then
    echo "PASS: $name (rc=${rc_py})"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name (rc_py=${rc_py} rc_sh=${rc_sh})"
    diff "$dir/.out.py" "$dir/.out.sh" 2>&1 | head -10 | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
  rm -rf "$dir"
}

# ---- fixtures -------------------------------------------------------------

fx_empty() { :; }   # project with no plan at all

fx_legacy_plan() {  # v2 legacy: plan files at project root
  local d="$1"
  printf '# Task Plan: demo\n\n### Phase 1: One\n\n- [x] item\n- **Status:** complete\n' > "$d/task_plan.md"
  printf '# Findings\n\n- nothing yet\n' > "$d/findings.md"
  printf '# Progress Log\n\n- started\n' > "$d/progress.md"
}

fx_long_plan() {    # forces head truncation on both sides
  local d="$1"
  { printf '# Task Plan: long\n'
    for i in $(seq 1 80); do printf '\n### Phase %s: filler\n\n- [ ] step %s\n- **Status:** pending\n' "$i" "$i"; done
  } > "$d/task_plan.md"
  printf '# Findings\n\n- x\n' > "$d/findings.md"
  { printf '# Progress Log\n'; for i in $(seq 1 40); do printf -- '- entry %s\n' "$i"; done; } > "$d/progress.md"
}

fx_named_ambiguous() {  # two named plans, no active pointer -> ambiguity
  local d="$1"
  mkdir -p "$d/.planning/aaa" "$d/.planning/bbb"
  for p in aaa bbb; do
    printf '# Task Plan: %s\n\n### Phase 1: x\n- **Status:** pending\n' "$p" > "$d/.planning/$p/task_plan.md"
    printf '# Findings\n\n- x\n' > "$d/.planning/$p/findings.md"
    printf '# Progress Log\n\n- x\n' > "$d/.planning/$p/progress.md"
  done
}

fx_named_selected() {   # one named plan + explicit pointer
  local d="$1"
  mkdir -p "$d/.planning/only"
  printf '# Task Plan: only\n\n### Phase 1: x\n- **Status:** in_progress\n' > "$d/.planning/only/task_plan.md"
  printf '# Findings\n\n- x\n' > "$d/.planning/only/findings.md"
  printf '# Progress Log\n\n- x\n' > "$d/.planning/only/progress.md"
  printf 'only\n' > "$d/.planning/.active_plan"
}

# ---- cases ----------------------------------------------------------------

ONLY="${1:-}"
case_run() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

case_run 1 && run_case "1 empty project / userprompt"      fx_empty           userprompt
case_run 2 && run_case "2 legacy plan / userprompt"        fx_legacy_plan     userprompt
case_run 3 && run_case "3 long plan truncation / userprompt" fx_long_plan     userprompt
case_run 4 && run_case "4 ambiguous named plans / userprompt" fx_named_ambiguous userprompt
case_run 5 && run_case "5 named plan selected / userprompt"  fx_named_selected userprompt
case_run 6 && run_case "6 legacy plan / precompact"        fx_legacy_plan     precompact
case_run 7 && run_case "7 legacy plan / preflight"         fx_legacy_plan     preflight

echo ""
echo "parity: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
