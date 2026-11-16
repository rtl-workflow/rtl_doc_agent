# 验证平台生成总 Agent

本目录是一个由宿主 AI 执行的总 agent 包。先读 [主入口](SKILL.md)，按 [执行手册](references/agent-runbook.md)调度 [技能注册表](agent/registry.json)。不是常驻服务，也不声称已经有自动执行全部步骤的调度器。

## 工作边界

- 本目录是工具/技能资产；目标工程使用独立 project_root。生成物放目标工程的获准目录，不能把示例工程当真实 DUT。
- 用户当前请求决定执行范围：评审只读、生成可写TB、执行才连接已配置SSH；修复DUT或生成新RTL属于单独设计任务。
- 总 agent 负责需求、架构、独立参考模型、checker/coverage设计、追溯、调度与结论；BFM、平台、TC、RTL是子技能，按需读取，不一次加载所有示例。
- 修改前读文件；并行代理使用不重叠文件范围。接口合同先冻结，再并行实现组件；集成与全量编译必须在组件完成后执行。
- 子技能不能覆盖总项目的只读边界、批准测试计划、UVM版本或SSH profile。原包的遥测、静默跳过、覆盖日志、固定UVS约定不生效。
- 任何生成或编译状态都不能自动提升为真实DUT验证通过。保留原始日志、失败尝试和变更摘要。编译后改代码必须重编译。
- 不自动执行模板中shell、网络上传、安装依赖或遥测。执行项目配置中的已审核命令；缺工具时完成可做的生成并标明未编译。

## 开发与检查

从此目录运行 `python -B -m agent.doctor` 检查注册表及入口文件，运行 `python -B -m unittest discover -s tests -p 'test_*.py'` 检查本地软件。doctor仅验证资产结构，不证明UVM语义、EDA环境或远端联通。

生成流程参见 [UVM合同](references/uvm-generation-contract.md)、[项目状态模板](assets/project-state.example.json)、[SSH合同](references/ssh-backend-contract.md)。实际已实现的门禁CLI参见 [运行指南](references/runtime-guide.md)。历史四包审查与旧J1–J8材料仅用于追溯，不作为当前执行规范。
