## 开发工作流（superpowers 主干）

> 此段是全局 `~/.claude/CLAUDE.md` 的一部分。安装本包后，请手动将此段合并进你的全局 CLAUDE.md（install.sh 只提示，不自动覆盖）。

默认开发流程按以下主干走，技能都在 `~/.claude/skills/`：

1. **讨论**：新想法/新功能先用 `brainstorming` 技能提问挖需求（用户明确说"直接做"则跳过）；已有方案要压力测试用 `/grilling`
2. **计划**：需求明确后用 `writing-plans` 技能写实现计划；用户要正式文档时用 `/prd`
3. **执行**：用 `executing-plans` 按计划逐阶段执行；实现阶段遵循 `test-driven-development`（先测试后实现）；UI 改动用 `/dev-browser` 实时验证
4. **收尾**：声称完成前必须走 `verification-before-completion`（跑命令拿证据）；提交前可用 `/code-review`
5. **失败分支**：同一问题验证失败 2 次以上，切换到 `systematic-debugging` 流程定位根因，禁止继续盲改
6. **提交节奏**：每个计划阶段完成并通过验证后，提出 commit（`feat:`/`fix:` 等 Conventional Commits 格式），**经用户确认后才能执行 git commit**

仲裁规则：
- 小任务（<10 次工具调用）直接做，以本规则为准；`brainstorming` 描述里的 "MUST" 不适用于小任务
- TDD 一律用 superpowers 版 `test-driven-development`；本地 `/tdd` 仅用于集成测试场景

按需启用，不要常驻注入：
- 小任务（<10 次工具调用）：直接做，不走流程
- 中小型任务（默认主力）：走上面的 superpowers 主干，纯 Markdown 技能用完即走
- 跨天长跑任务：叠加 planning-with-files（/plan 落 task_plan.md / findings.md / progress.md 到 `docs/harness/plans/`，/plan-attest 锁计划，/plan-loop 巡检），superpowers 照常在上层走

快速入口：`/flow <想法>` 从讨论到收尾走完整条链。

### 本包专属约定（vendored 改造部分）

- 计划产物统一落 `docs/harness/plans/`：实现计划 `YYYY-MM-DD-<feature>.md`；PWF 三件套单任务平铺该目录，多任务用 `docs/harness/plans/<task-slug>/`
- 脚本类命令（/plan-attest、/plan-doctor、/plan-loop）解析计划目录：`PWF_PLAN_ROOT` 指向 plan 目录本身 + `--target root`
- 不要运行 `init-session.sh` 无参模式（写项目根，已废弃位置）
