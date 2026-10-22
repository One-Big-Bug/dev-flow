---
description: "Bridge Claude Code's /goal to the active plan. Derives a goal condition from task_plan.md and invokes /goal so Claude keeps working until the plan is complete. Available since v2.38.0."
disable-model-invocation: true
allowed-tools: "Read Bash"
---

Bridge the active plan to Claude Code's `/goal` primitive.

Steps:

1. Resolve the active plan. Plans live under `docs/harness/plans/` (project root; flat or per-task `<task-slug>/` subdirectory):
   - Prefer an explicit user-named directory under `docs/harness/plans/`.
   - Else the single plan directory there, or the newest modified `task_plan.md`.
   - If nothing is found there, fall back to the script's own resolution (`${PLAN_ID}` env → `.planning/.active_plan` → newest `.planning/<dir>/` → legacy `./task_plan.md`), and report the plan as legacy/deprecated if it resolves that way.
   To make the helper script resolve a `docs/harness/plans/` location, set `PWF_PLAN_ROOT` to the absolute plan directory and use `--target root` (the write/resolve path; `--show`/`--clear` cannot combine with `--target`).
2. Read the resolved `task_plan.md`.
3. Derive a goal condition from the plan content:
   - Default: "all phases in task_plan.md report Status: complete and `sh ~/.claude/skills/planning-with-files/scripts/check-complete.sh` reports ALL PHASES COMPLETE"
   - If user passed an argument: use that as an additional clause (e.g., `/plan-goal until all tests pass`)
4. Issue Claude Code's `/goal <condition>` with the derived text.
5. Confirm to the user: print the goal condition + the active plan ID + remind that `/goal clear` cancels.

If `task_plan.md` does not exist, refuse and direct user to run `/plan` first.

Why this exists:

`/goal` runs the agent until a small fast model confirms the condition is met. It evaluates the transcript only, not files. By deriving the condition from the plan file, this command turns the file-based plan into a measurable termination criterion for `/goal`, so the loop terminates when the plan is actually done, not when the conversation looks done.

Notes:

- `/plan-goal` does not replace `/goal`. It composes with it. Users can still run `/goal "any text"` directly.
- The derived condition stays under the 4000-char limit `/goal` enforces by quoting only phase headers + acceptance criteria, not full task body.
- Combine with `/plan-loop` for a "babysit until done" workflow: `/plan-loop` cadence + `/plan-goal` termination.
- Soft constraint only: without a registered Stop hook this is advisory termination — the model still evaluates the condition. Hard gating (Stop block) is not wired in this pack.
