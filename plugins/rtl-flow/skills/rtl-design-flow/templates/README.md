---
doc: README
ip: {{ip}}
version: 0.1
status: Draft
updated: {{date}}
owner: {{owner}}
---

# {{ip}}

## 概述 (Overview)

{{一段话：这个 IP 做什么、用在什么系统里、对外提供什么能力。}}

## 特性 (Features)

- {{特性 1，含关键指标，如「支持 8/16/32 bit 数据宽度」}}

## 文档索引 (Documents)

| 文档 | 说明 |
|---|---|
| [需求规范](doc/00_requirements.md) | 规范化需求、假设、待确认问题 |
| [功能规格](doc/01_spec.md) | 功能行为描述 |
| [微架构](doc/02_architecture.md) | 框图、数据通路、FSM、时钟复位 |
| [接口](doc/03_interfaces.md) | 参数、端口、中断（自动生成） |
| [寄存器](doc/04_registers.md) | 寄存器映射（自动生成） |
| [RTL 代码架构](doc/05_rtl_structure.md) | 文件、层次、模块职责 |
| [编程指南](doc/06_programmers_guide.md) | 软件使用流程 |
| [验证计划](doc/07_dv_plan.md) | 测试点、覆盖率、追溯 |
| [迭代记录](doc/08_iteration_log.md) | 验证与修改迭代 |
| [设计决策](doc/09_decisions.md) | 重要设计取舍 |
| [签核清单](doc/10_checklist.md) | 阶段签核 |
| [变更记录](CHANGELOG.md) | 版本变化 |

## 当前状态 (Status)

| 项 | 状态 |
|---|---|
| 设计阶段 | D0 |
| 验证阶段 | V0 |
| 最近一次迭代 | — |
