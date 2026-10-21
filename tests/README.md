# tests/

## parity.sh — inject-plan.py ⇄ inject-plan.sh 等价性测试

双实现契约：同一项目状态 + 同一 `--context`，`inject-plan.py` 与 `inject-plan.sh`
（参考实现）必须输出字节一致的 stdout（见 inject-plan.py 头部声明）。

```bash
bash tests/parity.sh        # 全部用例
bash tests/parity.sh 3      # 只跑第 3 个用例
```

依赖：Python ≥ 3.8（PATH 上 python3/python/py 任一）+ Bash（Windows 用 Git Bash）。
用例失败时打印前 10 行 diff。

### 用例清单

| # | fixture | context | 覆盖点 |
|---|---------|---------|--------|
| 1 | 空项目 | userprompt | 无计划时双端静默一致 |
| 2 | 根目录 legacy 三件套 | userprompt | 基础注入路径 |
| 3 | 80 阶段长计划 | userprompt | 截断（head 窗口）一致性 |
| 4 | .planning/ 双命名计划无指针 | userprompt | 歧义 fail-closed 行为一致 |
| 5 | .planning/ 单计划 + .active_plan | userprompt | 命名计划选择路径 |
| 6 | legacy 计划 | precompact | PreCompact 注入 |
| 7 | legacy 计划 | preflight | 预检上下文 |

### 突变验证记录

- 2026-10-21：将 inject-plan.py:898 的 `===BEGIN-PWF-DATA` 改为 `===BEGIN-PWF-DATAX`
  → 3 个用例 FAIL；git checkout 还原后 7/7 PASS。harness 对字节级分叉有效。
- 注意：改 `===BEGIN PLAN DATA===` 类字符串（v2 静态标记）抓不到——当前实现
  的分隔符是 `===BEGIN-PWF-DATA kind=... nonce=...===`（inject-plan.py:898 /
  inject-plan.sh:1097），突变测试要打在真实产出行上。
