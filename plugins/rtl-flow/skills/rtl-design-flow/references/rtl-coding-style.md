# RTL 编码规范 (RTL Coding Style)

> 参考 lowRISC Verilog Coding Style（OpenTitan 使用）。团队可按自身规范覆盖本文件。

## 1. 语言与文件
- 使用可综合 SystemVerilog（IEEE 1800-2017 子集）；如项目要求纯 Verilog-2001，在 `09_decisions.md` 记录 DEC 并同步修改本节。
- 一个文件一个模块，文件名 = 模块名，`.sv` 后缀；package 文件以 `_pkg.sv` 结尾。
- 每个文件头部：

```systemverilog
// -----------------------------------------------------------------------------
// Module : demo_timer
// IP     : demo_timer  (doc: doc/05_rtl_structure.md)
// Brief  : 一句话描述
// -----------------------------------------------------------------------------
```

## 2. 命名
| 对象 | 规则 | 示例 |
|---|---|---|
| 模块、信号、实例 | lower_snake_case | `tx_fifo`, `u_tx_fifo` |
| 端口 | 加方向后缀 `_i/_o/_io`，低有效 `_ni/_no` | `data_i`, `rst_ni` |
| 寄存器 | `_q`（当前值）/ `_d`（下一值） | `state_q`, `state_d` |
| parameter / localparam | UpperCamelCase | `DataWidth` |
| 枚举类型 | lower_snake_case + `_e` | `state_e` |
| 枚举值 | UpperCamelCase | `StIdle` |
| 宏 | UPPER_SNAKE_CASE | `` `ASSERT `` |
| 实例名 | `u_` 前缀 | `u_sync` |
| generate 块 | `gen_` 前缀 | `gen_lane` |

## 3. 时序与组合
- 时序逻辑只用 `always_ff @(posedge clk_i or negedge rst_ni)`，只用非阻塞赋值 `<=`，块内只做 `_q <= _d` 或带使能的简单赋值。
- 组合逻辑只用 `always_comb`，只用阻塞赋值 `=`，块首给所有输出赋默认值，**禁止产生锁存器**。
- 默认复位：异步复位、同步释放、低有效 `rst_ni`；所有控制路径寄存器必须复位，纯数据通路寄存器可不复位（需在 05 中说明）。
- 禁止在同一 always 块中混合时序与组合；禁止 `initial`（testbench 除外）；禁止 `#delay`。

## 4. FSM
- 使用 `typedef enum logic [N-1:0] {...} state_e;`，两段式（`always_ff` 状态寄存器 + `always_comb` 次态/输出）。
- `case` 必须有 `default`，default 跳回安全状态。
- 状态名、转移条件与 `02_architecture.md` 中的状态转移表一一对应。

## 5. 参数化与位宽
- 位宽由参数推导，禁止魔数；用 `$clog2()` 计算地址位宽。
- 赋值两侧位宽一致，必要时显式截断/扩展；常量写明位宽 `'0`、`8'hFF`。

## 6. CDC 与复位
- 单 bit 跨时钟域：两级同步器（使用统一的同步器模块，如 `prim_flop_2sync`）。
- 多 bit：握手、异步 FIFO 或格雷码，禁止直接两级同步多 bit 总线。
- 所有 CDC 路径列在 `02_architecture.md` 的 CDC 表中。

## 7. 断言
- 关键协议与不变式用 SVA，放在 `` `ifndef SYNTHESIS `` 中或独立 bind 文件。
- 至少包含：输出无 X（复位后）、FSM 状态合法、握手协议。

## 8. Lint
- 交付前 `verilator --lint-only -Wall` 或 `verible-verilog-lint` 零 error；保留的 warning 需在 `05_rtl_structure.md` 的「Lint 豁免」表说明原因。
