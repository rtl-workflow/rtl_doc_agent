---
doc: 05_rtl_structure
ip: demo_timer
version: 1.2
status: Released
updated: 2026-10-23
owner: rtl-flow-example
---

# demo_timer RTL 代码架构

## 1. 文件清单 (File List)

| 文件 | 模块 | 说明 |
|---|---|---|
| `rtl/demo_timer.v` | `demo_timer` | 顶层，连接子模块并生成 `o_irq` |
| `rtl/demo_timer_reg.v` | `demo_timer_reg` | APB3 从接口与寄存器块 |
| `rtl/demo_timer_core.v` | `demo_timer_core` | 计数器与到时比较 |

## 2. 模块层次 (Hierarchy)

```text
demo_timer
├── U_reg    (demo_timer_reg)
└── U_core   (demo_timer_core)
```

## 3. 模块职责与接口 (Module Responsibilities)

### 3.1 demo_timer

- 职责：纯连接；`o_irq = intr_state & intr_enable`（REQ-FUNC-005）。
- 对应架构：02_architecture §1、§2。
- 关键信号：`ctrl_en`（使能）、`ctrl_clr`（清零脉冲）、`cmp_val`（比较值）、`count_val`（计数值）、`expire`（到时脉冲）。

### 3.2 demo_timer_reg

- 职责：APB 访问判定（`access = psel & penable`）、地址译码、5 个寄存器的存储与次态、读数据选择、`pslverr` 生成。
- 对应架构：02_architecture §2、§4（次态优先级表）。
- 关键信号：

| 信号 | 含义 |
|---|---|
| `hit_*` | 地址命中对应寄存器偏移（全 12 bit 比较，非对齐地址自然不命中） |
| `wr_en` | 有效写：`access & pwrite & addr_hit` |
| `ctrl_en_r` / `ctrl_mode_r` | `CTRL.EN` / `CTRL.MODE` |
| `o_ctrl_clr` | `CTRL.CLR` 写 1 产生的单周期清零脉冲（组合输出，不存储） |
| `cmp_r` | `CMP.VAL` |
| `intr_state_r` / `intr_enable_r` | `INTR_STATE.EXPIRED` / `INTR_ENABLE.EXPIRED` |

- 寄存器偏移以 `localparam` 定义（`ADDR_CTRL` 等），数值必须与 `data/demo_timer.yaml` 一致；修改 yaml 时需同步修改。

### 3.3 demo_timer_core

- 职责：`count_r` 计数与清零（`i_clr` 优先级最高，REQ-FUNC-006）、`o_expire = i_en && (count_r >= i_cmp)`（DEC-001）。
- 对应架构：02_architecture §3、§4。
- 关键信号：`count_r`（即 `COUNT.VAL`）、`o_expire`（组合输出单周期脉冲，供 `demo_timer_reg` 置位中断与清零 EN）。

## 4. 参数传递 (Parameters)

| 参数 | 定义位置 | 传递到 | 说明 |
|---|---|---|---|
| `ADDR_CTRL` ~ `ADDR_INTR_ENABLE` | `demo_timer_reg` localparam | 本模块 | 寄存器偏移 |
| `MODE_ONESHOT` | `demo_timer_reg` localparam | 本模块 | `CTRL.MODE` 单次模式编码 |

本 IP 无对外参数（`data/demo_timer.yaml` 中 `params` 为空）。

## 5. 编译与文件顺序 (Compile Order)

```text
rtl/demo_timer_core.v
rtl/demo_timer_reg.v
rtl/demo_timer.v
```

无 package、无 include，文件顺序不敏感。

## 6. 编码约定与偏离 (Conventions & Deviations)

遵循 `rtl-coding-style.md`（华为 Verilog 编码规范，Verilog-2001）。`run_lint.py` 风格检查 0 违规。偏离项：

| 位置 | 规则 | 偏离内容 | 原因 | DEC |
|---|---|---|---|---|
| `demo_timer.o_irq`；`demo_timer_reg.o_prdata`、`o_pslverr`、`o_pready` | HW-33 | 顶层输出未经寄存器，`o_prdata` / `o_pslverr` / `o_irq` 为寄存器值的组合逻辑，`o_pready` 为常量 | APB 零等待要求读数据与错误响应在访问周期内组合给出（REQ-IF-001）；`o_irq` 加寄存器会多 1 周期延迟，改变 01_spec §7 已审核的时序 | DEC-007 |

断言：规范 §10 规定 RTL 中不写 SVA，协议与不变式检查在 testbench 监视器中实现（DEC-004），不属于偏离。

## 7. Lint 豁免 (Lint Waivers)

| 工具 | 规则 | 位置 | 原因 |
|---|---|---|---|
| — | — | — | 无豁免：`verilator --lint-only -Wall --default-language 1364-2001` 零 warning（见 ITR-001、ITR-008） |

附注：RTL 与 testbench 均以 `iverilog -g2001` 编译，无任何编译告警。
