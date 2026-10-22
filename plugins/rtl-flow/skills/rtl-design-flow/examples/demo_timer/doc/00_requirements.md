---
doc: 00_requirements
ip: demo_timer
version: 1.1
status: Released
updated: 2026-10-22
owner: rtl-flow-example
reviewer: 示例用户
approved: 1.1@2026-10-22
---

# demo_timer 需求规范

## 1. 输入来源 (Sources)

> 原始材料原样保存在 `raw/`，此处登记。

| 编号 | 文件 / 来源 | 版本或日期 | 摘要 |
|---|---|---|---|
| SRC-1 | `raw/timer需求.txt` | 2026-10-22 | 一句话需求：APB 定时器，100 MHz，32 bit 计数，单次/周期模式，到时中断，三类寄存器 |
| SRC-2 | 用户答复（P0 提问） | 2026-10-22 | 对 Q-001 ~ Q-003 的答复及 ASM-001 ~ ASM-004 的确认 |
| SRC-3 | 需求变更 CR-1（示例场景） | 2026-10-22 | 软件需要能随时将计数值清零，无需等待到时或复位 |

## 2. 范围 (Scope)

**范围内：**
- 单个 32 bit 递增计数定时器，支持单次 (one-shot) 与周期 (periodic) 两种模式。
- APB3 从接口及其寄存器块。
- 一个电平型中断输出。

**范围外：**
- 预分频器 (prescaler)、多通道、捕获/PWM 功能。
- 跨时钟域：本 IP 为单时钟域设计。
- 中断控制器：`irq_o` 直接输出，由系统中断控制器汇总。

## 3. 需求列表 (Requirements)

| ID | 需求描述 | 来源 | 优先级 | 验证方法 |
|---|---|---|---|---|
| REQ-IF-001 | 必须提供 APB3 从接口：地址 12 bit、数据 32 bit，`pready_o` 恒为高（零等待）。 | SRC-1「挂APB」、SRC-2 Q-003 | P0 | 仿真 |
| REQ-IF-002 | 访问未映射或非 4 字节对齐的地址时，访问阶段必须拉高 `pslverr_o`；读返回 0，写不改变任何寄存器。 | SRC-2 Q-003 | P0 | 仿真 |
| REQ-PERF-001 | 设计必须为单时钟域同步设计，在 `clk_i` = 100 MHz 下满足时序。 | SRC-1「100M」 | P0 | 后端 STA |
| REQ-FUNC-001 | 计数器位宽必须为 32 bit；`CTRL.EN` = 1 时每个 `clk_i` 周期加 1，`CTRL.EN` = 0 时保持不变。 | SRC-1「计数器32位」、ASM-001 | P0 | 仿真 |
| REQ-FUNC-002 | `CTRL.EN` = 1 且计数值 ≥ `CMP.VAL` 时，必须产生一次到时事件：置位 `INTR_STATE.EXPIRED`，计数值在下一周期归零。 | SRC-1「计数到了给个中断」、ASM-002 | P0 | 仿真 |
| REQ-FUNC-003 | 单次模式（`CTRL.MODE` = 0）下，到时事件发生时硬件必须清零 `CTRL.EN`，计数停止。 | SRC-1「单次」、SRC-2 Q-002 | P0 | 仿真 |
| REQ-FUNC-004 | 周期模式（`CTRL.MODE` = 1）下，到时后必须自动继续计数，到时周期为 `CMP.VAL` + 1 个 `clk_i` 周期。 | SRC-1「周期」、ASM-002 | P0 | 仿真 |
| REQ-FUNC-005 | `irq_o` 必须为电平型中断，`irq_o` = `INTR_STATE.EXPIRED` & `INTR_ENABLE.EXPIRED`；软件对 `INTR_STATE.EXPIRED` 写 1 清除。 | SRC-2 Q-001、ASM-003 | P0 | 仿真 |
| REQ-FUNC-006 | 软件对 `CTRL.CLR` 写 1 时，计数值必须在下一周期归零；该操作不改变 `INTR_STATE`，`CTRL.CLR` 读为 0。 | SRC-3 | P1 | 仿真 |
| REQ-REG-001 | 复位后所有寄存器必须为复位值，`CTRL.EN` = 0，计数器停止在 0，`irq_o` 为低。 | SRC-1「复位后不要乱跑」 | P0 | 仿真 |
| REQ-REG-002 | 必须提供寄存器 `CTRL`、`CMP`、`COUNT`（只读）、`INTR_STATE`、`INTR_ENABLE`，地址映射见 04_registers。 | SRC-1「控制、比较值、中断状态」、ASM-003 | P0 | 仿真 |

## 4. 假设 (Assumptions)

> 原始材料未说明、由设计方合理推断的内容。用户确认后保留，否决则改为 REQ 或删除。

| ID | 假设内容 | 理由 | 用户确认 |
|---|---|---|---|
| ASM-001 | 计数器从 0 开始递增计数（而不是从比较值递减）。 | 原文「计数到了」暗示向上计数 | 已确认 |
| ASM-002 | 计数值达到比较值的当拍产生事件，下一拍归零，因此一个周期为 `CMP.VAL` + 1 拍。 | 常见定时器语义，且 `CMP.VAL` = 0 时仍有确定行为 | 已确认 |
| ASM-003 | 在原文三类寄存器之外增加 `INTR_ENABLE`（中断屏蔽）和 `COUNT`（计数值只读，便于调试）。 | 中断需可屏蔽；软件需要能读当前计数 | 已确认 |
| ASM-004 | 复位为异步复位、同步释放、低有效 (`rst_ni`)，复位同步器位于 IP 外部。 | 团队默认复位方案（rtl-coding-style §3） | 已确认 |

## 5. 待确认问题 (Open Questions)

| ID | 问题 | 影响范围 | 状态 | 结论 |
|---|---|---|---|---|
| Q-001 | 中断是电平型还是单周期脉冲？如何清除？ | REQ-FUNC-005、`INTR_STATE` | Closed | 电平型，软件写 1 清除 (rw1c) |
| Q-002 | 单次模式到时后，硬件是否自动清零 `CTRL.EN`？ | REQ-FUNC-003 | Closed | 是，自动清零 |
| Q-003 | APB 版本？是否需要 `pready`/`pslverr`？ | REQ-IF-001、REQ-IF-002 | Closed | APB3；零等待；非法地址返回 `pslverr` |

## 6. 原始材料问题记录 (Source Issues)

> 原始材料中的矛盾、错误、不规范之处，以及本文件如何处理。

| 位置 | 问题 | 处理方式 |
|---|---|---|
| SRC-1「100M」 | 单位不明确 | 按 100 MHz 理解，写入 REQ-PERF-001 |
| SRC-1「计数器32位吧」 | 语气不确定 | 按 32 bit 固定位宽实现，写入 REQ-FUNC-001 |
| SRC-1「复位后不要乱跑」 | 非量化描述 | 改写为可验证的 REQ-REG-001 |
| SRC-1 | 未说明中断类型、单次模式结束行为、APB 版本 | 提问 Q-001 ~ Q-003 |
| SRC-1 | 寄存器只列类别，无地址和位定义 | 由设计方定义于 `data/demo_timer.yaml`，见 ASM-003 |
