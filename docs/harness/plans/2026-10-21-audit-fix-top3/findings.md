# Findings & Decisions

## Requirements

- 修复审查报告（docs/harness/2026-10-21-audit-report.md）Top 3：F1 install.sh、F3 等价性测试、F5+F14 命令文档
- 全部修复须带命令证据验证（verification-before-completion）
- commit 须用户确认后执行

## Research Findings

- F1 证据：install.sh:10-11 rm 在 cp 前、无备份；install.sh:14-15 无 mkdir -p，全新机器 ~/.claude/commands 不存在时半装
- F3 证据：inject-plan.py:27 引用 tests/test_inject_plan_python_parity.py，本仓库无 tests/；双实现 sh 1406 行 + py 1754 行，历史上已漂移过一次（resolve-plan-dir.sh:178-179 注释自认）
- F5 证据：commands/plan-attest.md:22-24、plan-doctor.md:11-12 只有 ${CLAUDE_PLUGIN_ROOT} 路线；standalone 安装下该变量为空（SKILL.md hook 的 fallback 路径 $HOME/.claude/skills/planning-with-files/scripts/ 证明实际布局）
- F14 证据：plan-loop.md:36 引用 /plan-goal（不在 commands/）；plan-loop.md:19 的 scripts/check-complete.sh 是悬空相对路径
- F19 证据：attest-plan.sh:147-157 要求 --show/--clear 为唯一参数，plan-attest.md:14,27-28 未声明与 --target 互斥
- inject-plan 的运行入口：skill-hook.sh:140-149 优先 py（PWF_FAST_PATH），非零退出回退 sh inject-plan.sh —— 等价性测试应覆盖这两条路径

- F19 实测修正（Phase 3 发现）：原报告建议"--show 用 PWF_PLAN_ROOT 环境变量替代 --target"是**错的**——pin 模式 resolver 只找 `${PWF_PLAN_ROOT}/.planning/`（resolve-plan-dir.sh:48），而 `--show/--clear` 强制唯一参数（attest-plan.sh:148-149）无法加 `--target root`。实测正确用法：cwd 切到计划目录走 legacy 回退（`./task_plan.md`），输出 Attestation: ./.plan-attestation ✅。文档已按实测修正
- Key Question 1 解答：fixture 用 legacy 根目录三件套 + .planning/ 命名计划两种布局，均已验证 resolver 可解析
- Key Question 2 解答：按本机 Git Bash 验收（已落地，7/7 PASS）

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| install.sh 用 .bak 备份 | 审查报告 F1 原方案；跨文件系统兼容、失败回滚直白 |
| 等价性测试 = stdout diff | 双实现契约即"同输入同输出" |
| 验收环境 = 本机 Git Bash | 无 CI，主环境即 Windows Git Bash |

## Issues Encountered

| Issue | Resolution |
|-------|------------|

## Resources

- 审查报告：docs/harness/2026-10-21-audit-report.md
- inject-plan.py:1-70（双实现设计自述、fork 性能动因）
- skill-hook.sh:140-149（py 优先 / sh 回退入口）

---

*Update this file regularly during research so important evidence remains available after context changes.*
