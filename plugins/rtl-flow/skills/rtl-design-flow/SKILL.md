---
name: rtl-design-flow
description: 数字 IC / RTL IP 设计全流程规范（多 agent）。当用户提供需求描述或规格文档（可能不规范）并要求生成 RTL、编写或更新设计文档（需求、规格、架构、接口、寄存器、RTL 代码结构、编程指南、验证计划）、搭建验证环境、记录验证迭代或修改已有 IP 时使用。主会话担任编排者，由 flow.py 状态机决定每一步，5 个角色 agent 分工完成，脚本与 hook 负责检查和权限。
---

# RTL 设计全流程规范 (rtl-flow，多 agent 版)

本 skill 定义从「原始需求」到「RTL + 验证 + 标准化文档」的完整流程。目标：**任何人、任何一次 AI 会话产出的文档结构一致、术语一致、可追溯、可自动检查**，并且**设计与验证相互独立**。

本 skill 目录（下文记为 `$SKILL`）包含：

| 路径 | 用途 |
|---|---|
| `scripts/flow.py` | **编排状态机**：决定下一步做什么、调用检查脚本判定能否进入下一阶段、记录审核结果 |
| `references/doc-standard.md` | 文档体系、front matter、ID 规则、写作规范 |
| `references/glossary.md` | 术语表、信号命名后缀、寄存器访问类型 |
| `references/data-schema.md` | IP 描述文件 `data/<ip>.yaml`（单一信息源）字段定义 |
| `references/rtl-coding-style.md` | RTL 编码规范（华为 Verilog 规范，Verilog-2001）与 testbench 约定 |
| `templates/` | 所有文档模板，`flow.py init` 时复制到 IP 目录 |
| `scripts/gen_docs.py` | 由 `data/<ip>.yaml` 生成接口文档、寄存器文档、C 头文件 |
| `scripts/check_style.py` / `run_lint.py` | 编码规范检查；风格检查 + lint，写 `reports/lint.log` |
| `scripts/check_docs.py` | 文档完整性、追溯性、审核记录、RTL 一致性检查 |
| `scripts/run_regress.py` | 通用回归（iverilog），写 `reports/regress.json`；`--stub` 用端口桩代替 RTL 做 TB 自检 |
| `examples/` | 标杆示例（few-shot）；`examples/demo_timer/` 为完整走完 P0–P6 的参考 IP |

角色 agent 定义在插件的 `agents/` 目录，hook 定义在插件的 `hooks/` 目录。

## 0. 基本原则

1. **单一信息源 (SSOT)**：参数、端口、时钟复位、中断、寄存器只写在 `data/<ip>.yaml`。`03_interfaces.md`、`04_registers.md`、`sw/<ip>_regs.h` 由脚本生成，禁止手改（hook 拦截）。
2. **先文档后代码**：行为变更顺序永远是 `00_requirements` → `01_spec` / `02_architecture` → `data/<ip>.yaml` → RTL → DV。
3. **不猜测，显式记录**：模糊、矛盾、缺失的地方，要么问用户（`Q-xxx`），要么做假设（`ASM-xxx`），都写进 `00_requirements.md`。
4. **可追溯**：每条 `REQ-xxx` 必须在 `01_spec.md` 中被引用，并在 `07_dv_plan.md` 中有对应测试点 `TP-xxx`。
5. **设计与验证独立**：tb-engineer 只根据规格编写验证，看不到 RTL（hook 强制执行）。RTL 与 TB 结果不一致时，由 debugger 以规格为准判定谁错。
6. **流程由程序判定**：是否进入下一阶段由 `flow.py` 调用检查脚本决定，不由模型自行判断。
7. **原始输入只读**：用户给的原始材料保存在 `<ip>/raw/`，不修改。
8. **人工审核点**：G0（需求）、G1（规格）、G2（架构）必须停下来等待用户审核。审核结果只能由编排者在用户明确通过后通过 `flow.py review` 写入。

## 1. IP 目录结构（参考 OpenTitan `hw/ip/<ip>/`）

```
<ip>/
├── README.md / CHANGELOG.md
├── raw/                       # 原始需求/规格（只读）
├── data/<ip>.yaml             # 单一信息源
├── doc/00_requirements.md … 10_checklist.md   # 03/04 为生成文件
├── rtl/                       # RTL 源码
├── dv/tb/<ip>_tb.v            # 黑盒自检查 testbench（dv/build/ 为运行产物，不提交）
├── syn/                       # 综合脚本（可选）
├── reports/lint.log           # [生成] run_lint.py
├── reports/regress.json       # [生成] run_regress.py
├── sw/<ip>_regs.h             # [生成] 寄存器 C 头文件
└── .flow/                     # 编排状态：state.json、handoff/（交接文件）、debug/（定位报告）、
                               #           answers/、reviews/、inputs/（用户答复、审核意见、迭代描述）
```

## 2. 角色

| 角色 | 是谁 | 负责 | 主要可写范围 |
|---|---|---|---|
| 编排者 | 主会话（你） | 运行 `flow.py next` 并执行它给出的动作；与用户交互（提问、审核、上报） | `.flow/answers` `reviews` `inputs`、`doc/08` |
| `spec-author` | agent | P0 需求、P1 规格与 yaml、审核修改、需求变更 | README、CHANGELOG、data/、doc/00 01 06 08 09 10 |
| `architect` | agent | P2 微架构、审核修改、变更同步 | doc/02 08 09 |
| `rtl-engineer` | agent | P3 RTL、05、lint，按定位报告修复 RTL | rtl/、syn/、doc/02 05 08 09 10 |
| `tb-engineer` | agent | P4 验证计划与黑盒 testbench（**看不到 RTL**） | dv/、doc/07 08 |
| `debugger` | agent | 回归失败时定位根因并分类，写 ITR 和报告（不改代码） | doc/08、.flow/debug/、dv/build/ |

所有 agent 都不能写生成文件、`raw/` 中已有的文件和审核字段；子 agent 不能运行 `flow.py` 的管理命令。hook 会拦截越权操作，并把原因反馈给调用方。

## 3. 流程

```
P0  spec-author 写 00 ─► [有 Open 的 Q] 编排者合并提问 ─► spec-author 落实答复 ─► G0 人工审核
P1  spec-author 写 yaml / 01 / 06 ─► G1 人工审核
P2  architect 写 02 / 09 ─► G2 人工审核
P3‖P4  rtl-engineer（RTL + 05 + lint）  ‖  tb-engineer（07 + 黑盒 TB，桩检查）   并行，相互看不到
       flow.py 检查：check_docs --stage dv、lint 报告有效、TB 桩检查 PASS；不通过则把问题退回对应 agent
回归  flow.py 运行 run_regress.py ─► PASS ─► 完成（汇报，签核 P6 由用户确认后进行）
                                  └► FAIL ─► debugger 定位 ─► rtl / tb / both：派对应 agent 修复 ─► 再回归
                                                            └► spec / tool：上报用户决定
```

- 每个阶段的产出必须通过对应的 `check_docs.py --stage`，否则 flow.py 把错误退回该 agent，最多重试 3 次，之后上报用户。
- 修复最多 3 轮，仍失败则上报用户。
- 已审核的 00 / 01 / 02 一旦提升 version，flow.py 会在下一步之前自动重开对应审核（多个合并为一次）。
- 需求变更：`spec-author`（00 → 01 → yaml）→ 重开审核 → `architect`（如受影响）→ 重开 G2 → `rtl-engineer` ‖ `tb-engineer` → 回归。
- 每轮修改都在 `08_iteration_log.md` 记录 ITR：发起者（rtl-engineer 初始实现 / debugger / spec-author 变更）新建，修复者补写修改，flow.py 填写回归结果。

## 4. 编排者协议（主会话必须遵守）

你是编排者，**只做调度和与用户交互，不亲自编写需求、规格、架构、RTL 或 testbench**（hook 会拦截）。

**新建 IP**：`python $SKILL/scripts/flow.py init <ip_dir> [--auto] --input <文件或文字> ...`（复制模板、把材料保存到 raw/、建立 .flow/）。

**循环**：反复执行下面两步，直到动作为 `finish`：

1. 运行 `python $SKILL/scripts/flow.py next <ip_dir>`（可能运行回归，Bash 超时设为 600000 ms）。
2. 按输出 JSON 的 `action` 执行，`instructions` 字段中有具体说明：

| action | 你要做的事 |
|---|---|
| `dispatch` | 对 `agents` 中每一项调用 Agent 工具：`subagent_type`、`description`、`prompt` **原样**传入；多于一项时在同一条消息中并行启动。等全部完成后回到第 1 步。如果找不到 `rtl-flow:<角色>` 类型，改用不带前缀的 `<角色>`。 |
| `ask_user` | 用 AskUserQuestion 合并提问 `questions`（每次最多 4 个，可分多次），把答复写入 `answers_file`，运行 `flow.py answers <ip_dir> --file <answers_file>`；用户不愿回答时用 `--none`。 |
| `review` | 汇报被审文档、要点（`highlights`）、新增的 ASM / DEC、需要用户判断的地方，用 AskUserQuestion 请用户选「通过」或「需要修改」，不知道审核人姓名时一并询问。通过：`flow.py review <ip_dir> --pass --reviewer <姓名>`；需要修改：把意见写入 `comments_file`，运行 `flow.py review <ip_dir> --changes <comments_file>`。**只有用户明确表示通过时才能用 `--pass`，在用户答复前不得继续。** |
| `escalate` | 向用户简要说明 `reason` / `detail`，请用户决定。继续当前步骤：把用户的说明写入 `.flow/inputs/` 下的文件，运行 `flow.py resume <ip_dir> --note <文件>`；按需求变更处理：`flow.py iter <ip_dir> --kind change --file <文件>`。 |
| `finish` | 汇报回归结果、各审核点状态、遗留 WARN；提醒签核（P6）需用户确认。 |

规则：
- 不要跳过 `next`，不要自己判断阶段是否完成，不要修改 `.flow/state.json`。
- 子 agent 不能向用户提问，它们的 Q 由 flow.py 汇总后交给你提问。
- 汇报时不要把文档全文贴进对话，给出文件路径和要点即可。
- 用户的口头修改意见同样要落到文档：审核意见用 `review --changes`，需求变更用 `iter --kind change`。
- `flow.py guard <ip_dir> off` 会关闭路径保护，只能在用户明确要求手工修改时使用，改完后用 `on` 恢复。

**自动模式**（`init --auto`，或用户说「不用等我审核」）：G0–G2 不停顿，审核字段写 `approved: skipped`，汇报中注明「未经人工审核」；P0 的 Q 仍要提问。`skipped` 在 `--stage signoff` 报 ERROR，交付前必须补审。

**中断后继续**：直接运行 `flow.py next <ip_dir>`，flow.py 从 `.flow/state.json` 恢复。如果上次派发的 agent 没有完成，flow.py 会让对应 agent 重做。

**迭代**（验证失败、需求变更，见 `/rtl-flow:ip-iter`）：`flow.py iter <ip_dir> --kind failure|change --file <描述文件>`，然后进入循环。

## 5. 审核点 (Review Gates)

| 闸门 | 被审文档（记录审核结果） | 一并审核 |
|---|---|---|
| G0 | `00_requirements` | Q 的答复、ASM |
| G1 | `01_spec` | 03 / 04（即 yaml）、06 初稿、新增 ASM |
| G2 | `02_architecture` | 本阶段新增的 DEC |

`flow.py review --pass` 在被审文档的 front matter 写入：

```yaml
reviewer: 张三             # 审核人
approved: 0.2@2026-10-22   # <通过时的 version>@<日期>
```

`approved` 中的版本必须等于当前 `version`。审核后内容实质变化须提升 version，flow.py 随即重开该审核点。

## 6. 命令速查

```bash
python $SKILL/scripts/flow.py init    <ip_dir> [--auto] --input <文件或文字> ...
python $SKILL/scripts/flow.py next    <ip_dir>
python $SKILL/scripts/flow.py status  <ip_dir>
python $SKILL/scripts/flow.py answers <ip_dir> --file F | --none
python $SKILL/scripts/flow.py review  <ip_dir> --pass --reviewer NAME | --changes F
python $SKILL/scripts/flow.py iter    <ip_dir> --kind failure|change --file F
python $SKILL/scripts/flow.py resume  <ip_dir> [--note F]

python $SKILL/scripts/gen_docs.py     <ip_dir>                  # 由 yaml 生成 03/04 与 C 头文件
python $SKILL/scripts/run_lint.py     <ip_dir>                  # 风格检查 + lint，写 reports/lint.log
python $SKILL/scripts/run_regress.py  <ip_dir> [--stub]         # 回归，写 reports/regress.json
python $SKILL/scripts/check_docs.py   <ip_dir> --stage req|spec|arch|rtl|dv|signoff
```

check_docs 的阶段是累积的：当前阶段及以下的检查失败为 ERROR，以上的仅为 WARN。
依赖：Python 3.8+、PyYAML；lint 需要 Verilator 或 Verible；回归需要 Icarus Verilog ≥ 12。

## 7. P6 签核

签核需用户确认：按 `10_checklist.md` 逐项勾选；所有文档 `status` 改为 `Released` 后运行 `check_docs.py --stage signoff`（Released 状态下 TODO/TBD/占位符/Open 的 Q 都会报 ERROR；三个审核点都必须是人工通过）。签核时如需修改文档，先用 `flow.py guard <ip_dir> off`，完成后恢复。
