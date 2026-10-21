---
description: "Lock the current task_plan.md content with a SHA-256 attestation. Hooks then refuse to inject plan content if the file diverges from the attested hash, blocking silent tampering. Use --show to print the stored hash, --clear to remove the attestation. Available since v2.37.0."
disable-model-invocation: true
allowed-tools: "Bash"
---

Run the plan attestation helper for the active plan.

Steps:
1. Resolve the active plan. Plans live under `docs/harness/plans/` (project root; flat or per-task `<task-slug>/` subdirectory):
   - Prefer an explicit user-named directory under `docs/harness/plans/`.
   - Else the single plan directory there, or the newest modified `task_plan.md`.
   - If nothing is found there, fall back to the script's own resolution (`${PLAN_ID}` env → `.planning/.active_plan` → newest `.planning/<dir>/` → legacy `./task_plan.md`), and report the plan as legacy/deprecated if it resolves that way.
   To make the helper script resolve a `docs/harness/plans/` location, set `PWF_PLAN_ROOT` to the absolute plan directory and use `--target root`.
2. Compute the SHA-256 of the resolved `task_plan.md`.
3. Write the hex digest to `.planning/<active-plan>/.attestation` (parallel-plan mode) or `./.plan-attestation` (legacy mode).
4. Confirm to the user with the short hash (first 12 hex chars) and the storage path.

An explicit `${PLAN_ID}` or `${PWF_PLAN_ROOT}` that does not resolve exits with an error. It never falls back to another plan.

Implementation:
- On Linux/macOS/Git Bash: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/attest-plan.sh`
- On Windows PowerShell plugin installs: `& "$env:CLAUDE_PLUGIN_ROOT\scripts\attest-plan.ps1"`
- On Windows PowerShell standalone installs: `& "$env:USERPROFILE\.claude\skills\planning-with-files\scripts\attest-plan.ps1"`

Flags:
- `--show` — print the currently stored hash and where it lives.
- `--clear` — remove the attestation (re-open the plan to free editing).

After running this command, every UserPromptSubmit and PreToolUse hook fire compares `task_plan.md` against the stored hash. If they diverge, the hook emits `[PLAN TAMPERED — injection blocked]` instead of feeding plan content into the model. Re-run `/plan-attest` whenever you intentionally edit and re-approve the plan.
