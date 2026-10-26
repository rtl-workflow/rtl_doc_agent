---
doc: README
ip: demo_timer
version: 1.3
status: Released
updated: 2026-10-24
owner: rtl-flow-example
---

# demo_timer

> 这是 rtl-flow 插件的**标杆示例**：从一句话的不规范需求（`raw/timer需求.txt`）出发，完整走完 P0–P6，包含一次需求变更迭代。所有仿真、lint、综合结果均为真实运行结果。

## 概述 (Overview)

`demo_timer` 是一个挂在 APB3 总线上的 32 bit 可编程定时器。计数值达到比较值时产生到时事件，置位中断状态并输出电平中断 `o_irq`。支持单次和周期两种模式，以及软件清零计数。

## 特性 (Features)

- APB3 从接口：12 bit 地址、32 bit 数据，零等待，非法 / 非对齐地址返回 `pslverr`
- 32 bit 递增计数器，比较值可编程，定时范围 1 ~ 2^32 个周期（100 MHz 下最长约 42.95 s）
- 单次模式（到时自动停止）/ 周期模式（到时自动重装）
- 电平中断，可屏蔽，写 1 清除
- `CTRL.CLR` 软件清零计数（v1.1 新增）
- 单时钟域，68 个触发器，约 500 个二输入门

## 文档索引 (Documents)

| 文档 | 说明 |
|---|---|
| [需求规范](doc/00_requirements.md) | 11 条 REQ、4 条 ASM、3 条已关闭的 Q、原始材料问题记录 |
| [功能规格](doc/01_spec.md) | 功能行为描述 |
| [微架构](doc/02_architecture.md) | 框图、次态优先级表、时钟复位、综合实测 PPA |
| [接口](doc/03_interfaces.md) | 端口、时钟复位、中断（自动生成） |
| [寄存器](doc/04_registers.md) | 5 个寄存器（自动生成） |
| [RTL 代码架构](doc/05_rtl_structure.md) | 3 个模块的职责与信号 |
| [编程指南](doc/06_programmers_guide.md) | C 示例代码 |
| [验证计划](doc/07_dv_plan.md) | 11 个测试点、8 个断言、13 个覆盖点、追溯矩阵 |
| [迭代记录](doc/08_iteration_log.md) | ITR-001 ~ ITR-008 |
| [设计决策](doc/09_decisions.md) | DEC-001 ~ DEC-007 |
| [签核清单](doc/10_checklist.md) | D0–D3 / V0–V3 |
| [变更记录](CHANGELOG.md) | 1.0.0、1.1.0、2.0.0 |

## 当前状态 (Status)

| 项 | 状态 |
|---|---|
| 设计阶段 | D3 |
| 验证阶段 | V3 |
| 最近一次迭代 | ITR-008 编码规范改为华为 Verilog 规范 |
| 人工审核 | 00 / 01 / 02 已审核（v1.2，2026-10-24） |

## 目录与命令

```text
raw/            原始需求（只读）
data/           单一信息源 demo_timer.yaml
doc/            00–10 文档
rtl/            demo_timer.v / demo_timer_reg.v / demo_timer_core.v（Verilog-2001，华为编码规范）
dv/tb/          黑盒自检查 testbench（只通过顶层端口访问 DUT）
dv/run_sim.py   回归；dv/run_mutation.py 变异测试
syn/synth.ys    Yosys 综合（无 latch 检查、逻辑深度）
reports/        lint.log（run_lint.py 生成）
sw/             自动生成的寄存器 C 头文件
```

```bash
python dv/run_sim.py                  # 回归（需 iverilog / vvp 在 PATH 中）
python dv/run_mutation.py             # testbench 有效性
yowasp-yosys -s syn/synth.ys          # 综合评估
python <skill>/scripts/run_lint.py .   # lint，结果写 reports/lint.log
```
