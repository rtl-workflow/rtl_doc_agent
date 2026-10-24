# 文档规范 (Documentation Standard)

## 1. 文档体系

| 文件 | 名称 | 生成方式 | 主要读者 | 何时更新 |
|---|---|---|---|---|
| `README.md` | IP 概述 | 手写 | 所有人 | 状态/特性变化 |
| `CHANGELOG.md` | 变更记录 | 手写 | 所有人 | 每次对外可见变化 |
| `doc/00_requirements.md` | 需求规范 | 手写 | 架构、DV | 需求变化 |
| `doc/01_spec.md` | 功能规格 | 手写 | 设计、DV、软件 | 功能变化 |
| `doc/02_architecture.md` | 微架构 | 手写 | 设计、后端 | 结构变化 |
| `doc/03_interfaces.md` | 接口 | **生成** | 集成、DV | 改 yaml 后重新生成 |
| `doc/04_registers.md` | 寄存器 | **生成** | 软件、DV | 改 yaml 后重新生成 |
| `doc/05_rtl_structure.md` | RTL 代码架构 | 手写 | 设计、维护者 | 文件/层次变化 |
| `doc/06_programmers_guide.md` | 编程指南 | 手写 | 软件 | 寄存器/流程变化 |
| `doc/07_dv_plan.md` | 验证计划 | 手写 | DV | 需求/测试变化 |
| `doc/08_iteration_log.md` | 迭代记录 | 手写（追加） | 所有人 | 每轮修改 |
| `doc/09_decisions.md` | 设计决策 | 手写（追加） | 架构、评审 | 每个重要取舍 |
| `doc/10_checklist.md` | 签核清单 | 手写 | 项目管理 | 阶段推进 |

所有手写文档以 `templates/` 下的同名模板为起点。**模板中的二级标题（`## `）全部是必填章节**，不得删除或改名；不适用的章节保留标题并写「不适用：<原因>」。可以新增三级及以下标题。

## 2. Front matter

每个文档（含生成文档）开头必须有：

```yaml
---
doc: 01_spec            # 与文件名一致（不含 .md）
ip: uart_lite           # IP 名，与 data/<ip>.yaml 的 name 一致
version: 0.1            # 文档版本，主.次；内容实质变化时提升
status: Draft           # Draft | Review | Released
updated: 2026-10-22     # 最后修改日期 YYYY-MM-DD
owner: zhangsan         # 负责人
---
```

`00_requirements`、`01_spec`、`02_architecture` 是人工审核点（G0 / G1 / G2）的被审文档，另有两个字段：

```yaml
reviewer: lisi          # 审核人
approved: 0.2@2026-10-22  # 审核通过时的 version@日期；自动模式写 skipped
```

- 只有用户明确通过后才能填写，AI 不得自行填写。
- `approved` 中的版本必须等于当前 `version`；审核后实质修改须提升 version 并重新审核。
- status 含义：`Draft` 编写中 → `Review` 已提交审核或已审核通过 → `Released` 签核发布。

## 3. ID 规则

| 前缀 | 含义 | 定义位置 | 格式示例 |
|---|---|---|---|
| `REQ` | 需求 | 00_requirements | `REQ-001` 或带域 `REQ-REG-001` |
| `ASM` | 假设 | 00_requirements | `ASM-001` |
| `Q` | 待确认问题 | 00_requirements | `Q-001` |
| `DEC` | 设计决策 | 09_decisions | `DEC-001` |
| `TP` | 测试点 | 07_dv_plan | `TP-001` |
| `ITR` | 迭代 | 08_iteration_log | `ITR-001` |
| `BUG` | 缺陷 | 08_iteration_log | `BUG-001` |

- 编号三位数字，从 001 递增，**永不复用**；作废的条目保留并标注 `~~删除~~ (见 ITR-xxx)`。
- ID 定义处必须是表格某行的第一列；引用处直接写 ID 文本即可（脚本按文本匹配）。
- 推荐需求域：`FUNC` 功能、`IF` 接口、`REG` 寄存器、`PERF` 性能、`CLK` 时钟复位、`PWR` 功耗、`DFT` 可测性、`SEC` 安全。

## 4. 需求写法

每条 REQ 必须满足：
- **单一**：一条只说一件事，不出现「并且/以及」连接两个要求。
- **可验证**：能写出通过/不通过的判定；含数量的要写数值和单位。
- **用规范情态词**：`必须`（强制）/ `应`（推荐，偏离需写 DEC）/ `可`（可选）。
- **有来源**：`raw/<file> §<章节>`、`用户口头 YYYY-MM-DD` 或 `派生自 REQ-xxx`。

❌ `模块要支持高速传输并且低功耗。`
✅ `REQ-PERF-001 | 在 clk=200 MHz 下，持续吞吐率必须 ≥ 1 个 32 bit 数据/周期。| raw/spec_v0.docx §3.2 | P0`

## 5. 写作规范

- 语言：正文中文；信号名、寄存器名、参数名、协议名保留英文原样。
- 代码元素用反引号：`clk`、`CTRL.EN`、`DATA_WIDTH`。寄存器字段统一写作 `REG.FIELD`。
- 数值：十六进制 `0x1F` 或 Verilog 形式 `8'h1F`，二进制 `4'b1010`；位范围 `[7:0]`，高位在前。
- 单位：数字与单位之间空格，`100 MHz`、`32 bit`、`4 KiB`、`10 ns`、`2 cycles`。
- 时钟周期统一称「周期 (cycle)」，并注明所属时钟域。
- 有效电平：低有效信号以 `_n` 结尾，文中说「拉低有效」，不要说「置 0 有效」。
- 未定内容只允许写 `TBD(Q-xxx)`，必须关联一个 Q；Released 状态下不得出现。
- 术语以 `glossary.md` 为准，同义词不得混用（如统一用「复位」，不用「重置」）。

## 6. 图表

- 框图、FSM、层次：**Mermaid**（```mermaid 代码块），保证可 diff、可评审。
- 时序：**WaveDrom** JSON（```wavedrom 代码块）。
- FSM 必须同时给出状态图和状态转移表（当前状态 / 条件 / 下一状态 / 输出）。
- 表格优先于大段文字：端口、寄存器、状态、测试点一律用表格。

## 7. 变更控制

1. 改行为：按 `00 → 01/02 → yaml → RTL → DV` 顺序修改。
2. 每次修改在 `08_iteration_log.md` 记 ITR；重要取舍在 `09_decisions.md` 记 DEC。
3. 文档内容实质变化：提升 front matter `version`，更新 `updated`。已审核的 00 / 01 / 02 提升 version 后须重新审核。
4. 对外可见变化（端口、寄存器、行为、时序）写入 `CHANGELOG.md`。
5. 修改 yaml 后必须重新运行 `gen_docs.py`，否则 `check_docs.py` 会报生成文件过期。
