# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-contained, vendored skill pack ("dev-flow") for Claude Code — **not a Node/npm project** (no package.json, no build/test toolchain). It bundles the /flow pipeline (superpowers skills) plus the /plan family (planning-with-files) and deploys by copying files into `~/.claude/`.

- `skills/` — 7 skills, each a directory whose entry point is `SKILL.md`
- `commands/` — 6 slash-command Markdown files (become `/flow`, `/plan`, `/plan-attest`, `/plan-doctor`, `/plan-loop`, `/status`)
- `CLAUDE-workflow.md` — the "开发工作流" section meant to be merged into the user's global `~/.claude/CLAUDE.md`
- `install.sh` — one-command installer

## Commands

```bash
bash install.sh   # Install/sync skills/ → ~/.claude/skills/, commands/ → ~/.claude/commands/
                  # Requires Bash (Git Bash on Windows); rm+cp, same-name skills are overwritten
```

After installing, verify the deployed hook chain by running `/plan-doctor` in any project. There is no build, lint, or test suite in this repo.

## Architecture

### Install model

`install.sh` copies each `skills/<name>/` directory into `~/.claude/skills/<name>/` (removing the old same-name directory first) and each `commands/*.md` into `~/.claude/commands/`. There is no versioning — upgrading means editing this repo and re-running `install.sh`. Version provenance is tracked manually in README.md's 血缘 table (vendored upstream commits).

### Skill loading

Skills are discovered by Claude Code scanning `~/.claude/skills/<name>/SKILL.md`; only the frontmatter `description` is resident in context — the body loads on trigger. Runtime artifacts (plan files) never live here; they are written into the *target project* under `docs/harness/plans/`.

### Two skill families with different natures

- **superpowers five** (`brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`) — pure Markdown, no script dependencies. Only `writing-plans` was forked: plan output paths aligned to `docs/harness/plans/YYYY-MM-DD-<feature>.md` (3 places).
- **planning-with-files (PWF)** — the only script-heavy skill. `scripts/` holds lifecycle hooks and helpers, each in `.sh` + `.ps1` pairs for Windows, plus `.py` hooks (`inject-plan.py`, `session-catchup.py`). These run as Claude Code hooks and are what `/plan-doctor` self-checks.

### Vendoring rules

All skills are vendored (MIT) and deliberately **do not auto-follow upstream**. When merging upstream, diff manually and re-run `/plan-doctor` as a regression check.

## Conventions that matter when editing

- Plan artifacts go to the *target project's* `docs/harness/plans/`: implementation plans as `YYYY-MM-DD-<feature>.md`; PWF's task_plan/findings/progress flat there for single tasks, `docs/harness/plans/<task-slug>/` for multi-task.
- Script-style commands (`/plan-attest`, `/plan-doctor`, `/plan-loop`) resolve the plan dir via `PWF_PLAN_ROOT` pointing at the plan directory itself + `--target root`.
- Never run `init-session.sh` without arguments — it writes to the deprecated project-root location.
- `.gitattributes` pins line endings: `.sh`/`.py` = LF, `.ps1` = CRLF. Keep it that way; Windows Git Bash breaks on CRLF shell scripts.
- Users' global CLAUDE.md is updated by *manual merge* of `CLAUDE-workflow.md` — `install.sh` only prints a reminder and never touches it.
