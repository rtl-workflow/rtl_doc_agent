# 能力与限制

本包是宿主AI驱动的验证平台生成agent，目标为块级UVM平台。四个子技能和本地工具可以协作完成工程任务，尚不是无人值守EDA产品。

| 能力 | 当前实现 | 结论边界 |
| --- | --- | --- |
| 输入与架构 | 总agent流程，默认prepared输入；Office/OCR用宿主或外部工具 | 转换出的事实仍需来源和语义核对 |
| BFM/TC生成 | agent子技能、输入输出schema、提示规则 | 没有独立确定性生成程序；输出generated不是编译通过 |
| 平台集成 | 两套legacy模板、骨架创建器及辅助脚本 | 创建器不实现协议，不自动完成env/top接线 |
| GEN/RM/checker/SVA/coverage | [组件编写流程](component-authoring.md)规定总agent职责 | 必须按目标协议实现；空模板不算完成 |
| UVM规范 | [生成合同](uvm-generation-contract.md)约束标准API/版本 | 模板有UVM1.1及外部库依赖，未验证IEEE1800.2兼容 |
| 静态门禁 | 已实现design/IR/platform/manifest结构与批准合同核对、源码散列 | 不是SV语义、elaboration或接线证明 |
| 运行证据 | 本地编译→仿真日志、test/seed与计划摘要、活动判定及聚合 | 本地pass仅表示证据符合合同，不认证真实DUT |
| 远端执行 | [SSH合同](ssh-backend-contract.md)，仿真器待定 | SSH适配器未实现；必须明确实际执行方式与证据 |
| 资产检查/打包 | doctor和release工具 | 验证目录/依赖/文件完整性，不证明EDA可用或分发授权 |

## 使用前必须解决的项目事实

真实RTL/top/filelist/includes/宏/参数；clock/reset及接口方向；接受/执行/完成/拒绝/取消事件；独立oracle；事务匹配/乱序/超时；覆盖目标；工具及UVM库身份。缺事实仅阻塞依赖项，保留全量计划与未决记录。

## 已知限制

1. legacy模板driver/monitor/RM存在注释占位，旧report/scoreboard可出现零活动假绿。必须实现行为并做正反例/故障注入验收。
2. Superbench依赖外部SUPERBENCH/CCL等工程设施；Gaea构建链含旧工具配置、路径和重复用例风险。发布包保留源模板，不承诺可直接编译。宿主会话快照和GUI布局已从模板剔除，目标环境应由profile重新生成配置。
3. 其他legacy辅助脚本主要基于字符串/正则，有错误传播与多顶层/extern处理局限；不能把退出0当成功。
4. static/run/aggregate目前独立，前置gate仍由总agent显式执行/绑定，非机器强制全流程。
5. 当前data/reject/reset计数公式需先确认适合协议；接受前拒绝、无数据写完成等情况不能硬凑指标。
6. 前后散列是变更检测，不是OS强制只读；同权限可伪造证据。可信身份与日志权限需独立部署。
7. coverage_samples非零不代表覆盖闭合；没有通用波形解码/失败聚类或自动覆盖闭合引擎。
8. 本地测试包含门禁、资产目录、创建器和打包反例；没有真实DUT/EDA验证。具体数量以本次执行报告为准。
9. [权利说明](../RIGHTS.md)中的来源许可未全部核实，不将候选包称为可公开开源分发的软件。

## 优先扩展

先验收一个真实SSH/仿真器/UVM/小DUT组合，证明有效比较与故障检测；再补typed组件IR及gate回执绑定、事务事件台账与重跑模型；按需求增加文档解析和更多工具profile。开源选型背景见[调研参考](opensource-integration.md)，不是已安装能力。
