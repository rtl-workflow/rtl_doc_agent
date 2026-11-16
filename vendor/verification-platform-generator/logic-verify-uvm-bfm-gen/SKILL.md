---
name: logic-verify-uvm-bfm-gen
description: 总 agent 调用的 UVM BFM 生成子技能；按批准接口合同由 agent 编写代码，输出组件清单与未决项。无独立生成器或内置远端编译器。
version: 3.0.0
metadata:
  category: tool
---

# UVM BFM 生成子技能 3.0.0

本包由[总 skill](../SKILL.md)编排：接收接口/时序合同，生成驱动与观测组件，并交回产物清单。它是 agent 执行规程，**不包含独立代码生成器、schema执行器或SSH执行器**。本包不调用运营遥测，不要求用户评分，也不虚报离线排队。

## 输入合同

机器输入见[输入 schema](schemas/input_schema.json)。执行前由总 agent 校验，关键事实未知时返回 `blocked` 与缺项，不用模板默认值补协议。

必填：`interface_name`、`output_dir`、`uvm_version`、`library_identity`、`protocol_contract`，以及以下三种输入之一：

| 模式 | 字段 | 规则 |
| --- | --- | --- |
| Excel | `excel_file` + `sheet_name` | sheet须显式指定且真实存在；未指定时返回候选给总agent，不自动选首个或pkt_fifo；未答复/超时不是批准 |
| 信号表 | `signals` | 每项name/direction/width/description必填，位宽正整数；不能同时提交Excel来源 |
| 已整理文本 | `interface_markdown` | 已批准的接口Markdown正文；总agent转换成信号/时序事实并记录来源，不将文字解析成功等同语义批准 |

`protocol_contract` 必须包含方向视角 `direction_view`（dut/bfm）、`clocking`、`reset`、`acceptance` 和 `source_ref`。I/O方向按声明视角解释；inout须另定义驱动时段、释放及冲突检查。记录边沿、clocking skew、复位极性/同步性、握手、取消及字节序；未涉及的项写明有来源的不适用理由。

Excel列可使用名称、I/O、位宽、说明、源代码（Wavedrom）、补充说明，以及可选自测试/带激励/trans字段。随包[参考工作簿](references/bfm_test_all.xlsx)仅作格式参考，不视为本项目已确认协议。Wavedrom不能覆盖文字合同；有冲突提交总agent决策。

`self_test` / `with_stimulus` 可省略（语义为关闭），兼容旧值 Y/N/1/0 字符串或布尔值。开启时必须提供获批transaction字段与激励预期；缺失返回blocked，不能固定Packet或数据1..8替代真实合同。

## UVM 与模板边界

参考[生成规则](references/prompt_templates.md)和相邻平台包的 Gaea BFM 模板。模板路径：`../logic-verify-uvm-platform-gen/references/platform_demo/gaea_demo/gaea_demo/env/bfm/bfm_temp/`。该依赖必须存在；模板空任务不是已实现行为。

`uvm_version` 与 `library_identity` 来自总agent的库profile。目标遵循选定的标准UVM API；不要把旧UVM1.1模板仅改标签就宣称1800.2兼容。保留合法factory/config_db/TLM结构，验证virtual interface、active/passive、单驱动和观测端口；需要不同框架时由总agent批准适配合同。

BFM负责真实信号驱动和采样，不自行生成黄金预期并验证自身。独立RM/scoreboard由平台接入；接受/实际输出分别由真实monitor观测，禁止固定PASS和固定活动计数。

## 执行步骤

1. 总agent传入已批准输入、可写范围与run/attempt标识；登记来源和未决项，复用已经给出的确认，不重复要求评分或确认。
2. 校验schema及协议语义，检查sheet/端口/位宽/时序/单一驱动者；保留冲突，不静默丢弃不认识的信号或字段。
3. 读取模板并列组件依赖、TLM类型、配置路径、文件清单。默认Gaea布局包含集成类、cfg、driver、interface、monitor、receiver、flist、ini；不适用组件必须记录理由并获得总agent设计合同支持。
4. 在批准的 `output_dir` 下创建唯一attempt目录；拒绝越界和已存在目标覆盖。生成接口协议行为、reset清理、超时与采样逻辑，不复制注释占位当实现。
5. 按实际库组织package/import/include和filelist；Gaea依赖 `env/common/glb_dec.sv` 中的类型时，确认其package作用域和编译顺序，不盲目拼接源码。
6. 做源码审阅；语法检查不是编译。将最终源文件及摘要交回总agent，由总agent按[SSH后端合同](../references/ssh-backend-contract.md)安排编译/仿真。SSH后端尚未实现，具体仿真器未选定；本包不默认调用UVS。工具未配置记录 `compile_status=blocked`，已完成生成仍可交付但不得称已编译。
7. 保留原始日志、命令、工具版本、源码摘要和每次失败记录。**禁止删编译日志；编译后若更改包括import/include在内的任何源文件，旧编译结果失效，必须对最终集成产物重编译。**
8. 交回[输出 schema](schemas/output_schema.json)规定的产物、阶段状态、未决项和证据引用。文件数量一致只是清单检查，不是功能验收。自测试须另有真实执行/比较证据；不能计为真实DUT通过。

## 输出与兼容迁移

本包文档、manifest及schema合同统一为 **3.0.0**，JSON Schema方言为Draft-07（与UVM版本无关）。

- 保留 `excel_file/sheet_name/signals/interface_name/output_dir/wavedrom/self_test/with_stimulus` 旧字段；新增必填UVM库与协议合同。旧调用缺少这些事实时应返回待补信息，不推断。
- 输出 `schema_version="3.0.0"`、`status`、`validation_scope="generation_only"`、`compile_status`、`artifacts_out`、`logs`、`issues` 必填。
- 推荐 `status=generated/blocked/failed`；兼容旧 `success`，但仅是generated的旧别名，**不是编译或仿真PASS**。generated/success要求非空产物清单；每项必须有path/type/sha256。blocked/failed必须给出至少一个issue。
- `compile_status` 独立为not_run/blocked/passed/failed；passed/failed必须附非空编译证据（真实日志路径、工具版本、命令、最终源码集合摘要）。schema只能检查字段形状，不能证明文件存在、日志真实性、路径安全或语义正确，总agent还须独立核验。
- 不在此输出宣称真实DUT通过；总agent依据完整门禁和独立证据形成最终判定。
