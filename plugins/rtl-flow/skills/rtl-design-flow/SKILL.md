---
name: rtl-design-flow
description: 数字 IC / RTL IP 设计全流程规范。当用户提供需求描述或规格文档（可能不规范）并要求生成 RTL、编写或更新设计文档（需求、规格、架构、接口、寄存器、RTL 代码结构、编程指南、验证计划）、搭建验证环境、记录验证迭代或修改已有 IP 时使用。产出遵循统一模板、术语与 ID 追溯规则，并用脚本自动生成与检查。
---

# RTL 设计全流程规范 (rtl-flow)

本 skill 定义从「原始需求」到「RTL + 验证 + 标准化文档」的完整流程。目标：**任何人、任何一次 AI 会话产出的文档结构一致、术语一致、可追溯、可自动检查**。

本 skill 目录（下文记为 `$SKILL`）包含：

| 路径 | 用途 |
|---|---|
| `references/doc-standard.md` | 文档体系、front matter、ID 规则、写作规范 —— **开始任何文档工作前必读** |
| `references/glossary.md` | 术语表、信号命名后缀、寄存器访问类型 |
| `references/data-schema.md` | IP 描述文件 `data/<ip>.yaml`（单一信息源）字段定义 |
| `references/rtl-coding-style.md` | RTL 编码规范 —— 写 RTL 前必读 |
| `templates/` | 所有文档模板，新建 IP 时整体复制 |
| `scripts/gen_docs.py` | 由 `data/<ip>.yaml` 生成接口文档、寄存器文档、C 头文件 |
| `scripts/run_lint.py` | 运行 lint 并写 `reports/lint.log` |
| `scripts/check_docs.py` | 文档完整性 / 追溯性 / 审核记录 / RTL 一致性检查 |
| `examples/` | 标杆示例（few-shot），**优先模仿其写法与粒度**；`examples/demo_timer/` 为完整走完 P0–P6 的参考 IP |

## 0. 基本原则

1. **单一信息源 (SSOT)**：参数、端口、时钟复位、中断、寄存器只写在 `data/<ip>.yaml`。`03_interfaces.md`、`04_registers.md`、`sw/<ip>_regs.h` 由脚本生成，**禁止手改**。
2. **先文档后代码**：行为变更顺序永远是 `00_requirements` → `01_spec`/`02_architecture` → `data/<ip>.yaml` → RTL → DV。不允许 RTL 先改、文档事后补。
3. **不猜测，显式记录**：原始输入中模糊、矛盾、缺失的地方，要么问用户（记为 `Q-xxx`），要么做假设（记为 `ASM-xxx`），二者都写进 `00_requirements.md`。
4. **可追溯**：每条 `REQ-xxx` 必须在 `01_spec.md` 中被引用，并在 `07_dv_plan.md` 中有对应测试点 `TP-xxx`。
5. **每步可检查**：每个阶段结束运行 `check_docs.py --stage <阶段>`，ERROR 必须清零才能进入下一阶段。
6. **原始输入只读**：用户给的原始材料原样保存在 `<ip>/raw/`，不修改。
7. **人工审核点**：G0（需求）、G1（规格）、G2（架构）结束时**必须停下来等待用户审核**，通过后才进入下一阶段。审核结果记录在被审文档的 front matter 中，规则见 §3。

## 1. IP 目录结构（参考 OpenTitan `hw/ip/<ip>/`）

```
<ip>/
├── README.md                  # 概述、特性、文档索引、当前状态
├── CHANGELOG.md               # 版本变更记录
├── raw/                       # 原始需求/规格（只读）
├── data/<ip>.yaml             # 单一信息源
├── doc/
│   ├── 00_requirements.md     # 需求规范化：REQ / ASM / Q
│   ├── 01_spec.md             # 功能规格 (Theory of Operation)
│   ├── 02_architecture.md     # 微架构：框图、数据通路、FSM、时钟复位、CDC
│   ├── 03_interfaces.md       # [生成] 参数、端口、时钟复位、中断
│   ├── 04_registers.md        # [生成] 寄存器
│   ├── 05_rtl_structure.md    # RTL 代码架构：文件、层次、模块职责
│   ├── 06_programmers_guide.md# 软件编程指南
│   ├── 07_dv_plan.md          # 验证计划：测试点、覆盖率、追溯矩阵
│   ├── 08_iteration_log.md    # 验证/修改迭代记录
│   ├── 09_decisions.md        # 设计决策记录 (DEC)
│   └── 10_checklist.md        # 阶段签核清单 (D0-D3 / V0-V3)
├── rtl/                       # RTL 源码
├── dv/                        # 测试平台、测试用例、仿真脚本
├── syn/                       # 综合脚本（可选，用于无 latch 检查与 PPA 评估）
├── reports/lint.log           # [生成] run_lint.py 的 lint 报告（含 RTL 摘要，用于判断是否过期）
└── sw/<ip>_regs.h             # [生成] 寄存器 C 头文件
```

## 2. 流程（每个阶段有闸门，未过闸不得进入下一阶段）

### P0 需求接收与规范化 (Intake)
1. 创建 IP 目录：复制 `$SKILL/templates/` 全部内容到 `<ip>/`，文件名中的 `ip` 替换为实际 IP 名，所有 `{{...}}` 占位符按实际填写。
2. 将用户原始材料复制到 `raw/`，在 `00_requirements.md` 的「输入来源」表登记（文件名、版本/日期、摘要）。
3. 逐条抽取需求，改写为**单一、可验证、带量化指标**的 `REQ-xxx`（写法见 doc-standard §4）。每条标注来源（`raw/xxx §y`）和优先级。
4. 列出所有模糊点/矛盾/缺失：能合理推断的写 `ASM-xxx`，关键且不能推断的写 `Q-xxx` 并**向用户提问**（用 AskUserQuestion，一次合并提问）。
5. **闸门 G0（人工审核）**：`check_docs.py --stage req` 无 ERROR 后，`00_requirements.md` 的 status 改为 `Review`，提交用户审核（尤其是 ASM 与 Q）。用户通过后填写 00 的 `reviewer` / `approved`，再进入 P1。

### P1 规格与数据 (Spec)
1. 编写 `data/<ip>.yaml`（参数、时钟复位、端口、中断、寄存器）。
2. 运行 `gen_docs.py` 生成 `03_interfaces.md`、`04_registers.md`、`sw/<ip>_regs.h`。
3. 编写 `01_spec.md`：每个功能小节以 `> 覆盖需求: REQ-xxx, REQ-yyy` 开头。
4. 编写 `06_programmers_guide.md` 初稿（初始化、典型操作、中断处理）。
5. **闸门 G1（人工审核）**：`check_docs.py --stage spec` 无 ERROR（所有 REQ 均被 spec 引用、生成文件最新、00 已审核）后，`01_spec.md` 的 status 改为 `Review`，提交用户审核。审核范围：01（功能行为）、03/04（端口与寄存器，即 yaml 内容）、06 初稿、新增的 ASM。用户通过后填写 01 的 `reviewer` / `approved`，再进入 P2。

### P2 微架构 (Architecture)
1. 编写 `02_architecture.md`：顶层框图（Mermaid）、子模块划分、数据通路、FSM（状态图 + 状态表）、时钟/复位方案、CDC、关键时序（WaveDrom）、面积/时序/功耗估计。
2. 重要取舍记入 `09_decisions.md`（DEC-xxx：背景、选项、结论、影响）。
3. `02_architecture.md` §2 子模块表：第一列写模块名（反引号包裹，与 RTL 的 `module` 名一致），「职责」「关键接口」两列必填。P3 时脚本会检查这些模块都在 RTL 中实现、并在 05 中描述。
4. **闸门 G2（人工审核）**：`check_docs.py --stage arch` 无 ERROR（子模块表完整、01 已审核）后，`02_architecture.md` 的 status 改为 `Review`，提交用户审核。审核范围：02 与本阶段新增的 DEC（09）。用户通过后填写 02 的 `reviewer` / `approved`，再进入 P3。

### P3 RTL 实现
1. 严格按 `references/rtl-coding-style.md` 编写 RTL，顶层端口必须与 `data/<ip>.yaml` 完全一致。
2. 编写 `05_rtl_structure.md`：文件清单、模块层次树、各模块职责、参数传递、编码约定偏离说明。
3. 运行 `run_lint.py <ip_dir>`（默认 Verilator，`--tool verible` 可选），报告写入 `reports/lint.log`；lint 引起的修改记录到 `08_iteration_log.md`。warning 要么修复，要么在 05 §7 写明豁免原因。
4. **闸门 G3**：`check_docs.py --stage rtl` 无 ERROR：顶层端口与 yaml 一致；02 的子模块都在 RTL 中、RTL 的模块都在 05 中；`reports/lint.log` 存在、与当前 RTL 一致（RTL 改动后必须重跑）、无 lint error；02 已审核。G3 不需要停下来等待审核，汇报后直接进入 P4。

### P4 验证 (DV)
1. 编写 `07_dv_plan.md`：测试点 TP-xxx（每个关联 REQ）、激励策略、检查方法、覆盖率目标、追溯矩阵。
2. 搭建 `dv/` 测试平台与用例（优先自检查 testbench：scoreboard/断言，而不是看波形）。
3. 运行仿真（iverilog / verilator / 用户指定仿真器），结果写入 `08_iteration_log.md`。

### P5 迭代 (Iterate) —— 验证或需求变更导致的修改
每一轮修改都**必须**在 `08_iteration_log.md` 新增一条 `ITR-xxx`，包含：触发原因（失败用例/需求变更/评审意见）、现象、根因、修改内容（文件 + 摘要）、影响的文档、回归结果。
- 根因属于**规格错误/需求变化** → 先改 `00`/`01`/`yaml`，再改 RTL，并在 `09_decisions.md` 记录 DEC。
- 根因属于**RTL 实现错误** → 改 RTL；若影响微架构则同步 `02`/`05`。
- 根因属于**验证环境错误** → 改 dv，标注为 `TB bug`。
- **重开审核**：若修改了已审核的 00 / 01 / 02（内容实质变化，按 doc-standard §7 提升 version），对应闸门重新打开：先改完这些文档，合并一次提交用户审核，通过后更新 `approved` 再改 yaml / RTL。仅修改 RTL / DV 或未审核文档时不需要停下。
- 修改后重新运行 `gen_docs.py` + `run_lint.py`（改了 RTL 时）+ `check_docs.py --stage dv` + 回归。
- 对外可见的行为变化写入 `CHANGELOG.md`，并提升对应文档 `version`。

### P6 签核 (Sign-off)
按 `10_checklist.md` 逐项勾选；所有文档 `status` 改为 `Released` 后运行 `check_docs.py --stage signoff`（Released 状态下 TODO/TBD/占位符/Open 的 Q 都会报 ERROR；三个审核点都必须是人工通过，`approved: skipped` 也会报 ERROR）。

## 3. 审核点 (Review Gates)

| 闸门 | 被审文档（记录审核结果） | 一并审核 | 何时检查 `approved` |
|---|---|---|---|
| G0 | `00_requirements` | Q 的答复、ASM | `--stage spec` 起 |
| G1 | `01_spec` | 03 / 04（yaml）、06 初稿、新增 ASM | `--stage arch` 起 |
| G2 | `02_architecture` | 本阶段新增的 DEC | `--stage rtl` 起 |

1. **提交审核**：闸门的 `check_docs.py` 无 ERROR 后，把被审文档 status 改为 `Review`，向用户汇报：文档路径、要点（3–8 条）、新增的 ASM / DEC、需要用户特别判断的地方。然后用 AskUserQuestion 请用户选择「通过」或「需要修改」（修改意见可在 Other 中填写）。**在用户答复前不得开始下一阶段的任何工作。**
2. **需要修改**：按意见修改（落到 REQ / ASM / DEC，不只改正文），重新运行检查后再次提交，直到通过。
3. **通过**：在被审文档 front matter 填写：
   ```yaml
   reviewer: 张三             # 审核人；不知道姓名时在 G0 提问中一并询问
   approved: 0.2@2026-10-22   # <通过时的 version>@<日期>
   ```
   **只有用户明确表示通过时才能填写，AI 不得自行填写或推断。**
4. **版本绑定**：`approved` 中的版本必须等于当前 `version`。审核后内容实质变化须提升 version，检查脚本随即报「re-review required」，即闸门重开（见 P5）。
5. **自动模式**：用户明确要求不停顿（如 `/ip-new --auto`、或说「不用等我审核」）时，闸门不停下，填写 `approved: skipped`、`reviewer` 留空，并在汇报中注明「未经人工审核」。skipped 在签核前会报 WARN，在 `--stage signoff` 报 ERROR，交付前必须补审。

## 4. 命令

```bash
python $SKILL/scripts/gen_docs.py   <ip_dir>                  # 由 yaml 生成 03/04 与 C 头文件
python $SKILL/scripts/run_lint.py   <ip_dir>                  # lint，写 reports/lint.log（--tool verible 可选）
python $SKILL/scripts/check_docs.py <ip_dir> --stage req      # G0：文件、front matter、必填章节、ID
python $SKILL/scripts/check_docs.py <ip_dir> --stage spec     # G1：+ REQ 被 spec 覆盖、生成文件最新、00 已审核
python $SKILL/scripts/check_docs.py <ip_dir> --stage arch     # G2：+ 02 子模块表完整、01 已审核
python $SKILL/scripts/check_docs.py <ip_dir> --stage rtl      # G3：+ 端口一致、子模块在 RTL/05 中、lint 报告有效、02 已审核
python $SKILL/scripts/check_docs.py <ip_dir> --stage dv       # P4/P5：+ 每条 REQ 都有 TP
python $SKILL/scripts/check_docs.py <ip_dir> --stage signoff  # P6：+ 无占位符/TODO/Open Q，全部 Released，审核均为人工通过
```
阶段是累积的；当前阶段以下的检查失败为 ERROR，以上的仅为 WARN（提示后续要补）。
依赖：Python 3.8+、PyYAML（`.hjson` 数据文件需额外 `pip install hjson`）；lint 需要 Verilator 或 Verible。

## 5. 与用户沟通
- 每个闸门结束时简要汇报：产出了哪些文档、新增的 ASM/Q、检查结果。
- 不要把文档全文贴进对话；指向文件路径即可。
- 用户的口头修改意见同样要落到文档（REQ/ASM/DEC/ITR），不能只改代码。
