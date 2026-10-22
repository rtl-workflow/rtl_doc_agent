---
doc: 10_checklist
ip: {{ip}}
version: 0.1
status: Draft
updated: {{date}}
owner: {{owner}}
---

# {{ip}} 签核清单

> 参考 OpenTitan 的 D/V 阶段划分。勾选格式 `- [x]`，不适用写 `- [x] ~~项~~ 不适用：原因`。

## D0 需求与规格

- [ ] 00_requirements 已经用户确认（G0，front matter `approved`），无 Open 的 Q（或已记录为风险）
- [ ] data/<ip>.yaml 完成，gen_docs.py 生成成功
- [ ] 01_spec 覆盖全部 REQ，已经用户审核（G1，front matter `approved`）
- [ ] 02_architecture 框图与子模块划分完成，已经用户审核（G2，front matter `approved`）

## D1 RTL 功能完整

- [ ] 全部 RTL 文件完成，顶层端口与 yaml 一致（check_docs --stage rtl 通过）
- [ ] 05_rtl_structure 完成
- [ ] Lint 零 error，warning 均已豁免说明（`reports/lint.log` 与当前 RTL 一致）
- [ ] 所有寄存器与 yaml 一致

## D2 设计稳定

- [ ] 所有 P0/P1 需求实现
- [ ] CDC 表完整，同步器均使用统一模块
- [ ] 综合无 latch、无未连接端口
- [ ] 06_programmers_guide 完成

## D3 设计签核

- [ ] 所有文档 status 为 Released
- [ ] check_docs --stage signoff 通过
- [ ] CHANGELOG 已更新版本号

## V0 验证计划

- [ ] 07_dv_plan 完成，每条 REQ 至少关联一个 TP

## V1 冒烟测试

- [ ] 测试平台可运行，复位与寄存器读写用例通过

## V2 功能完整

- [ ] 全部 TP 用例实现并通过
- [ ] 代码覆盖率 ≥ 90%

## V3 验证签核

- [ ] 代码覆盖率达到 07 中的目标，未覆盖项已分析
- [ ] 无 Open 状态的 BUG
- [ ] 08_iteration_log 记录完整
