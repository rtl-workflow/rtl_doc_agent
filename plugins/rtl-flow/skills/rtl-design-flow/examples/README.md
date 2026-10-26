# 标杆文档 (Few-shot Examples)

AI 执行 rtl-design-flow 时，应**优先模仿本目录示例的写法、粒度与措辞**。

## demo_timer（内置示例）

从一句话的不规范需求出发，完整走完 P0–P6，并包含一次需求变更迭代。所有仿真、lint、综合结果均为真实运行结果，可通过 `check_docs.py --stage signoff` 与 `run_regress.py --stub`。

| 可以参考的写法 | 位置 |
|---|---|
| 不规范需求 → REQ / ASM / Q 的改写，原始材料问题记录 | `raw/timer需求.txt` → `doc/00_requirements.md` |
| 规格每节标注「覆盖需求」，WaveDrom 时序 | `doc/01_spec.md` |
| 无 FSM 时用次态优先级表描述控制逻辑；综合实测 PPA | `doc/02_architecture.md` |
| 设计取舍的选项对比 | `doc/09_decisions.md`（DEC-001 ~ DEC-005） |
| 测试点 ↔ 需求 ↔ 用例三方追溯；断言清单；覆盖率不可得时的替代指标 | `doc/07_dv_plan.md` |
| 各类根因的迭代记录：lint、工具问题、TB 盲区、估算偏差、需求变更、TB 期望值错误、流程规则变更 | `doc/08_iteration_log.md`（ITR-001 ~ ITR-009） |
| 需求变更按 `00 → 01/02/09 → yaml → RTL → DV` 顺序执行 | ITR-005 |
| 审核记录（G0 / G1 / G2）的写法 | `doc/00`、`01`、`02` 的 front matter `reviewer` / `approved`；ITR-007 |
| lint 报告（含 RTL 摘要，供检查脚本判断是否过期） | `reports/lint.log` |
| 02 子模块表：模块名与 RTL、05 一一对应 | `doc/02_architecture.md` §2 |
| 不适用项的写法（附原因与替代证据） | `doc/10_checklist.md` |
| 华为 Verilog 编码规范的 RTL 写法：文件头、`i_`/`o_` 端口、每个寄存器一个 `always` 块、`if (rst_n == 1'b0)` | `rtl/*.v` |
| 规范偏离的记录方式（HW-33） | `doc/05_rtl_structure.md` §6、DEC-007 |
| 黑盒自检查 Verilog-2001 testbench：只通过顶层端口访问 DUT；定向 + 参考模型逐周期比对 + 覆盖点 | `dv/tb/demo_timer_tb.v` |
| 黑盒下观测内部行为：寄存器回读比对、`o_irq` 上升沿 + 时钟沿计数器测时间、按参考模型计数值对齐同拍冲突 | `dv/tb/demo_timer_tb.v`（`wait_count`、`test_periodic`、`test_priority`）、`doc/07_dv_plan.md` §2 |
| 用变异测试证明 testbench 有效 | `dv/run_mutation.py` |

> **与多 agent 流程（0.4.0）的关系**：demo_timer 的设计与文档是在单 agent 流程下完成的，testbench 已在 ITR-009 改为黑盒（不含 `U_dut.xxx` 层次引用），与 tb-engineer 的规则一致，可整体参考。示例自带的 `dv/run_sim.py` 与 `run_regress.py` 的输出约定一致（`python $SKILL/scripts/run_regress.py examples/demo_timer [--stub]` 可直接运行）。

运行环境（示例中实际使用的版本）：Icarus Verilog 13.0、Verilator 5.052、Yosys 0.70（yowasp-yosys）、Python 3.12 + PyYAML。在 Windows 上可通过 `conda create -n rtlsim -c conda-forge iverilog verilator` 安装，使用 Verilator 时需设置 `VERILATOR_ROOT=<env>/Library`。

## 添加团队自己的示例

```
examples/
└── <example_ip>/            # 目录结构与 SKILL.md §1 一致
```

1. 优先放一个**完整**的中等复杂度 IP（有寄存器、FSM、中断），胜过多个零散片段。
2. 必须能通过 `check_docs.py --stage signoff`，避免 AI 学到不合规的写法。
3. 去除涉密信息（工艺、客户名、内部地址）。
4. 保留 `raw/` 中的原始不规范材料，让 AI 学会如何改写需求。
