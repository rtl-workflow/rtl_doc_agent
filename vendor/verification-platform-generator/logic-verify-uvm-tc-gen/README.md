# logic-verify-uvm-tc-gen 3.0.0

本包是[总agent](../SKILL.md)调度的测试用例生成子技能。由宿主agent阅读批准测试点及已有平台API并编写代码；不是独立可执行生成器，没有内置Excel转换入口、schema验证器或远端编译器。完整流程以[SKILL.md](SKILL.md)为准。

## 输入

[输入schema](schemas/input_schema.json)使用JSON Schema Draft-07。下例展示必要字段，不代表对应文件/库已存在或获得批准：

```json
{
  "source_mode": "prepared",
  "prepared_testpoints": [
    {"id": "TP-001", "source_ref": "spec.md#R1", "description": "批准的行为及检查目标"}
  ],
  "platform_dir": "/project/dv",
  "platform_type": 2,
  "input_mode": "testpoint",
  "approved_plan_ref": "/project/spec/approved-plan.json",
  "uvm_version": "1.2",
  "library_identity": "project-profile:uvm-1.2"
}
```

`source_mode`必须显式为prepared或excel。prepared接收总agent归一化的非空 `prepared_testpoints`（id/source_ref/description必填），或互斥的 `prepared_input_ref`（MD/JSON/CSV引用，保留稳定ID、原始来源和摘要）。引用是否存在、ID唯一性和内容是否齐全由总agent核验；本包没有转换器。

Excel模式改为 `source_mode=excel` 并提供 `excel_file`、`sheet_name`，不能同时提供prepared字段。`platform_type`必须显式提供（1=Superbench，2=Gaea），无默认值；Excel的sheet必须明确且真实存在。不自动选择首个sheet，不把未答复视为批准。测试模式可提出候选，但最终输入应由总agent确定。

## 平台映射

| 项目 | Superbench (1) | Gaea (2) |
| --- | --- | --- |
| 用例目录 | tc/ | tests/ |
| 用例清单 | tc/tc.list | tests/tc.list |
| 编译filelist | cfg/env.f | sim/scripts/tb_list.f |

均相对platform_dir。与[manifest](manifest.yaml)一致，定制路径须在项目合同明确，不根据默认类型猜测。basic_tc、svf命名是既有profile约定，不是IEEE UVM要求。

Gaea的tb_list.f同时引用sim/scripts/tc_list.f和tests/tc.list；**新增用例清单是tests/tc.list，原sim/scripts/tc_list.f基础类链必须保留**。现有tests/tc.list的tc_define/basic_tc/sanity/tc_undef顺序不能被生成器整体替换；新条目位于tc_undef前。runvcs预期从sim/scripts启动，编译前切到sim/<case>[.<suffix>]；-f/-F相对路径、重复来源及外部库仍属legacy待核验项。详见[实际构建链与限制](../logic-verify-uvm-platform-gen/references/template_structure.md)，本次没有修改或执行构建脚本。

## 生成与验收边界

1. 读取全量测试点并形成处置表；skip/BT关键字仅供分类，不静默过滤。排除须有理由和批准引用，未知项保留blocked。
2. 理解真实平台API，分解因子和范围；不能默认512通道、固定包长或VLAN/CRC行为。
3. 复用总agent已批准的设计/步骤；新语义冲突交回总agent，不循环索要确认/评分。
4. 生成用例与清单，保留来源、源码摘要及旧文件；只覆写需要的phase，不把空phase当完成。
5. 交总agent按[SSH合同](../references/ssh-backend-contract.md)编译与运行。SSH后端尚未实现，仿真器未确定，无默认UVS调用。
6. 保留原始日志与失败attempt；编译后改任何源码/filelist必须重编译，不能删日志或沿用旧通过。

## 输出合同和迁移

[输出schema](schemas/output_schema.json)版本3.0.0：生成状态与compile_status分开。推荐generated/blocked/failed；旧success仅保留为生成状态兼容别名，不是PASS。每个产物path/type/sha256必填；generated/success至少一个产物；编译passed/failed必须有编译证据引用。JSON合法不证明真实执行或功能正确，最终判定归总agent。

从旧1.x/2.x迁移时保留旧参数字段，补显式source_mode、platform_type、input_mode、approved_plan_ref、uvm_version及library_identity；旧Excel调用使用source_mode=excel，prepared工作流可由总agent传入归一化数组/引用。旧输出补schema_version、validation_scope、compile_status、issues、testpoint_disposition和产物摘要；不能把旧success自动升级为已编译。旧compile_result仅作附加元数据。

Python依赖文件中的pandas/openpyxl仅为读取Excel的可选宿主依赖，不等于已安装。发布包不包含遥测文件，不调用遥测或评分流程；第三方宿主的独立采集行为不由本包控制。
