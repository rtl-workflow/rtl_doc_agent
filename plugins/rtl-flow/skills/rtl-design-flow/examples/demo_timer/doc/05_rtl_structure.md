---
doc: 05_rtl_structure
ip: demo_timer
version: 1.1
status: Released
updated: 2026-10-22
owner: rtl-flow-example
---

# demo_timer RTL 代码架构

## 1. 文件清单 (File List)

| 文件 | 模块 | 说明 |
|---|---|---|
| `rtl/demo_timer.sv` | `demo_timer` | 顶层，连接子模块并生成 `irq_o` |
| `rtl/demo_timer_reg_top.sv` | `demo_timer_reg_top` | APB3 从接口与寄存器块 |
| `rtl/demo_timer_core.sv` | `demo_timer_core` | 计数器与到时比较 |

## 2. 模块层次 (Hierarchy)

```text
demo_timer
├── u_reg_top   (demo_timer_reg_top)
└── u_core      (demo_timer_core)
```

## 3. 模块职责与接口 (Module Responsibilities)

### 3.1 demo_timer

- 职责：纯连接；`irq_o = intr_state & intr_enable`（REQ-FUNC-005）。
- 对应架构：02_architecture §1、§2。
- 关键信号：`ctrl_en`（使能）、`ctrl_clr`（清零脉冲）、`cmp_val`（比较值）、`count_val`（计数值）、`expire`（到时脉冲）。

### 3.2 demo_timer_reg_top

- 职责：APB 访问判定（`access = psel & penable`）、地址译码、5 个寄存器的存储与次态、读数据选择、`pslverr` 生成。
- 对应架构：02_architecture §2、§4（次态优先级表）。
- 关键信号：

| 信号 | 含义 |
|---|---|
| `hit_*` | 地址命中对应寄存器偏移（全 12 bit 比较，非对齐地址自然不命中） |
| `wr_en` | 有效写：`access & pwrite & addr_hit` |
| `ctrl_en_q` / `ctrl_mode_q` | `CTRL.EN` / `CTRL.MODE` |
| `ctrl_clr_o` | `CTRL.CLR` 写 1 产生的单周期清零脉冲（组合输出，不存储） |
| `cmp_q` | `CMP.VAL` |
| `intr_state_q` / `intr_enable_q` | `INTR_STATE.EXPIRED` / `INTR_ENABLE.EXPIRED` |

- 寄存器偏移以 `localparam` 定义（`CtrlOffset` 等），数值必须与 `data/demo_timer.yaml` 一致；修改 yaml 时需同步修改。

### 3.3 demo_timer_core

- 职责：`count_q` 计数与清零（`clr_i` 优先级最高，REQ-FUNC-006）、`expire_o = en_i && (count_q >= cmp_i)`（DEC-001）。
- 对应架构：02_architecture §3、§4。
- 关键信号：`count_q`（即 `COUNT.VAL`）、`expire_o`（组合输出单周期脉冲，供 `reg_top` 置位中断与清零 EN）。

## 4. 参数传递 (Parameters)

| 参数 | 定义位置 | 传递到 | 说明 |
|---|---|---|---|
| `CtrlOffset` ~ `IntrEnableOffset` | `demo_timer_reg_top` localparam | 本模块 | 寄存器偏移 |
| `ModeOneshot` | `demo_timer_reg_top` localparam | 本模块 | `CTRL.MODE` 单次模式编码 |

本 IP 无对外参数（`data/demo_timer.yaml` 中 `params` 为空）。

## 5. 编译与文件顺序 (Compile Order)

```text
rtl/demo_timer_core.sv
rtl/demo_timer_reg_top.sv
rtl/demo_timer.sv
```

无 package、无 include，文件顺序不敏感。

## 6. 编码约定与偏离 (Conventions & Deviations)

遵循 `rtl-coding-style.md`。偏离项：

| 位置 | 偏离内容 | 原因 | DEC |
|---|---|---|---|
| 全部 RTL | 未在 RTL 中编写 SVA，断言以 testbench 监视器实现 | 示例环境仿真器 iverilog 不支持并发断言 | DEC-004 |

## 7. Lint 豁免 (Lint Waivers)

| 工具 | 规则 | 位置 | 原因 |
|---|---|---|---|
| — | — | — | 无豁免：`verilator --lint-only -Wall` 零 warning（见 ITR-001） |

附注：iverilog 13 编译时会对 `always_comb` 中的常量位选择和 `unique case` 给出 `sorry` 提示，属于仿真器能力限制，不影响功能，也不是 lint 问题。
