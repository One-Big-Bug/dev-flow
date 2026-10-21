---
description: "Self-check for the planning-with-files mechanisms that fail silently: plan resolution, hook injection, canonicalizer path shape, attestation state, install surfaces, and per-fire hook latency. Run it whenever hooks seem quiet or after installing on a new machine. Available since v3.6.0."
disable-model-invocation: true
allowed-tools: "Bash"
---

Run the planning-with-files self-check against the current project (plans expected under `docs/harness/plans/`).

Steps:
1. Run the doctor script from the project root:
   - Linux/macOS/Git Bash: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/plan-doctor.sh`
   - Windows without Git Bash on PATH: locate Git Bash via `git.exe` (its `usr\bin\sh.exe` sibling) and run the same script with it.
   - Note: plans are expected under `docs/harness/plans/`. If a plan exists there but the doctor can't see it, re-run with `PWF_PLAN_ROOT` set to the absolute `docs/harness/plans` path (or the specific plan directory) so the resolver is pinned correctly.
2. Report the PASS/WARN/FAIL lines to the user verbatim — they are designed to be read as-is.
3. If any line reports FAIL, explain the matching remediation:
   - resolver FAIL → inspect `.planning/.active_plan` content and plan dir names.
   - injection FAIL with a resolving plan → the hooks are silently dark; upgrading past v3.6.0 fixes the Windows-native-coreutils realpath cause. Also check `PLANNING_DISABLED`.
   - tamper WARN → re-approve with `/plan-attest` if the plan edit was intentional.
4. Do not attempt automatic fixes; this command is diagnostic only.

Why this exists: the mechanisms this skill relies on (hook injection, plan resolution) exit 0 and stay silent by design when something is off, so a broken install looks identical to "no plan yet". The doctor makes the difference visible in one pass.
