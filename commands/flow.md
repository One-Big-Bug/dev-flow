---
description: "通用开发流程：一个想法从讨论到收尾走完整条链（brainstorming → writing-plans → executing-plans + TDD → verification-before-completion）。参数是任务描述。"
---

按全局 CLAUDE.md 的「开发工作流」主干执行，参数即任务：$ARGUMENTS

执行规则：

1. **讨论**：调用 `brainstorming` 技能（~/.claude/skills/brainstorming/SKILL.md），按其流程向用户提问挖需求。若用户在参数里写了"直接做"或需求已足够明确，跳过并复述理解到的需求。
2. **计划**：调用 `writing-plans` 技能，把收敛后的需求写成实现计划（含阶段拆分），展示给用户。计划文档保存到 `{项目}/docs/harness/plans/YYYY-MM-DD-<feature>.md`。**计划确认是硬关卡：必须停下等用户明确同意，未同意前不得执行任何写操作。**
3. **执行**：调用 `executing-plans` 技能逐阶段实现；每个实现步骤遵循 `test-driven-development`（先写失败的测试，再写最小实现）。每个阶段完成并通过验证后提出 commit 建议，**经用户确认后才执行 git commit**。
4. **失败分支**：同一问题验证失败 2 次以上，停止修改，切换到 `systematic-debugging` 技能定位根因后再继续。
5. **收尾**：调用 `verification-before-completion` 技能，跑验证命令、确认输出后才能声明完成。

任务规模判断（以全局 CLAUDE.md 仲裁规则为准）：
- 小任务（预计 <10 次工具调用）：跳过第 1、2 步，直接实现并用第 5 步收尾；`brainstorming` 的 "MUST" 不适用。
- 用户提到"长期/跨天/多会话"：在计划确认后，改用 planning-with-files 流程（/plan 落三件套到 `docs/harness/plans/`）承载执行。
