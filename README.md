# dev-flow

自包含的全局开发流程组合包：**/flow 主干（superpowers 六件套）+ /plan 家族（planning-with-files 长跑外挂）**。克隆到任何机器，跑一次 `install.sh` 即完成部署。

## 内容

```
skills/    7 个技能（安装到 ~/.claude/skills/）
commands/  6 个命令（安装到 ~/.claude/commands/）
CLAUDE-workflow.md  全局 CLAUDE.md 的「开发工作流」段（手动合并）
install.sh 一键安装
```

### /flow：中小型任务主力链

```
/flow <想法>
 ① brainstorming 问透需求（小任务跳过；压力测试已有方案用 /grilling，不在本包内）
 ② writing-plans 出计划 →【硬关卡：用户点头才动】
 ③ executing-plans + test-driven-development 实现
    ├ 失败 2 次 → systematic-debugging
    └ 每阶段验证过 → commit 建议 →【用户确认才 commit】
 ④ verification-before-completion 拿证据 → 完成
```

### /plan：跨天长跑记忆外挂

planning-with-files 三件套（task_plan.md / findings.md / progress.md）落 `docs/harness/plans/`，生命周期 hook 在技能激活后逐轮注入计划上下文，计划在 /clear、压缩、崩溃后自动从磁盘恢复。配套：/plan-attest（锁计划）、/plan-loop（巡检）、/status、/plan-doctor（自检）。

### 任务分级

- 小任务（<10 次工具调用）：直接做
- 中小型：/flow 全链
- 跨天/多会话：/flow ② 确认后切 /plan 承载执行

## 血缘（vendored 来源与分叉）

均为 MIT 许可，整体 vendored 并已按本机工作流改造，**不自动跟随上游**：

| 组件 | 来源 | 版本/commit | 本地分叉 |
|---|---|---|---|
| brainstorming, executing-plans, test-driven-development, systematic-debugging, verification-before-completion | [obra/superpowers](https://github.com/obra/superpowers) | `b739a8a` | 无 |
| writing-plans | 同上 | `b739a8a` | 计划产物路径对齐 `docs/harness/plans/YYYY-MM-DD-<feature>.md`（3 处） |
| planning-with-files | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 基于 v3.24.0 拷贝（上游最新 v3.25.0） | 无直接改动；路径约定通过 commands 层适配 |

## 安装

```bash
git clone <本仓库地址> && cd dev-flow
bash install.sh        # Windows Git Bash 可直接跑
```

安装后手动步骤（install.sh 会再次提示）：

1. 将 `CLAUDE-workflow.md` 内容合并进 `~/.claude/CLAUDE.md`
2. 重启 Claude Code 会话
3. 任意项目里跑 `/plan-doctor` 验证 hook 链路

### 依赖

- PWF hook 需要 Bash 与 Python 3.10+（Windows 装 Git for Windows，其 Bash 在 PATH 上）
- superpowers 技能为纯 Markdown，无脚本依赖

## 更新

- **改本地流程**：改本仓库 → `bash install.sh` 同步到 `~/.claude/`
- **合并上游（可选）**：对照上游 diff 手动合并，跑 `/plan-doctor` 回归

## Token 模型（三档）

| 档位 | 量级 |
|---|---|
| 常驻（每次会话：description 行 + CLAUDE.md 工作流段） | ~1.5K |
| 触发（SKILL.md 正文一次性加载） | 单个 5-10K |
| PWF hook 注入（仅计划激活后） | 每轮 200-500，无计划时静默为零 |
