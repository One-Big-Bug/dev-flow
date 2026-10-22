# Findings & Decisions

## Requirements

- 用户诉求："既可以全自主又可以保留现在方式" → per-plan opt-in 自主，默认手动
- 本轮范围：/plan-goal（软约束自主）+ 上游 gate 测试；硬门禁（Stop hook 接线）暂缓

## Research Findings

- 上游 commands/plan-goal.md：29 行，v2.38.0 引入，disable-model-invocation: true；从 task_plan.md 派生条件调原生 /goal；默认条件 "all phases report Status: complete and check-complete.sh reports ALL PHASES COMPLETE"
- 上游 tests/ 有 97 个文件；test_gate.py、test_init_modes.py 与 gate 判定直接相关；test_inject_plan_python_parity.py 存在（vendored 完全没有 tests/）
- vendored SKILL.md 与上游逐字节一致——v3 gated 章节都在，只是触发层（hooks.json）和命令层缺失
- gate 硬门禁生效需 hooks.json 的 Stop 接线（上游 Tier-1 host 可真 block）；无接线时 /plan-goal 的完成判定是"软约束"（靠模型读计划自觉）

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| plan-goal 命令改写为 standalone 路线 | 本包是 skill-only 安装，CLAUDE_PLUGIN_ROOT 不存在（F5 同源教训） |
| 测试用 conftest 适配路径 | 不改被测脚本，保持 vendored 与上游一致性可对照 |

## Issues Encountered

| Issue | Resolution |
|-------|------------|

## Resources

- 上游仓库：D:\Dev\Project\skills\planning-with-files20261015\planning-with-files-master
- 对比分析：本会话（README 宣称 + 代码核验两路取证，交叉一致）
