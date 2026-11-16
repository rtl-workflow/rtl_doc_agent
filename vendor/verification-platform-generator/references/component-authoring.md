# 总 agent 的组件编写流程

这是总agent原生职责的工作手册，不是额外已实现的自动生成器。BFM、平台、TC之间缺少的GEN/RM/checker/SVA/coverage由此负责，不等待不存在的第五个外部skill。

## 1. 固定组件规格

从批准需求和接口事实生成每个组件规格：purpose、requirement_ids、inputs、outputs、state、reset、timing、configuration、dependencies、error_policy、observability、completion。输入输出必须有类型、方法签名和事件语义；字段引用[UVM合同](uvm-generation-contract.md)。所有推断和未决项标注，不当作已经批准。

## 2. GEN与transaction

定义协议合法请求、约束和错误注入开关；GEN/sequence仅产生刺激意图，不增加accepted计数。共用transaction字段先确定，不能分别在BFM/RM/TC生成冲突定义。覆盖合法最小/最大边界、反压与并发，配置以项目事实为准，不能固定512通道或网络包长。

## 3. 独立RM

以已观测接受事件而非driver意图推进预期状态；从需求状态机/算法建立oracle，记录每条规则来源。输出期望事务及关联键，不消费DUT实际返回修正期望。必要的物理/下游响应模型与oracle保持状态分离。算法存在未决项时阻塞该checker，仍可生成其他接口结构。

## 4. Scoreboard/checker

expected和actual分别经明确端口输入。按ID、顺序约束和reset世代匹配；查missing/duplicate/unexpected/wrong-owner/data-error/timeout。结束时排空并验证未完成事务；不能只比较累计数量，不能接受0==0作为有效数据sanity。声明支持的并发和乱序范围，不将单流模板默认为通用金标准。

## 5. SVA与coverage

每条assertion绑定协议或时序要求，声明时钟、reset禁用条件、未知值策略和允许延迟。coverage基于真实采样事件，coverpoints/cross有需求映射、目标及排除项；不以采样次数替代覆盖闭合。SVA/coverage语言特性必须经目标工具profile验证。

## 6. 组件自检与集成

对组件准备最小正例/反例，能用真实工具则执行并保留日志；只有静态检查时明确not_compiled。至少验证正常匹配、错误数据、丢重事务、reset在途及纯monitor模式等适用场景。模型替身自检不作为真实DUT结果。

交付清单：源码、组件合同、依赖filelist、输入/输出/TLM ABI、已实现状态、测试向量或用例、实际运行记录、未决项。满足清单后交平台技能，完成env/top接线后再交TC技能扩展计划。任何修改共享transaction/配置方法的补丁都需要重核下游组件。
