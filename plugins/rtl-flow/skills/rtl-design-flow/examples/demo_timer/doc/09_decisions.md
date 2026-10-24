---
doc: 09_decisions
ip: demo_timer
version: 1.2
status: Released
updated: 2026-10-23
owner: rtl-flow-example
---

# demo_timer 设计决策记录

## 1. 决策总览 (Summary)

| ID | 日期 | 标题 | 状态 |
|---|---|---|---|
| DEC-001 | 2026-10-22 | 到时比较使用「≥」而非「=」 | 已采纳 |
| DEC-002 | 2026-10-22 | `CTRL.EN` 软件写与硬件清零同拍时软件优先 | 已采纳 |
| DEC-003 | 2026-10-22 | `INTR_STATE.EXPIRED` 硬件置位与软件清除同拍时置位优先 | 已采纳 |
| DEC-004 | 2026-10-22 | 断言以 testbench 监视器实现，不写入 RTL | 已采纳 |
| DEC-005 | 2026-10-22 | 计数清零以 `CTRL.CLR` 写 1 触发实现 | 已采纳 |
| DEC-006 | 2026-10-23 | RTL 编码规范改为华为 Verilog 编码规范，端口改名 | 已采纳 |
| DEC-007 | 2026-10-23 | 顶层 APB 输出与中断不经寄存器输出（偏离 HW-33） | 已采纳 |

> 状态：提议 / 已采纳 / 已废弃（被 DEC-xxx 取代）。

## 2. 决策详情 (Details)

### DEC-001 到时比较使用「≥」而非「=」

- **背景**：REQ-FUNC-002 要求计数值达到比较值时到时。软件可能在计数过程中修改 `CMP.VAL`。
- **选项**：
  1. `COUNT == CMP`：比较器略小；但运行中把 CMP 改到当前计数值以下时，要计到 2^32 回绕才到时（100 MHz 下约 43 s），软件难以察觉。
  2. `COUNT >= CMP`：32 bit 比较器略大；改小 CMP 时立即到时，行为可预期。
- **结论**：选 2。100 MHz 下 32 bit 比较器时序余量充足（REQ-PERF-001），可预期性更重要。
- **影响**：01_spec §3.2、06_programmers_guide §5；验证需覆盖「运行中改小 CMP」场景。

### DEC-002 `CTRL.EN` 软件写与硬件清零同拍时软件优先

- **背景**：REQ-FUNC-003 要求单次模式到时后硬件清零 `CTRL.EN`。软件写 `CTRL` 可能与到时事件发生在同一周期。
- **选项**：
  1. 硬件清零优先：软件的启动/重配置写入会被吞掉，软件必须回读确认。
  2. 软件写优先：软件写入的值总是生效；代价是若软件恰好写 EN = 1，单次定时会被视为重新启动。
- **结论**：选 2。软件写入意图明确，「写了却不生效」更难调试。
- **影响**：01_spec §3.3；RTL `demo_timer_reg` 中 `ctrl_en_r` 的 `if` / `else if` 优先级链里软件写为第一个分支。

### DEC-003 `INTR_STATE.EXPIRED` 硬件置位与软件清除同拍时置位优先

- **背景**：REQ-FUNC-005 要求写 1 清除中断状态。周期模式下，软件清除可能与下一次到时同拍。
- **选项**：
  1. 软件清除优先：可能丢失一次中断。
  2. 硬件置位优先：不丢中断；`CMP.VAL` = 0 的周期模式下状态无法清除。
- **结论**：选 2，这是中断状态寄存器的通行做法；`CMP.VAL` = 0 的副作用写入 01_spec §9 与编程指南。
- **影响**：01_spec §6、§9；06_programmers_guide §5。

### DEC-004 断言以 testbench 监视器实现，不写入 RTL

- **背景**：rtl-coding-style §7 要求关键协议与不变式用 SVA 实现。示例环境仅有 iverilog 13，不支持并发断言 (`assert property`)。
- **选项**：
  1. 在 RTL 中写 SVA 并用 `` `ifdef `` 屏蔽：iverilog 下不生效，等于没有检查。
  2. 在 testbench 中用逐周期监视器 + 参考模型实现同等检查：任何仿真器都能运行。
- **结论**：选 2。检查内容见 07_dv_plan §4。迁移到商用仿真器时，可把监视器中的不变式改写为 bind SVA。
- **影响**：05_rtl_structure §6 记录为编码规范偏离；07_dv_plan §4。
- **后续**：DEC-006 采用华为 Verilog 编码规范后，规范本身禁止在 RTL 中写 SVA（rtl-coding-style §10），本决策成为规范要求，不再是偏离。

### DEC-005 计数清零以 `CTRL.CLR` 写 1 触发实现

- **背景**：需求变更 CR-1 新增 REQ-FUNC-006，要求软件能随时清零计数值。
- **选项**：
  1. 把 `COUNT` 改为可写 (rw)：功能更通用（可写任意值），但改变已发布寄存器的访问类型，影响 REQ-REG-002 和已有软件，并增加 32 bit 写数据通路。
  2. 新增独立的命令寄存器：占用新地址，增加一个寄存器的译码与文档。
  3. 在 `CTRL` 的空闲位 [2] 增加只写位 `CLR`，写 1 产生单周期清零脉冲：改动最小，无新增触发器；缺点是写 `CLR` 会同时写 `EN`/`MODE`，软件需读-改-写。
- **结论**：选 3。改动最小、向后兼容（旧软件写 `CTRL` 时 bit 2 为 0，行为不变）。读-改-写要求写入 01_spec §3.6 与编程指南。
- **影响**：data/demo_timer.yaml（`CTRL.CLR`）；01_spec §3.6、§9；02_architecture §4；06_programmers_guide；RTL 两个子模块；07_dv_plan 新增 TP-011。

### DEC-006 RTL 编码规范改为华为 Verilog 编码规范，端口改名

- **背景**：团队要求 RTL 采用 Verilog 风格，以华为 Verilog 编码规范为准。原 RTL 按 lowRISC SystemVerilog 风格编写（`logic`、`always_ff`、`_i` / `_o` 后缀、`_q` / `_d`）。rtl-flow 的 `rtl-coding-style.md` 改写为华为规范（HW-xx 规则），`run_lint.py` 增加自动风格检查。
- **选项**：
  1. 只改新 IP，本示例保留 SystemVerilog 写法：示例是 AI 的 few-shot 标杆，风格不一致会让新 IP 混用两种写法。
  2. 按新规范重写本示例 RTL 与 testbench，端口按 `i_` / `o_` 前缀改名：行为不变，但端口名变化对集成方不兼容。
- **结论**：选 2。IP 版本 1.1.0 → 2.0.0（端口改名为不兼容变化），寄存器与时序不变。端口对照：`clk_i` → `clk`、`rst_ni` → `rst_n`、`psel_i` → `i_psel`、`penable_i` → `i_penable`、`pwrite_i` → `i_pwrite`、`paddr_i` → `i_paddr`、`pwdata_i` → `i_pwdata`、`prdata_o` → `o_prdata`、`pready_o` → `o_pready`、`pslverr_o` → `o_pslverr`、`irq_o` → `o_irq`。子模块 `demo_timer_reg_top` 改名为 `demo_timer_reg`，例化名改为 `U_reg` / `U_core`。
- **影响**：data/demo_timer.yaml；00、01、02（信号名）；03 / 04（重新生成）；05；07；RTL 与 testbench 全部文件；`dv/run_sim.py`、`dv/run_mutation.py`、`syn/synth.ys`；CHANGELOG 2.0.0。

### DEC-007 顶层 APB 输出与中断不经寄存器输出（偏离 HW-33）

- **背景**：rtl-coding-style HW-33（华为规范「顶层输出信号必须寄存」）要求顶层输出经寄存器输出。本 IP 顶层输出 `o_prdata`、`o_pslverr`、`o_irq` 为寄存器值的组合逻辑，`o_pready` 为常量。
- **选项**：
  1. 全部改为寄存器输出：APB 零等待（REQ-IF-001）要求读数据在访问周期内有效，寄存输出需在建立周期预取读数据，`COUNT` 读到的值会早 1 周期；`o_irq` 寄存后到时到中断延迟从 1 周期变为 2 周期，改变 01_spec §7 已审核的指标。
  2. 保持组合输出，记录偏离：组合逻辑只有一级地址选择（`o_prdata`）或一个与门（`o_irq`），输入均来自本 IP 的寄存器和 APB 输入，时序风险可控。
- **结论**：选 2。偏离记录在 05_rtl_structure §6。若集成方要求寄存输出，可在 SoC 层加一级寄存，或作为需求变更处理。
- **影响**：05_rtl_structure §6；RTL 注释引用本 DEC。
