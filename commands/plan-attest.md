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

Implementation (first match wins; in this pack the standalone skill route is the primary one — `${CLAUDE_PLUGIN_ROOT}` is only set for plugin installs):
- Git Bash / macOS / Linux standalone (this pack's default layout): `sh ~/.claude/skills/planning-with-files/scripts/attest-plan.sh`
- Windows PowerShell standalone installs: `& "$env:USERPROFILE\.claude\skills\planning-with-files\scripts\attest-plan.ps1"`
- Plugin installs (Bash): `sh ${CLAUDE_PLUGIN_ROOT}/scripts/attest-plan.sh`
- Windows PowerShell plugin installs: `& "$env:CLAUDE_PLUGIN_ROOT\scripts\attest-plan.ps1"`

Flags:
- `--show` — print the currently stored hash and where it lives.
- `--clear` — remove the attestation (re-open the plan to free editing).
- `--show` and `--clear` must be the only argument (attest-plan.sh rejects any
  other combination with a usage error) — they CANNOT be combined with
  `--target root`. For `docs/harness/plans/` locations, run them with the cwd
  at the plan directory (legacy fallback resolves `./task_plan.md` there);
  the `PWF_PLAN_ROOT` pin alone is not enough, because pin mode looks for
  `${PWF_PLAN_ROOT}/.planning/` subdirectories. The write path (`--target
  root` + `PWF_PLAN_ROOT`) has no such restriction.

After running this command, every UserPromptSubmit and PreToolUse hook fire compares `task_plan.md` against the stored hash. If they diverge, the hook emits `[PLAN TAMPERED — injection blocked]` instead of feeding plan content into the model. Re-run `/plan-attest` whenever you intentionally edit and re-approve the plan.
