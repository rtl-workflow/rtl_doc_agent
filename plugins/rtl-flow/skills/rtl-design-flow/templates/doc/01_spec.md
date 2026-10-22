---
doc: 01_spec
ip: {{ip}}
version: 0.1
status: Draft
updated: {{date}}
owner: {{owner}}
reviewer:                # 审核人，用户审核通过后填写
approved:                # <version>@YYYY-MM-DD，用户明确通过后才填写；自动模式填 skipped
---

# {{ip}} 功能规格

## 1. 概述 (Overview)

{{IP 的功能定位、在系统中的位置（可附系统连接图）。}}

## 2. 特性列表 (Features)

| 特性 | 说明 | 覆盖需求 |
|---|---|---|
| {{特性}} | {{说明}} | REQ-FUNC-001 |

## 3. 工作原理 (Theory of Operation)

> 每个小节以「覆盖需求」开头。描述外部可观察的行为，不描述实现细节（实现细节写在 02）。

### 3.1 {{功能点}}

> 覆盖需求: REQ-FUNC-001

{{行为描述。必要时附 WaveDrom 时序图。}}

## 4. 工作模式与状态 (Modes)

{{IP 对外可见的工作模式、模式切换条件。无则写「不适用：<原因>」。}}

## 5. 时钟与复位行为 (Clock & Reset Behavior)

{{各时钟域作用；复位后各输出和寄存器的状态；复位期间的行为。}}

## 6. 中断与错误处理 (Interrupts & Errors)

{{中断产生/清除条件；非法操作（非法地址、非法配置）时的行为。}}

## 7. 性能指标 (Performance)

| 指标 | 数值 | 条件 | 覆盖需求 |
|---|---|---|---|
| 吞吐率 | {{x}} | {{条件}} | REQ-PERF-001 |
| 延迟 | {{x}} cycles | {{条件}} | |

## 8. 接口与寄存器引用 (Interfaces & Registers)

端口与参数详见 [03_interfaces.md](03_interfaces.md)，寄存器详见 [04_registers.md](04_registers.md)。此处只说明协议层面的约定（如总线错误响应、访问宽度限制）。

## 9. 限制与已知问题 (Limitations)

{{设计限制、不支持的场景。}}
