# dev-flow 严格审查报告（2026-10-21）

> 审查范围：全维度，按项目实际裁剪（纯 Markdown 技能包，无构建/性能/依赖维度）。
> 方法：三路并行取证（shell 脚本 / ps1+py 脚本 / 命令与文档一致性），全部结论带文件:行号证据。
> 状态：审查报告，未做任何代码改动。

## 审查范围覆盖说明

| 要求的维度 | 本项目适用性 |
|---|---|
| 项目结构与模块划分 | ✅ 见 F2、F3、F13（vendored 双实现、函数族四份拷贝） |
| 代码质量 | ✅ 见 F2-F9、F13-F16 |
| 性能/资源 | ➖ 无运行时服务；唯一性能敏感点（hook 10s 超时）已由 inject-plan.py 快路径解决，属正面项 |
| 依赖与配置 | ✅ 见 F10、F17、F18 |
| 测试 | ✅ 见 F12（最大缺口：双实现无等价性测试） |
| 工程化（CI/CD、可观测性） | ✅ 见 F11、F12；CI/CD 不适用（无构建，git 仓库 + 脚本即全部） |
| 安全与健壮性 | ✅ 见 F1、F4-F7、F19-F21 |

**做得好的（不凑数，仅确认）**：TOCTOU 防护、fail-closed 设计、PS1 全 ASCII 无 BOM、
Python 发现机制排除 WindowsApps 别名、头部文档 12/12 齐全、`docs/harness/plans/` 路径约定全库统一无残留、
writing-plans 分叉"3 处"与 README 血缘表完全吻合、install.sh 结尾提示与 README 一致。

---

## 优先级清单（高 → 低）

### 【高】F1. install.sh 先 `rm -rf` 后 `cp -r`，失败即销毁技能且留下半装状态

- **位置**：`install.sh:10-11`（rm 在前 cp 在后，无 trap/backup）；`install.sh:14-15`（无 `mkdir -p`）
- **影响与风险**：cp 失败（权限/磁盘中断）时同名技能已被删除、无备份、无回滚——install.sh 自身制造的丢失风险比它防御的任何风险都大；全新机器上 `~/.claude/commands/` 不存在时 cp 失败，`set -euo pipefail` 中止，结果是 7 技能已装、6 命令全缺的静默半装态。严重程度：**高**
- **修改方案**：
  ```bash
  mkdir -p "${DEST}/skills" "${DEST}/commands"
  for d in "${SRC}"/skills/*/; do
    name="$(basename "$d")"
    rm -rf "${DEST}/skills/${name}.bak"
    [ -d "${DEST}/skills/${name}" ] && mv "${DEST}/skills/${name}" "${DEST}/skills/${name}.bak"
    if cp -r "$d" "${DEST}/skills/${name}"; then
      rm -rf "${DEST}/skills/${name}.bak"
    else
      [ -d "${DEST}/skills/${name}.bak" ] && mv "${DEST}/skills/${name}.bak" "${DEST}/skills/${name}"
      echo "FAILED: ${name}"; exit 1
    fi
  done
  ```
- **成本**：小；非破坏性变更

### 【高】F2. phase-status.ps1 / ledger-append.ps1 / ledger-summary.ps1 自铸 resolver，绕过 slug+containment 防护

- **位置**：`phase-status.ps1:43-85`（`Join-Path $planRoot $env:PLAN_ID` 后仅 `Test-Path`）；`ledger-append.ps1:55-88`（同）；`ledger-summary.ps1:31-64`（同，只读降档）
- **影响与风险**：`PLAN_ID='..\..\other'` 可选中项目外目录——phase-status 做状态**改写**、ledger-append 做**写入**，路径穿越防护被包装脚本自铸副本绕过。对照 sh 侧同功能走 resolve-plan-dir.sh 的完整 `Test-ValidSlug` + `Test-WithinRoot`（resolve-plan-dir.sh:65-228、resolve-plan-dir.ps1:115-158），这是 ps1 侧单方面缺失。严重程度：**高**
- **修改方案**：三个脚本的 `Resolve-PlanDir`/`Resolve-PlanFile` 改为调用 `resolve-plan-dir.ps1`（与 sh 侧消费脚本 ledger-append.sh:47-65 的包装模式对齐），删除各自的裸 `Test-Path` 分支
- **成本**：中；非破坏性变更

### 【高】F3. 双实现（sh/py）无等价性测试，py 头部引用的测试在本仓库不存在

- **位置**：`inject-plan.py:27` 引用 `tests/test_inject_plan_python_parity.py`，全仓库无 tests 目录（find 无结果）
- **影响与风险**：inject-plan.py（1754 行）与 inject-plan.sh（1406 行）是刻意维护的字节级孪生，任何一侧改动都必须三处同步（sh/py/ps1）。等价性保证完全依赖一个**不存在的测试**——每次改动的回归防线为零，而历史上已经真实漂移过一次（resolve-plan-dir.sh:178-179 注释自认）。严重程度：**高**
- **修改方案**：最小可行：新建 `tests/`，写对比 harness——同一组固定 stdin fixture 分别喂 `inject-plan.py --context` 与 `skill-hook.sh` 快路径关闭版，diff stdout。10 个左右覆盖：无计划/单计划/多计划歧义/超长截断/attestation 各一
- **成本**：中；非破坏性变更

### 【高→中】F4. set-active-plan.sh 完全忽略 PWF_PLAN_ROOT 钉住，注释与实现矛盾

- **位置**：`set-active-plan.sh:6-8`（硬编码 `PLAN_ROOT="${PWD}/.planning"`）vs `set-active-plan.sh:130-133`（注释宣称支持 pin containment）
- **影响与风险**：用户按 issue #212 用 `PWF_PLAN_ROOT` 钉住子目录后执行 `set-active-plan.sh <id>`，会改写**父目录**项目的 `.active_plan`——恰是该 pin 要防止的错误。严重程度：**高**（当前使用模式是单项目平铺时不会触发，故实际暴露面有限）
- **修改方案**：脚本开头增加与消费脚本一致的 pin 读取：`PLAN_ROOT="${PWF_PLAN_ROOT:-${PWD}/.planning}"`，并补充 containment 校验
- **成本**：小；非破坏性变更

### 【中】F5. plan-attest.md / plan-doctor.md 只写 plugin 路线，本包主安装路线下必失败

- **位置**：`commands/plan-attest.md:22-24`（仅 `${CLAUDE_PLUGIN_ROOT}` 三条路线）；`commands/plan-doctor.md:11-12`（同）
- **影响与风险**：本包经 install.sh 装到 `~/.claude/skills/` 后 `CLAUDE_PLUGIN_ROOT` 为空（SKILL.md hook 里的 `[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && exit 0` 明确承认此布局）——而 /plan-doctor 正是 README.md:57 与 install.sh:23 指定的**首次验证入口**，新用户首跑即失败。严重程度：**中**
- **修改方案**：两个命令各补第 4 条路线：`sh ~/.claude/skills/planning-with-files/scripts/<脚本>.sh`，并置于首位（本包主路线）
- **成本**：小；非破坏性变更

### 【中】F6. planning-with-files SKILL.md 把无参 init-session.sh 描述为"backward-compatible"，与包内禁令相反

- **位置**：`planning-with-files/SKILL.md:225`（"legacy mode, backward-compatible"）vs `CLAUDE-workflow.md:29`、`commands/plan.md:14`（明令禁止）
- **影响与风险**：模型直接触发技能（不经 /plan 命令）时读到的是 SKILL.md 正文——权威文本侧是"合法"，会按上游习惯把三件套写到项目根，正是包约定要废弃的位置。两个信息源互相打架，模型行为不可预测。严重程度：**中**
- **修改方案**：SKILL.md:225 处加 deprecated 警示："⚠ 本包已禁用无参模式（写入已废弃位置）；必须显式指定计划目录"，与 vendored 改造层对齐
- **成本**：小；非破坏性变更

### 【中】F7. init-session.ps1 在 PS 5.1 下写 BOM，与同包 phase-status.ps1 的 BOM 规避方针自相矛盾

- **位置**：`init-session.ps1:258,290,319,340`（`Out-File -Encoding UTF8` = BOM + CRLF）；对照 `phase-status.ps1:249-257` 自己的长注释论证过必须 `UTF8Encoding($false)`
- **影响与风险**：同一计划由 PS 创建 vs sh 创建首字节不同；BOM 前缀使 inject-plan.py:706 的 `line.startswith(b"# ")` 丢标题。严重程度：**中**
- **修改方案**：四处 `[IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))` 替换 `Out-File -Encoding UTF8`
- **成本**：小；非破坏性变更

### 【中】F8. README/CLAUDE.md 谎称 "superpowers 纯 Markdown 无脚本依赖"

- **位置**：`README.md:62`、`CLAUDE.md:35` vs `skills/brainstorming/scripts/`（server.cjs、helper.js、start-server.sh 等）+ `visual-companion.md:38-98`
- **影响与风险**：用户据此不装 Node，visual companion 静默失效。另：`CLAUDE.md:35` "superpowers five" 实际列 6 个技能，口径混乱。严重程度：**中**
- **修改方案**：改为"superpowers 技能为纯 Markdown；brainstorming 的 visual companion 需 Node.js（可选）"；顺修 "five"→"六件套"
- **成本**：小；非破坏性变更

### 【中】F9. vendored 文档残留大量悬空子技能引用

- **位置**：`writing-plans/SKILL.md:14,59,191,201`（`superpowers:subagent-driven-development`、`superpowers:using-git-worktrees`，且模板把前者列为 REQUIRED）；`executing-plans/SKILL.md:88,104,242,304,372`（`finishing-a-development-branch`、`requesting-code-review`）
- **影响与风险**：模型按模板生成的每份计划头都携带不存在的子技能指令，执行时要么幻觉执行、要么无谓报错。严重程度：**中**
- **修改方案**：两类处理：删除引用，或在其后加"（不在本包内，跳过该步骤）"标注。建议删除 REQUIRED 引用、其余加标注
- **成本**：小；非破坏性变更

### 【中】F10. 计划目录解析 + Windows 兼容函数族在 4 个脚本中整段复制粘贴，且已发生语义漂移

- **位置**：`resolve-plan-dir.sh:65-228`（权威）、`inject-plan.sh:140-247`、`set-active-plan.sh:11-174`（含逐字相同的 100+ 行注释）、`skill-hook.sh:73-121`（WindowsApps 判断已退化为子串匹配，语义与其他三份不同）
- **影响与风险**：修一个 canonicalize bug 需同步 4 处；注释自认历史上漂移过一次。5 个消费脚本另各有手写的 resolver 包装（ledger-append.sh:47-65 等）。严重程度：**中**
- **修改方案**：短期接受内联（hook 单文件约束真实存在），但把 skill-hook.sh:73-121 的 `select_python` 对齐回权威 case 模式；长期在 resolve-plan-dir.sh 提供 `--source` 模式供其他脚本 source
- **成本**：小（对齐 select_python）/ 大（source 化重构）；非破坏性

### 【中】F11. flock + unlink 锁文件竞态（sh/ps1 两侧同病）

- **位置**：`ledger-append.sh:330-339`、`attest-plan.sh:253-262`、`ledger-append.ps1:168-186`
- **影响与风险**：unlink-under-flock 竞态可让两个等待者同时进入临界区；对 ledger 只是 tick 计数重复（低危），对 `.attestation` 削弱声称的互斥。严重程度：**中**
- **修改方案**：不 rm 锁文件，改为持久锁文件 + flock；或接受现状但在注释中明确"互斥为尽力而为"
- **成本**：小；非破坏性变更

### 【中】F12. inject-plan.py 错误静默吞掉，违反自身契约

- **位置**：`inject-plan.py:1743-1744`（`except Exception: return 3` 连一行 stderr 都不留）；`inject-plan.py:1747-1749`（stdout 写失败 `except: pass`，exit 0 却无输出）
- **影响与风险**：return 3 走 shell 回退本身是文档化契约，但失败原因完全不可见，调试只能盲猜；stdout 静默丢失则主调方以为成功。严重程度：**中**
- **修改方案**：两处 except 中各加 `print(f"...: {e}", file=sys.stderr)`（stderr 不参与 hook 协议）
- **成本**：小；非破坏性变更

### 【中】F13. session-catchup.py frame_untrusted_context 字节裁剪可截断 UTF-8 多字节字符导致崩溃

- **位置**：`session-catchup.py:219-238`（`errors='replace'` 后重编码，再按字节 `payload[:-1]` 裁剪，最后严格 `payload.decode('utf-8')`）
- **影响与风险**：裁剪落在多字节字符中间 → UnicodeDecodeError traceback，整个 hook 崩溃。当前调用方内容远小于 65536 故属潜伏缺陷，但 `--replay` 帧控契约本身被破坏。严重程度：**中**（潜伏）
- **修改方案**：裁剪后改用 `payload.decode('utf-8', errors='ignore')`，或裁剪前按字符数而非字节数
- **成本**：小；非破坏性变更

### 【中】F14. commands/plan-loop.md 引用不存在的 /plan-goal，巡检 prompt 带悬空相对路径

- **位置**：`plan-loop.md:36`（`/plan-goal` 不在 commands/ 6 个文件之列，SKILL.md:284-289 明说其仅 plugin 路线提供）；`plan-loop.md:19`（`scripts/check-complete.sh` 相对路径在目标项目根下不存在）
- **影响与风险**：模型照执行必失败。严重程度：**中**
- **修改方案**：plan-loop.md 删 /plan-goal 引用改述 manual fallback（SKILL.md:324-347 已有现成文本）；19 行补全 `~/.claude/skills/planning-with-files/scripts/check-complete.sh`
- **成本**：小；非破坏性变更

### 【中】F15. phase-status.ps1 状态改写不跳过 fenced code block

- **位置**：`phase-status.ps1:214-243`（直接 `-match '\*\*Status:\*\*'`）；对照 `set-active-plan.ps1:212-231` 与 sh 侧（set-active-plan.sh:195-203）均有围栏状态机
- **影响与风险**：计划文档里示例代码中的 `**Status:**` 行会被误改写。严重程度：**中**
- **修改方案**：移植 set-active-plan.ps1:212-231 的 ```/~~~ 围栏状态机
- **成本**：小；非破坏性变更

### 【中】F16. 超长函数集中（Injector._run 约 417 行）

- **位置**：`inject-plan.py:930-1346`（`_run`）；`session-catchup.py:528-689`（`opencode_catchup` 约 162 行）；另 `secure_progress_marker`（inject-plan.py:524-647）约 124 行
- **影响与风险**：`_run` 把解析/安全检查/attestation/guard/注入全部内联，是"逐字节对齐 sh"约束的代价——任何改动都在巨型函数里做，且与 sh 的逐段 diff 困难。严重程度：**中**（可维护性）
- **修改方案**：不急于拆——先落 F3 的等价性测试，有防线后再按"安全检查/attestation/注入"三段提函数。**顺序不可反**
- **成本**：大（须在测试防线之后）；非破坏性

### 【低】F17. init-session.sh 缺 set -u 且 --template 尾随时静默退出

- **位置**：`init-session.sh:25`（仅 `set -e`）、`init-session.sh:50`（`TEMPLATE="$2"` 展开空 + `shift 2` 失败被 set -e 吞）
- **修改方案**：改 `set -eu`；解析循环对 `--template` 显式检查 `$# -ge 2`。成本：小
- 严重程度：**低**

### 【低】F18. inject-plan.sh 内部 mtime 兜底缺 trusted-python、python 探测策略不一致

- **位置**：`inject-plan.sh:323`（缺 trusted-python 兜底，与 resolve-plan-dir.sh:233-247 分叉）；`ledger-append.sh:210-217`（无版本探测、不试 `py` 启动器，与 init-session.sh:117、inject-plan.sh:54 不一致）
- **影响与风险**：Windows 原生 stat 下 newest-mtime 回退失效（fail-closed 无注入，安全但功能缺失）；PATH 上 Python 2 会静默落 1970 时间戳。成本：小
- 严重程度：**低**

### 【低】F19. plan-attest.md 的 --target 与 --show/--clear 互斥未说明

- **位置**：`plan-attest.md:14,27-28` vs `attest-plan.sh:147-157`（`--show` 要求唯一参数）
- **影响与风险**：模型很可能拼出 `--target root --show` 报 usage 错。修改方案：文档改为"--show/--clear 用 PWF_PLAN_ROOT 环境变量而非 --target"。成本：小
- 严重程度：**低**

### 【低】F20. slug 语义跨平台分叉 + 杂项文案错误

- **位置**：`init-session.sh:73-81` vs `init-session.ps1:64-78`（非 ASCII 名字两条路线生成不同计划目录名）；`set-active-plan.ps1:336`（PowerShell 环境提示运行 init-session.**sh**）；`commands/flow.md:5,15`（依赖全局 CLAUDE.md 已合并，install.sh 不校验）；`inject-plan.py:912,919`（`smart_plan_extract` 同一 plan 算两遍）；`ledger-summary` ps1 缺 sh 版的位置参数能力
- 修改方案：各自一行修复；slug 分叉记录到 README 血缘表即可（低频路径）。成本：小
- 严重程度：**低**

### 【低】F21. inject-plan.py Windows 缓存根在无 HOME 时 fail-closed

- **位置**：`inject-plan.py:300-307,1132-1141`（`XDG_CACHE_HOME→HOME→TMPDIR|/tmp`，Windows 原生 Python 无 HOME 落 /tmp 不存在 → Bail）
- **影响与风险**：当前只经 sh 启动器运行被掩盖；`--claude-event` 可独立入口。严重程度：**低**
- **修改方案**：链首补 `LOCALAPPDATA`。成本：小

### 【不修，记录为知情设计】

- **双实现孪生（inject-plan.py 1754 行 + sh 1406 行 + py 反向调 sh）**：为解决 Git Bash 130 次 fork / 10s 超时的刻意设计（inject-plan.py:1-30），瓶颈真实，方案成立。代价由 F3 的测试缺口承接，而非推翻设计。
- **install.sh 无版本化/无卸载**：与 vendored 模式自洽（README 血缘表承担溯源），F1 的 .bak 备份已兜住数据安全面。
- **ledger 截断语义 sh 按字节 / ps1 按字符**：平台运行时差异，非 bug。
- **fenced code block 状态机在 set-active-plan 对两侧均有、仅 phase-status.ps1 缺**（F15），属个别遗漏非系统性缺失。

---

## 需要确认的问题（信息不足项，未臆测）

1. planning-with-files 声称"基于上游 v3.24.0 无直接改动"——未逐行比对上游，无法证伪；若未来要合并上游 v3.25.0，建议先落 F3 测试再动。
2. F4 的实际暴露面取决于你是否真用 `PWF_PLAN_ROOT` 钉住子目录；若从不用，可降为低优先级。
3. `inject-plan.py:27` 引用的 parity 测试可能存在于上游仓库而未随 vendored 拷贝过来——值得去上游确认，能抄就抄。

## 最值得优先做的 3 项

1. **F1（install.sh 备份式安装 + mkdir -p）**——成本最小（十几行脚本），消除的是安装器自己制造的数据丢失风险，且所有后续改动都依赖重跑 install.sh 同步，它是全链路的入口。
2. **F3（补 sh/py 等价性测试）**——是 F10/F16/F12 等一切双实现演进的前置防线；没有它，双实现只能冻结，任何优化都要裸奔三处同步。
3. **F5 + F14（命令文档的悬空路径/引用一次修完）**——/plan-doctor 是指定的首次验证入口，首跑必败直接摧毁新用户对整包的信任；这些全是纯 Markdown 一行级修复，五分钟内可全部清零。

## 最大的单点风险

**双实现/三实现（sh / py / ps1）体系无任何测试防线**（F3 + F10）。整个 PWF 的安全性建立在 resolve/canonicalize/containment 逻辑的跨副本一致上，而这套逻辑现存 4 份 bash 拷贝 + 8 份 ps1 + 2 份 py，其中至少一处已语义漂移（skill-hook.sh 的 WindowsApps 判断）、至少一处已单方面缺失防护（ps1 自铸 resolver）、测试文件压根不存在。下一次任何一个脚本的安全修复，都有很高概率没有同步到其余副本——而哪个副本被 hook 实际执行，取决于平台与调用路径，问题将以"偶发、难复现"的形态出现。
