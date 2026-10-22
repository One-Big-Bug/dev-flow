# Task Plan: 自主跑能力（软约束版）— vendor plan-goal + gate 测试

范围（grilling 已确认）：只做建议 1+3；建议 2（Stop hook 硬门禁接线）观察后再说。手动模式默认保留（自主为 per-plan opt-in）。

## Goal

dev-flow 获得"目标驱动跑完整个计划"的能力（/plan-goal → 原生 /goal），且 gate 判定逻辑有上游测试防线；默认行为与现状完全一致。

## Next Step

等待用户确认计划后执行 Phase 1。

## Current Phase

Phase 1: vendor commands/plan-goal.md

## Phases

### Phase 1: vendor /plan-goal 命令（standalone 路线改写）

- [x] 从上游拷贝 commands/plan-goal.md 到 dev-flow commands/
- [x] 改写：计划目录解析遵循 docs/harness/plans 约定（含 --show/--clear 互斥说明）；check-complete.sh 用 standalone 绝对路径
- [x] 回改 commands/plan-loop.md:36 → 指向真实 /plan-goal
- [x] frontmatter 对齐 plan-loop.md 风格；补"软约束"声明（无 Stop hook 时为 advisory）
- **Status:** complete

### Phase 2: vendor 上游 gate 测试

- [x] 拷贝 tests/test_gate.py、test_init_modes.py——上游测试的 REPO_ROOT 解析（parents[1]/skills/planning-with-files/scripts）与本仓库布局一致，**无需 conftest 适配**
- [x] 测试全绿：python -m unittest 22 个用例 OK（118s，无需 pytest）
- **Status:** complete

### Phase 3: 收尾验证与 commit

- [x] bash install.sh 重装；plan-goal.md 进入 ~/.claude/commands/ ✅
- [x] 手动模式回归：无 .mode 文件（本仓库与安装侧均无），plan-doctor PASS，parity 7/7 ✅
- [ ] 分阶段提出 commit（用户确认后执行）
- **Status:** in_progress

## Key Questions

1. 上游 test_gate.py 依赖什么 pytest fixture/conftest？（Phase 2 首步确认）
2. /plan-goal 派生条件里引用的 check-complete.sh 路径需按 standalone 改写（Phase 1 一并处理）

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| 只做 1+3，不做 hook 接线 | 用户确认：先软约束，硬门禁观察后再上 |
| 测试路径适配放 conftest，不改被测脚本 | 保持与上游逐字节一致的原则（vendored 纪律） |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|

## Notes

- 自主/手动共存机制：无 .mode = 现状；--gated 那次任务的 plan 才进自主门禁（本轮不接线，gated 硬门禁仍不生效，属知情限制）
