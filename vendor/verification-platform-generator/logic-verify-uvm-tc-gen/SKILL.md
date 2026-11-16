---
name: logic-verify-uvm-tc-gen
description: 总agent调用的UVM测试用例生成子技能；从批准测试点与现有平台API由agent编写用例，保留追溯与阻塞项，不包含独立生成器或SSH执行器。
version: 3.0.0
---

# UVM 测试用例生成子技能 3.0.0

由[总skill](../SKILL.md)调度。接收已集成平台、明确的profile和批准计划，输出用例及追溯文档；不负责凭空创建RM/scoreboard或修改DUT。保留既有因子分解方法，但所有协议参数以项目合同为准。本包不调用遥测、不强制评分、不依赖某个宿主question工具。

## 输入与平台路径

[输入schema](schemas/input_schema.json)共同必填：`source_mode`、`platform_dir`、`platform_type`、`input_mode`、`approved_plan_ref`、`uvm_version`、`library_identity`。

`source_mode` 显式选择 `prepared` 或 `excel`：总agent默认优先采用prepared工作流，传入归一化后的 `prepared_testpoints` 非空数组（每项id/source_ref/description必填），或互斥的 `prepared_input_ref`（保留稳定ID和原始来源的MD/JSON/CSV引用）。引用内容与摘要、ID唯一性由总agent核验。此子技能不增加文档转换器。Excel分支必需 `excel_file` + `sheet_name`，不得与prepared输入混用。

- `platform_type` **必须显式提供，无默认值**：1=Superbench，2=Gaea。不得根据目录缺失自行创建另一套平台。
- `input_mode` 为testpoint/testcase。可从列名提出候选，但实际选择由总agent合同给出；同名/多义列返回未决项。
- Excel分支的 `sheet_name` 必须明确且存在；不得退回首个sheet或根据超时选择。prepared分支不要求Excel或sheet。
- 已经获得的用户/设计批准由总agent传入或引用，子技能不重复要求交互。新语义冲突提交总agent；未知值不等于批准。

| 项目 | Superbench (1) | Gaea (2) |
| --- | --- | --- |
| 测试目录 | `tc/` | `tests/` |
| 用例清单 | `tc/tc.list` | `tests/tc.list` |
| 编译filelist | `cfg/env.f` | `sim/scripts/tb_list.f` |
| 理解文档 | `tc/platform_understanding.md` | `tests/platform_understanding.md` |

以上相对 `platform_dir`，也是manifest唯一映射。适配现有非标准布局必须先在总agent项目合同中明确映射。创建目录仅在已授权可写范围内；不能覆盖既有文件或静默替换平台。

Gaea必须保留两级清单链：`sim/scripts/tb_list.f`同时引用`sim/scripts/tc_list.f`和`tests/tc.list`，前者已有basic_tc/sanity条目，后者含tc_define/basic_tc/sanity/tc_undef。新增用例登记在`tests/tc.list`中、tc_undef之前，不能创建不存在的`sim/scripts/tc.list`，不能用新用例清单替换或移除基础类链。实际证据与工作目录见[模板构建链说明](../logic-verify-uvm-platform-gen/references/template_structure.md)。

模板runvcs从sim/scripts读取sim.cfg，再切换到sim/<case>[.<suffix>]编译；顶层-f、嵌套-F、重复基础类/sanity和另外传入test_dir均需目标工具profile复核。本技能只追加经审核的新用例记录，不自动修旧构建路径或删除重复基础条目。未验证这些legacy依赖时报告blocked/not_compiled，不虚构编译通过。

## 执行流程

1. **校验输入**：读取计划及选定sheet或prepared数据/引用，登记原件与归一化件摘要、行号/段落定位、稳定testpoint ID、输入模式与批准版本。prepared引用若没有稳定ID/来源或内容缺失则blocked，不凭空补事实。
2. **登记全量测试点**：每一行保留为included/blocked/excluded记录。`skip testpoint`、`测试活动`、`skip Test Activity`只提供候选分类，不因skip/BT关键字自动删除。excluded必须带批准的理由和计划引用；未批准排除记blocked，仍在全量追溯中。不得把N/A或跳过当通过。
3. **理解平台**：读取真实env_cfg、dut_cfg、base_test/basic_tc、transaction/sequence、RM/scoreboard/coverage接口与filelist。形成平台理解文档，记录类型、配置路径、可重写回调、reset/结束语义、UVM库身份、已知缺口。只列真实可调用API，不造方法适配想象的用例。
4. **因子分解**：参考[因子指导](references/测试因子设计指导书.md)，提取条件、前提、目标，关联平台配置。未匹配项返回blocked及缺失API/语义；不能“使用默认值或跳过”。总agent可明确批准子集或替代配置，但必须记录理由，保持原计划分母。
5. **形成步骤**：逐用例列source ID、前提、配置、刺激、独立预期、实际观测、checker、coverage、seed及排空/超时条件。随机范围、通道数、数据长度、字节序、错误模式来自批准规格；“满通道”不是固定512，“随机长度”不是默认60..9672，VLAN/CRC不适用于所有DUT。边界值缺失则阻塞相关用例。
6. **确认合同**：已有批准则直接复用；新增关键语义由总agent处理确认。本子技能返回可审阅的步骤和未决项，禁止把超时或无回复视为同意。
7. **生成代码**：每个用例独立SV文件；按现有profile采用 `svf_<name>` 和真实base class。`basic_tc`/svf是项目约定，不是UVM标准。只覆写需要的phase，调用适当super方法并保留objection/排空/timeout。不要为“十个phase齐全”生成空任务。通过获批配置/抽象API驱动，不直接篡改DUT内部状态、RM、checker或阈值。公共逻辑需要修改基础类时提交总agent审查可写范围。
8. **集成清单**：先读tc.list及filelist，以真实构建规则计算相对路径。相同条目且内容摘要一致可标记复用；同名内容不同为冲突，不能静默跳过。新增文件/条目及修改前后摘要写入产物清单，保留既有用例。
9. **审阅与编译交接**：词法/括号检查仅前置筛查，不是SV语法或UVM验证。将最终源文件、filelist与摘要交回总agent，按[SSH合同](../references/ssh-backend-contract.md)编译。SSH后端尚未实现、仿真器未确定，不自动调用UVS；没有工具时compile_status=blocked或not_run，继续交付可完成的生成结果。
10. **失败处理与证据**：保留每次编译/运行的命令、版本、原始日志、源码集合摘要。修复只限授权TB文件，不能删检查器/缩减计划获取绿色。源码或filelist修改后原结果失效，必须重编译并按同test/seed复跑；不删日志、不覆盖旧attempt。

## 交付内容

- 平台理解文档：实际基类、组件/API、clock/reset、oracle/actual/checker路径、UVM库版本和限制。
- 因子表：testpoint、因子/范围/来源、平台配置路径、匹配状态、未决项；仅获批组合进入生成。
- 步骤表：test ID、requirement/testpoint IDs、前提、刺激、期望、观测/checker、coverage、seed。
- 全量处置表：每个输入行的included/blocked/excluded、理由和批准引用；保留全量计划与获批子计划区别。
- 用例源码、tc.list/filelist变更及摘要；如果编译执行过，附真实证据引用。

[好代码标准](references/好代码标准.txt)作为辅助审阅参考；本合同中已批准计划、独立RM、不可篡改checker和证据保存要求优先于泛化示例。生成的测试必须触发真实比较；调用日志打印或零UVM错误不是完成条件。

## 版本与兼容

本包入口、manifest和输入/输出合同统一为 **3.0.0**；schema方言为Draft-07，与UVM版本独立。保留旧 `excel_file/sheet_name/platform_dir/platform_type/user_prompt`，Excel旧调用需补 `source_mode=excel`；也可改用总agent提供的prepared数组/引用。平台类型不再有默认值，新增source_mode/input_mode/approved_plan_ref/UVM库身份必填。旧调用缺字段返回待补信息，不猜测。

[输出schema](schemas/output_schema.json)中：

- `status=generated/blocked/failed`；兼容旧success，仅视为generated别名，**不能当编译或DUT PASS**。
- schema_version、validation_scope=generation_only、compile_status、artifacts_out、logs、issues必填；generated/success需非空产物，每项path/type/sha256必填。blocked/failed需issue。
- `compile_status` 独立为not_run/blocked/passed/failed；passed/failed须有日志/命令/工具版本/最终源码集合摘要证据。旧compile_result可保留作附加元数据，但不能替代必需证据。
- `testpoint_disposition` 必填，列全量输入点及处置/来源；excluded必须带approval_ref。schema不检查输入行全集、语义正确或批准真实性，总agent必须复核，不能仅见JSON有效就放行。
- metrics是生成工作量，不是覆盖闭合证据。schema不认证文件存在、路径安全、哈希真实性或真实编译。最终判定由总agent完成。
