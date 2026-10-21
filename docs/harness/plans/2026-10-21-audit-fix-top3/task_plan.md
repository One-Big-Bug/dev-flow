# Task Plan: 落地审查报告 Top 3（install.sh 备份安装 / sh-py 等价性测试 / 命令文档悬空路径）

依据：docs/harness/2026-10-21-audit-report.md（F1 / F3 / F5+F14）

## Goal

修掉审查报告的 Top 3 高价值问题：安装器不再有数据丢失风险、双实现拥有等价性测试防线、命令文档无悬空路径——全部经命令验证后提出 commit。

## Next Step

执行 Phase 4：真机重装 install.sh → standalone 路线跑 /plan-doctor 回归 → 分阶段提出 commit。

## Current Phase

Phase 4: 收尾验证与 commit

## Phases

### Phase 1: install.sh 备份式安装（F1）

- [ ] 加 `mkdir -p "${DEST}/skills" "${DEST}/commands"`
- [ ] 技能改为 .bak 备份 → cp 成功删 .bak / 失败回滚 mv
- [ ] 失败时输出 FAILED 提示并 exit 1
- [x] 真机验证：正常重装路径 + 模拟 cp 失败（icacls deny 源目录）验证回滚
- **Status:** complete

### Phase 2: sh/py 等价性测试（F3）

- [x] 新建 tests/ 目录与对比 harness（固定 fixture 喂 inject-plan.py 与 sh 路径，diff stdout）
- [x] 用例：无计划 / 单计划 / 多计划歧义 / 超长截断 / attestation（≥5 个）→ 实落 7 个（含 precompact/preflight/命名计划选择）
- [x] tests/README.md 说明运行方式与 fixture 约定
- [x] 测试全绿；故意改 py 分隔符一行验证测试能抓到（3 FAIL → 还原 7/7 PASS）
- **Status:** complete

### Phase 3: 命令文档悬空路径修复（F5+F14）

- [x] plan-attest.md 补 standalone 路线 `~/.claude/skills/planning-with-files/scripts/attest-plan.sh`（置首位）
- [x] plan-doctor.md 同样补 standalone 路线
- [x] plan-loop.md:36 删 /plan-goal 引用，改述 native /goal manual fallback
- [x] plan-loop.md:19 的 check-complete.sh 补全绝对路径
- [x] 顺带 F19：plan-attest.md 注明 --show/--clear 互斥与正确用法（真机验证中发现 F19 最初方案错误，已修正，见 findings）
- **Status:** complete

### Phase 4: 收尾验证与 commit

- [ ] `bash install.sh` 重装到 ~/.claude 并确认 7 技能 6 命令就位
- [ ] /plan-doctor 回归（经 standalone 路线跑通）
- [ ] 更新 README 依赖节（brainstorming 需 Node，属 F8 顺带，可选）
- [ ] 提出分阶段 commit（用户确认后执行）
- **Status:** pending

## Key Questions

1. 等价性测试的 fixture 如何构造最小计划目录？（Phase 2 首项实验确定）
2. Phase 2 harness 在 Windows Git Bash 下跑通即可，还是要兼顾 CI？（当前无 CI，按本机跑通即可）

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| install.sh 用 .bak 备份而非 cp 到临时目录再 mv | 保留跨文件系统兼容，逻辑直白；审查报告 F1 方案原样落地 |
| 测试走 stdout diff 对比而非逐函数单测 | 双实现契约就是"同输入同输出"，diff 最直接对应 F3 的等价性声明 |
| 本机 Git Bash 跑通为验收标准 | 项目无 CI，README 依赖节明示 Windows Git Bash 是主环境 |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|

## Notes

- install.sh 改动需真机重装验证——它会把本仓库同步到 ~/.claude/，属预期行为
- Phase 2 若发现 py/sh 已有行为分叉，记录到 findings.md，不擅自"修对齐"，报给用户裁决
