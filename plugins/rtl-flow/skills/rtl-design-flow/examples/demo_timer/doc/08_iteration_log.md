---
doc: 08_iteration_log
ip: demo_timer
version: 1.3
status: Released
updated: 2026-10-24
owner: rtl-flow-example
---

# demo_timer 迭代记录

## 1. 迭代总览 (Summary)

> 每轮修改追加一行，新的在下。

| ID | 日期 | 触发 | 根因类别 | 摘要 | 回归结果 |
|---|---|---|---|---|---|
| ITR-001 | 2026-10-22 | Lint | RTL bug | `demo_timer_reg_top` 多余输出端口 `ctrl_mode_o` 未被使用，删除 | 未运行（P3 阶段尚无 testbench）；lint 0 warning |
| ITR-002 | 2026-10-22 | 仿真失败 | 工具问题 | iverilog 13 不支持对 `string` 使用 `case`，编译崩溃；testbench 改用 if 链 | 13/13 通过 |
| ITR-003 | 2026-10-22 | 评审意见 | TB bug | 变异测试发现随机用例检测不到「非对齐地址命中」类缺陷；补充随机地址池 | 13/13 通过；变异 6/6 检出 |
| ITR-004 | 2026-10-22 | 评审意见 | Spec 错误 | 综合实测逻辑深度 32 级，与 02 初估「< 30 级」不符；修正文档 | 不涉及 RTL |
| ITR-005 | 2026-10-22 | 需求变更 | 需求变化 | CR-1：新增 `CTRL.CLR` 计数清零（REQ-FUNC-006），IP 版本 1.0.0 → 1.1.0 | 14/14 通过；变异 7/7 检出 |
| ITR-006 | 2026-10-22 | 签核 | — | 签核回归：`test_random` 50 个种子 | 59/59 通过；覆盖点 13/13 |
| ITR-007 | 2026-10-22 | 用户反馈 | — | rtl-flow 0.2.0 流程升级：补审核记录、lint 报告入库 | 不涉及 RTL；lint PASS；signoff 0 error |
| ITR-008 | 2026-10-23 | 用户反馈 | — | 编码规范改为华为 Verilog 规范：RTL / testbench 改写为 Verilog-2001，端口改名，IP 版本 1.1.0 → 2.0.0 | 59/59 通过；覆盖点 13/13；变异 7/7 检出 |

> 触发：仿真失败 / Lint / 需求变更 / 评审意见 / 用户反馈。
> 根因类别：Spec 错误 / 需求变化 / RTL bug / TB bug / 工具问题。

## 2. 迭代详情 (Details)

### ITR-001 删除未使用的 `ctrl_mode_o` 端口

- **日期**：2026-10-22
- **触发**：P3 lint，`verilator --lint-only -Wall`：`%Warning-UNUSEDSIGNAL: rtl\demo_timer.sv:20:25: Signal is not used: 'ctrl_mode'`
- **现象**：`demo_timer_reg_top` 输出 `ctrl_mode_o`，顶层连到线网 `ctrl_mode` 后无人使用。
- **根因**：02 架构初稿把 `CTRL.MODE` 列为 `reg_top` → `core` 的接口，但「单次模式到时清零 EN」在 `reg_top` 内完成，`core` 不需要模式信息。（类别：RTL bug）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `rtl/demo_timer_reg_top.sv` | 删除输出端口 `ctrl_mode_o` 及其赋值 |
  | `rtl/demo_timer.sv` | 删除线网 `ctrl_mode` 及端口连接 |
  | `doc/02_architecture.md` | §1 框图与 §2 子模块接口删除 `ctrl_mode` |
- **影响文档**：02_architecture §1、§2
- **关联**：无
- **回归结果**：lint 0 warning；`check_docs.py --stage rtl` 0 error。

### ITR-002 iverilog 不支持 string case

- **日期**：2026-10-22
- **触发**：首次运行 `dv/run_sim.py`，编译失败：`Assertion failed: ivl_expr_value(expr) == IVL_VT_BOOL || ivl_expr_value(expr) == IVL_VT_VECTOR, file ../../tgt-vvp/eval_vec4.c, line 1359`
- **现象**：iverilog 代码生成阶段内部断言失败，无源码行号。
- **根因**：二分排查确认由 testbench 主流程 `case (test)`（`test` 为 `string`）触发，属于 iverilog 13 的限制。（类别：工具问题）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `dv/tb/tb_demo_timer.sv` | 用例分发由 `case (test)` 改为 `if / else if` 字符串比较 |
- **影响文档**：无
- **关联**：无
- **回归结果**：13/13 通过（8 个定向用例 + `test_random` 5 个种子），10/10 覆盖点命中。

### ITR-003 变异测试暴露随机用例检查盲区

- **日期**：2026-10-22
- **触发**：首轮回归一次全部通过。为确认 testbench 不是「假通过」，向 RTL 注入 6 个已知缺陷（变异测试）。
- **现象**：6 个变异全部被至少一个用例检出；但 M4（非对齐地址 `0x006` 误命中 `CMP`）只被定向用例 `test_apb_err` 检出，`test_random` 漏检。
- **根因**：`test_random` 的非法地址池只有越界地址和 `0x001`，不含「合法偏移 + 1~3」的非对齐地址。（类别：TB bug）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `dv/tb/tb_demo_timer.sv` | 随机非法地址池加入 5 个寄存器偏移 + 1~3 的全部非对齐地址 |
  | `dv/run_mutation.py` | 新增：变异测试脚本，固化 M1 ~ M6 |
- **影响文档**：07_dv_plan §2、§5、§7
- **关联**：DEC-001、DEC-002、DEC-003（M1 ~ M3 分别验证其被检查）
- **回归结果**：13/13 通过；变异测试 6/6 检出，M4 现可被 `test_apb_err` 与 `test_random` 同时检出。

### ITR-004 修正关键路径估计

- **日期**：2026-10-22
- **触发**：为完成 D2 签核项「综合无 latch」，新增 `syn/synth.ys` 并运行 Yosys 综合。
- **现象**：68 个触发器、497 个二输入门、无 latch，与预期一致；`ltp` 报告最长组合路径 32 级，02 §8 初估为「< 30 级」。
- **根因**：初估未计入 32 bit 比较器的进位链深度。（类别：Spec 错误）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `syn/synth.ys` | 新增：Yosys 综合脚本，内含无 latch 断言 |
  | `doc/02_architecture.md` | §8 改为综合实测数据 |
- **影响文档**：02_architecture §8；07_dv_plan TP-010
- **关联**：REQ-PERF-001
- **回归结果**：不涉及 RTL，无需回归。

### ITR-005 需求变更 CR-1：计数清零

- **日期**：2026-10-22
- **触发**：需求变更 CR-1（00_requirements SRC-3）：软件需要能随时将计数值清零。
- **现象**：v1.0 只能在复位或到时后归零（01_spec v1.0 §9 已记录为限制）。
- **根因**：新增需求。（类别：需求变化）
- **修改**（按 `00 → 01/02/09 → yaml → RTL → DV` 顺序）：
  | 文件 | 修改摘要 |
  |---|---|
  | `doc/00_requirements.md` | 新增 SRC-3、REQ-FUNC-006 |
  | `doc/01_spec.md` | 新增 §3.6；更新 §2、§3.1、§9 |
  | `doc/09_decisions.md` | 新增 DEC-005（实现方式选择） |
  | `data/demo_timer.yaml` | `CTRL` 新增字段 `CLR` [2] (wo)；版本 1.1.0；重新生成 03/04/C 头文件 |
  | `doc/02_architecture.md` | §1 框图、§2 接口、§4 次态表 |
  | `rtl/demo_timer_reg_top.sv` | 新增输出 `ctrl_clr_o` = 写 `CTRL` 且 `pwdata[2]` |
  | `rtl/demo_timer_core.sv` | 新增输入 `clr_i`，清零优先级最高 |
  | `rtl/demo_timer.sv` | 连接 `ctrl_clr` |
  | `doc/05_rtl_structure.md`、`doc/06_programmers_guide.md` | 信号说明；读-改-写示例 `timer_restart()` |
  | `dv/tb/tb_demo_timer.sv` | 参考模型加入 CLR；新增 `test_clr` 与 3 个覆盖点 |
  | `dv/run_sim.py`、`dv/run_mutation.py` | 登记 `test_clr`；新增变异 M7 |
  | `doc/07_dv_plan.md` | 新增 TP-011，更新追溯矩阵 |
  | `CHANGELOG.md` | 1.1.0 |
- **影响文档**：00、01、02、03、04、05、06、07、09、CHANGELOG
- **关联**：REQ-FUNC-006、DEC-005、TP-011、BUG-003
- **过程中的问题**：
  1. 修改 00 后立即运行 `check_docs.py --stage dv`，报 `REQ-FUNC-006 not covered by any spec section / test point`，确认闸门生效，按顺序补齐。
  2. 写完 DEC-005 后 `--stage rtl` 报 `TP-011 referenced but not defined`，在 07 中定义后消除。
  3. 首次回归 `test_clr` 失败：`read 0x008 = 0x00000006, expected 0x00000007`。参考模型监视器无报错，说明 RTL 符合规格；根因是用例把读访问的「建立 + 访问」算成 2 个沿，实际只有 1 个沿，期望值应为 6。（BUG-003，TB bug）
- **回归结果**：lint 0 warning；综合 68 个触发器（CLR 为组合脉冲，不增加触发器）、无 latch、最长路径 32 级；回归 14/14 通过，覆盖点 13/13；变异测试 7/7 检出。

### ITR-006 签核回归

- **日期**：2026-10-22
- **触发**：P6 签核，按 07_dv_plan §7 运行 `python dv/run_sim.py --seeds 50`。
- **现象**：全部通过。
- **根因**：不适用（例行回归）。
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | — | 无 |
- **影响文档**：无
- **关联**：无
- **回归结果**：59/59 通过（9 个定向用例 + `test_random` 50 个种子）；13/13 覆盖点命中，最少的 `sw_vs_hw_en` 命中 55 次。

### ITR-007 流程升级：审核点与 lint 报告

- **日期**：2026-10-22
- **触发**：用户反馈：希望在 G0（需求）、G1（规格）、G2（架构）停下来人工审核，并把 lint 结果落成可检查的文件。rtl-flow 升级到 0.2.0 后，`check_docs.py --stage signoff` 报 4 个 ERROR：00 / 01 / 02 `not approved`，`reports/lint.log missing`。
- **现象**：本示例按 0.1.0 规则完成，没有审核字段和 lint 报告文件。
- **根因**：规范新增要求，不是设计问题。（类别：不适用）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `doc/00_requirements.md`、`doc/01_spec.md`、`doc/02_architecture.md` | front matter 增加 `reviewer` / `approved: 1.1@2026-10-22`。审核人「示例用户」与 SRC-2 一样是模拟的用户角色；按新规则，ITR-005 修改 00 / 01 / 02 并提升到 1.1 时会重开 G0–G2，故记录的是 1.1 版的审核 |
  | `reports/lint.log` | 新增：`run_lint.py` 生成，Verilator 0 error / 0 warning |
  | `doc/10_checklist.md` | D0、D1 证据改为引用审核字段与 `reports/lint.log` |
  | `README.md` | 目录与命令加入 `reports/`、`run_lint.py` |
- **影响文档**：00、01、02（仅 front matter）、10、README
- **关联**：无
- **回归结果**：不涉及 RTL，无需仿真回归；`run_lint.py` PASS；`check_docs.py --stage signoff` 0 error。

### ITR-008 编码规范改为华为 Verilog 编码规范

- **日期**：2026-10-23
- **触发**：用户反馈：团队需要 Verilog 风格的代码，以华为 Verilog 编码规范为准。rtl-flow 将 `rtl-coding-style.md` 改写为华为规范（HW-xx 规则），`run_lint.py` 新增风格检查后，本示例原 RTL 报 126 条风格违规（SystemVerilog 关键字 75、端口命名 29、文件头 12、文件后缀 / 文件名 3、`timescale` 3、复位写法 2、端口顺序 2），`gen_docs.py` 报 yaml 端口命名错误。
- **现象**：RTL 与 testbench 为 SystemVerilog（`logic`、`always_ff`、`unique case`、`string`），端口用 `_i` / `_o` 后缀，寄存器用 `_q` / `_d`，复位写作 `if (!rst_ni)`。
- **根因**：编码规范变更，不是设计问题。（类别：不适用）
- **修改**：
  | 文件 | 修改摘要 |
  |---|---|
  | `data/demo_timer.yaml` | 版本 2.0.0；端口改名（对照表见 DEC-006）；`rtl_files` 改为 `.v` |
  | `rtl/demo_timer.v`、`rtl/demo_timer_reg.v`、`rtl/demo_timer_core.v` | 替代原 `.sv` 文件。Verilog-2001；华为规范文件头与命名；每个寄存器一个时序 `always` 块，用 `if` / `else if` 优先级链表达 DEC-002、DEC-003；读数据选择改为 `case (i_paddr)`；子模块 `demo_timer_reg_top` 改名 `demo_timer_reg` |
  | `dv/tb/demo_timer_tb.v` | 由 `tb_demo_timer.sv` 改写为 Verilog-2001：`string` 改为定宽 `reg`，`$sformatf` 改为 `$sformat`，局部数组改为选择函数；检查与覆盖点逻辑不变 |
  | `dv/run_sim.py`、`dv/run_mutation.py` | `iverilog -g2001`；testbench 路径与顶层名；M1 ~ M7 的注入位置按新 RTL 更新，注入的缺陷不变 |
  | `syn/synth.ys` | `read_verilog` 去掉 `-sv`，读取新文件 |
  | `doc/00`、`01`、`02`、`05`、`06`、`07`、`09`、`README.md` | 信号名、文件名、模块名更新；02 §8 组合逻辑门数更新为实测 494；05 §6 记录 HW-33 偏离；09 新增 DEC-006、DEC-007 |
  | `doc/03_interfaces.md`、`doc/04_registers.md` | 重新生成 |
  | `reports/lint.log` | 重新生成：风格检查 0 违规，Verilator（`--default-language 1364-2001`）0 error / 0 warning |
  | `CHANGELOG.md` | 新增 2.0.0 |
- **影响文档**：00、01、02（已审核文档，提升到 1.2，重开 G0 / G1 / G2）、03、04、05、06、07、09、10、README、CHANGELOG
- **审核**：2026-10-24 用户确认 00 / 01 / 02 v1.2 通过，写入 `approved: 1.2@2026-10-24`，状态改回 Released，10 清单 D0、D3 全部勾选。
- **关联**：DEC-006、DEC-007
- **回归结果**：`python dv/run_sim.py --seeds 50`：59/59 通过，13/13 覆盖点命中，最少的 `sw_vs_hw_en` 命中 55 次，与 ITR-006 相同（同种子下随机激励与 DUT 响应一致）；`python dv/run_mutation.py`：7/7 检出；Yosys：68 个触发器（36 个复位为 0、32 个复位为 1）、494 个二输入门（原 497）、最长路径 32 级，无 latch。

## 3. 缺陷列表 (Bugs)

| ID | 描述 | 发现于 | 修复于 | 状态 |
|---|---|---|---|---|
| BUG-001 | `reg_top` 多余输出端口 `ctrl_mode_o` | ITR-001 | ITR-001 | Closed |
| BUG-002 | `test_random` 不覆盖非对齐地址 | ITR-003 | ITR-003 | Closed |
| BUG-003 | `test_clr` 读 `COUNT` 期望值多算 1 拍 | ITR-005 | ITR-005 | Closed |
