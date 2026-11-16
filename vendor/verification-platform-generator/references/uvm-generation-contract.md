# UVM 代码生成合同

适用于总agent及所有生成子技能。目标是正确使用选定UVM库和协议行为，不以文件名、继承关系或模板编译冒充符合性。

## 标准与profile

- 新设计以IEEE1800.2及明确版本的Accellera参考库/API为目标，记录库来源、版本与摘要。目标标准不是已完成认证声明。
- 现有Superbench/Gaea模板包含UVM1.1及外部库假设，标记legacy profile。保留/升级取决于工程环境，不自动覆盖为UVM1.2或1800.2；升级后全量编译和行为回归。
- UVM标准未规定GEN/BFM/RM目录布局，也未要求每个test覆写全部phase。只覆写实际需要的phase，正确调用super及objection生命周期。
- 仿真器profile必须声明SV classes、随机约束、UVM、SVA、DPI、coverage等必要能力。工具能编译Verilog不代表能运行本平台。

## 组件ABI

每个组件合同列出ID、责任、class/package/filelist、参数和transaction类型、依赖、配置字段及config_db路径、virtual interface、TLM端口名称/类型/方向、clock/reset、active/passive、允许驱动信号、完成与排空条件。连接双方在生成前引用同一份合同；不能由各自独立猜测字段。

标准型实现可使用：uvm_sequence_item、typed uvm_sequence/sequencer/driver、uvm_monitor、uvm_agent、uvm_env、uvm_test及analysis port/imp/fifo。既有框架合法使用uvm_component和get/peek/put端口也允许，但需明确适配映射，不因类名不同判错误。

## 生成顺序与检查

| 产物 | 必须实现/核查 |
| --- | --- |
| interface/clocking/modport | 信号位宽/类型/方向、采样时序、reset极性、单一驱动者；不得对所有信号统一置0 |
| item/config/package | 字段、约束、合法范围、对象创建与复制规则、factory注册、编译顺序 |
| driver/sequencer/GEN | 请求握手、反压/错误、reset中止；取item与完成通知配对；发送意图和真实接受分开 |
| monitor/agent | 独立采真实事件；不驱动DUT信号；active/passive及输出端口各模式连通 |
| RM/scoreboard | 需求驱动的独立预测、匹配ID/reset世代、允许乱序、丢失/重复/超时/排空、有效比较 |
| SVA/coverage | 每条绑定需求与采样事件；reset disable/未知值策略；覆盖目标与排除理由 |
| env/top | build/connect、virtual interface/config_db、factory override、DUT实例、clock/reset与所有实际连接 |
| sequence/test | 已批准场景、config与刺激、objection、有限时长、结束判据；test不重写checker阈值 |
| filelist/profile | 宏/includes/包顺序/UVM库/外部VIP、编译与运行参数、工具版本、可复现入口 |

固定模板只保证结构复用。空任务、TODO、全注释驱动/monitor、空DUT实例或无实际比较须标 `scaffold`，不能作为完整generated平台。

## 行为与证据验收

- sanity：真实DUT至少一次合法接受、完成观测和独立比对；如果场景本就没有数据比较，合同须定义对应的协议/取消判据。
- 负例：单因素错误必须明确预期检测；恢复路径有观测；预期失败不能通过删除UVM_ERROR或忽略整段日志实现。
- reset：清理模型/队列与世代，明确在途请求取消和恢复；旧世代返回不能匹配新请求。
- 接线自证：故意断开monitor/scoreboard或翻转数据必须失败；检查纯monitor模式、主动模式和多实例配置。
- 当前BT_METRIC来自真实组件的活动统计，不能由包装命令打印常数。v1计数契约不适用协议时提出版本化扩展，不能把未接受请求硬计accepted。
- 每次最终源码变更都失效编译证据。保留编译/仿真日志、工具/库/RTL/TB摘要；尚无工具的产物标not_compiled。

## 编辑权限

刺激/测试实现可写；DUT、批准计划和验收阈值默认只读。RM/checker按确认的规格实现，修复时记录原因并独立审阅，不允许因失败直接放宽预期。生成代码和判断代码在同权限环境仍可能被篡改，实际可信边界必须由部署权限提供。
