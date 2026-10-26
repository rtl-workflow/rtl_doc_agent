---
doc: 10_checklist
ip: demo_timer
version: 1.4
status: Released
updated: 2026-10-25
owner: rtl-flow-example
---

# demo_timer 签核清单

> 参考 OpenTitan 的 D/V 阶段划分。勾选格式 `- [x]`，不适用写 `- [x] ~~项~~ 不适用：原因`。每项注明证据。

## D0 需求与规格

- [x] 00_requirements 已经用户确认，无 Open 的 Q（`approved: 1.2@2026-10-24`，ITR-008 重审通过；Q-001 ~ Q-003 Closed，ASM-001 ~ ASM-004 已确认）
- [x] data/<ip>.yaml 完成，gen_docs.py 生成成功（`gen_docs.py --check` 全部 up-to-date）
- [x] 01_spec 覆盖全部 REQ，已经用户审核（`check_docs.py --stage spec` 覆盖检查通过；`approved: 1.2@2026-10-24`）
- [x] 02_architecture 框图与子模块划分完成，已经用户审核（子模块表检查通过；`approved: 1.2@2026-10-24`）

## D1 RTL 功能完整

- [x] 全部 RTL 文件完成，顶层端口与 yaml 一致（check_docs --stage rtl 通过）
- [x] 05_rtl_structure 完成
- [x] Lint 零 error，warning 均已豁免说明（`reports/lint.log`：PASS，风格检查 0 违规，Verilator 0 error / 0 warning，无豁免）
- [x] 所有寄存器与 yaml 一致（TP-001、TP-002 回读验证；A7 读数据逐次比对）

## D2 设计稳定

- [x] 所有 P0/P1 需求实现（REQ 11/11，见 07 §6）
- [x] ~~CDC 表完整，同步器均使用统一模块~~ 不适用：单时钟域（02 §6）
- [x] 综合无 latch、无未连接端口（`syn/synth.ys` 内 latch 断言与 `check -assert` 通过）
- [x] 06_programmers_guide 完成

## D3 设计签核

- [x] 所有文档 status 为 Released
- [x] check_docs --stage signoff 通过（0 error）
- [x] CHANGELOG 已更新版本号（2.0.0）

## V0 验证计划

- [x] 07_dv_plan 完成，每条 REQ 至少关联一个 TP

## V1 冒烟测试

- [x] 测试平台可运行，复位与寄存器读写用例通过（`test_reset`、`test_reg_rw`）

## V2 功能完整

- [x] 全部 TP 用例实现并通过（TP-001 ~ TP-011；TP-010 为综合评估）
- [x] ~~代码覆盖率 ≥ 90%~~ 不适用：iverilog 不支持代码覆盖率，以 13 个功能覆盖点全部命中 + 变异测试 7/7 检出替代（07 §5）

## V3 验证签核

- [x] ~~代码覆盖率达到 07 中的目标，未覆盖项已分析~~ 不适用：同 V2，替代指标已达成
- [x] 无 Open 状态的 BUG（BUG-001 ~ BUG-003 均 Closed）
- [x] 08_iteration_log 记录完整（ITR-001 ~ ITR-008）
