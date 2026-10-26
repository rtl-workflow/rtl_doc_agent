---
doc: CHANGELOG
ip: demo_timer
version: 1.3
status: Released
updated: 2026-10-26
owner: rtl-flow-example
---

# 变更记录

格式参考 [Keep a Changelog](https://keepachangelog.com/)。只记录对外可见的变化（端口、寄存器、行为、时序、参数）。

## [Unreleased]

无。

## [3.0.0] - 2026-10-26

### Changed
- **不兼容**：复位端口 `rst_n` 改名为 `rst`（DEC-008）。复位名不再表示极性，本 IP 仍为低有效异步复位，集成方需按新端口名重新连接。
- 新增 `rtl/define.v`（复位极性宏 `RST_EDGE` / `RST_ACT`、仿真延时宏 `U_DLY`），必须放在编译列表最前。寄存器、行为与时序不变；仿真中寄存器输出在时钟沿后 1 ns 变化。

## [2.0.0] - 2026-10-23

### Changed
- **不兼容**：顶层端口按华为 Verilog 编码规范改名（DEC-006）：`clk_i` → `clk`、`rst_ni` → `rst_n`、`psel_i` → `i_psel`、`penable_i` → `i_penable`、`pwrite_i` → `i_pwrite`、`paddr_i` → `i_paddr`、`pwdata_i` → `i_pwdata`、`prdata_o` → `o_prdata`、`pready_o` → `o_pready`、`pslverr_o` → `o_pslverr`、`irq_o` → `o_irq`。集成方需按新端口名重新连接。
- RTL 改为 Verilog-2001（`.v`），子模块 `demo_timer_reg_top` 改名为 `demo_timer_reg`。寄存器、行为与时序不变。

## [1.1.0] - 2026-10-22

### Added
- `CTRL.CLR`（bit 2，只写，读为 0）：写 1 使计数值在下一周期归零（REQ-FUNC-006，DEC-005，ITR-005）。

### Changed
- 写 `CTRL` 时 bit 2 不再被忽略。旧软件写 `CTRL` 时 bit 2 为 0，行为不变。

## [1.0.0] - 2026-10-22

### Added
- 初始版本：APB3 从接口、32 bit 计数器、单次 / 周期模式、电平中断；寄存器 `CTRL`、`CMP`、`COUNT`、`INTR_STATE`、`INTR_ENABLE`。
