# 总 agent 执行手册

## 任务路由

| 用户意图 | 行为 | 不需要等待的部分 |
| --- | --- | --- |
| 梳理/评审 | 读需求、代码、技能与配置，输出事实和差距 | 不执行子技能中的生成、清理或遥测 |
| 从输入生成平台 | intake→design→components→integrate→tests | 工具未定可完成源码，声明未编译 |
| 集成现成组件 | 验证组件合同→platform→tests | 不重写已运行组件，不自动生成新RTL |
| 仅生成BFM或TC | 调用相应子技能，验证其必要前提 | 不声称完整平台已完成 |
| 执行/回归 | 校验批准版本与工具profile→compile→execute→deliver | 未配置环境只阻塞执行，不回滚已完成设计 |
| 修复失败 | 分类platform/model/DUT/environment→最小修复→同test/seed复跑 | DUT修复须属于用户授权；保留失败证据 |

调用者只需提出业务目标，不必手动选择四个skill。总agent根据目标自动路由；能从工程推断的事实先读取，不额外询问已给出的信息。

## 项目状态与文件布局

技能包根目录为asset_root，目标工程为project_root；二者不能混为一谈。建议输出布局如下，已有工程布局优先：

```text
<project>/dv/
  project-state.json        # 状态/证据索引，不存私钥
  spec/                    # 输入清单、需求追溯、未决项、设计和组件合同
  components/              # agent生成的组件；按profile适配目录
  tb/                      # 集成平台（或项目已有env/top结构）
  tests/                   # 用例和manifest
  sim/                     # filelist、受审核工具profile
  runs/<campaign>/<run>/    # 编译/仿真原始证据，失败亦保留
  reports/                 # 从证据生成的交付报告
```

[project-state示例](../assets/project-state.example.json)只是人工/agent维护的数据协议，当前没有消费它并自动运行的CLI。现有bt_uvm要求独立JSON contract/design/ir/platform/plan/manifest，不能把project-state直接传给它。字段兼容转换属于总agent显式步骤，需逐项检查。

状态使用not_started/in_progress/blocked/completed/failed；每阶段结论另记claim：draft/generated/compiled/model_tested/real_dut_tested。status completed本身不代表pass。缺事实时记录question ID、受影响组件/测试及依赖，不把整项需求删除。

## 阶段检查单

1. **intake**：记录来源路径及SHA-256、RTL顶层、filelist/includes/defines/parameters、配置集合、单一写范围。P0可外部转换，保留原件与转换件定位。检查方向以DUT还是BFM为参照。
2. **design**：需求→feature→testpoint→test映射；接口采样/驱动/复位；独立oracle；事务生命周期；checker和coverpoints；组件类/方法/配置/TLM ABI；冻结批准子集与剩余缺口。
3. **components**：按[组件编写流程](component-authoring.md)完成BFM/GEN/RM/checker/SVA/coverage。可并行写不同组件，不能两方同时改transaction定义；接口变更先更新合同并通知依赖方。
4. **integrate**：选明确profile，审查包内脚本后在唯一输出目录使用；检查外部库及版本；连接图、顶层端口、config_db、factory、复位、filelist、类型参数。运行当前static platform并保留结果，但不当SV语义证明。
5. **tests**：先一个有效端到端sanity，再适用边界、错误、复位在途与压力。TC读取实际平台API，不能从提示猜类名。计划/manifest逐项对齐，排除项及未实现项保留原因。
6. **compile**：审核SSH profile及host，确认真实工具版本/库与编译命令，完整编译最终源码；当前SSH适配器未实现时使用宿主已获授权的远端能力并原样收集证据，不能宣称已由bt_uvm自动远程执行。没有远端能力就not_compiled。
7. **execute**：先编译后仿真；日志保留，失败分类，取消/超时/断线状态明确。同run_id查询未知结果，不盲目重提交。与现有evidence v1不兼容的远端回执不能伪造成v1记录。
8. **deliver**：列生成/编译/替身自检/真实DUT实测及未运行；审核覆盖目标、批准分母与全量test/seed；命令、工具、源码、证据摘要关联；报告缺口和可复现步骤。

## 门禁调用边界

[运行指南](runtime-guide.md)给出实际CLI；各static gate现在互相独立，必须显式运行并保存receipt。每份receipt索引记录输入版本/摘要、命令、原始输出、退出码、scope。现有run不会自动消费前置receipt，不能靠写project-state宣称机器已强制执行。

当前aggregate拒绝同目录多个test/seed尝试：将一个被审核的campaign结果集与历史attempt分开索引，保留所有失败，并说明本次采纳哪一次。不得删除历史失败或偷偷挑通过项。自动attempt选择机制尚待实现。

## 变更失效表

| 变更 | 需重做 |
| --- | --- |
| 需求/时序/接口/参数 | design及相关组件、测试和所有下游证据 |
| transaction/组件ABI | 所有依赖组件及集成/编译/运行 |
| TB/RTL/filelist/宏/UVM库 | 源码完整性与编译、相关运行 |
| test/seed/plan/判定器阈值 | 计划审核、manifest及受影响运行/聚合 |
| 仅交付文字 | 对照既有证据复核，不能升级claim |

## 调度与交接

总agent分派给子技能的最小包：task_id、目标、输入路径/摘要、明确profile、允许写路径、只读路径、依赖ABI、验收标准。返回最小包：files、hashes、状态、未决项、编译/仿真是否执行及原始证据。

平台不负责猜缺失RM，TC不负责修DUT，BFM不负责证明自己生成的预期正确。总agent对这些跨层缺口负责，能实现则落实，缺语义则明确阻塞。
