---
description: "Start Manus-style file-based planning. Creates task_plan.md, findings.md, progress.md for complex tasks."
---

Invoke the planning-with-files:planning-with-files skill and follow it exactly as presented to you.

Create the three planning files under `docs/harness/plans/` in the current project (create the directory if it doesn't exist):
- Single simple task: `docs/harness/plans/task_plan.md`, `findings.md`, `progress.md` (flat).
- Multi-task / cross-day work: `docs/harness/plans/<task-slug>/task_plan.md` etc., one subdirectory per task.
- task_plan.md — for phases, progress, and decisions
- findings.md — for research and discoveries
- progress.md — for session logging

Create them manually from the skill's `templates/` (do NOT run `scripts/init-session.sh` without args — it writes to project root, which is the deprecated location). If you use `init-session.sh` with a name arg, move or point the result into `docs/harness/plans/<task-slug>/` and pin `PWF_PLAN_ROOT` to the absolute plan directory itself (`.../docs/harness/plans` for flat layout, `.../docs/harness/plans/<task-slug>` for a named task) so script-based commands (`/plan-attest`, `/plan-doctor`, `/plan-loop`) resolve it.

Then guide the user through the planning workflow.
