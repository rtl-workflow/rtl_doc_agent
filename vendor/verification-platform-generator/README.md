# 验证平台生成 Agent

**1.0.0-rc.1 · 发布候选**

由宿主AI统筹需求与RTL分析、UVM架构、组件生成、平台集成、测试用例及证据验收。四个子skill按需调用；用户无需逐个选择。不是独立后台服务，也不包含已验收的SSH执行器或EDA仿真器。

## 快速开始

1. 解压候选包，保持目录结构。让支持本地指令文件的AI宿主读取 [SKILL.md](SKILL.md)；目录约定见 [AGENTS.md](AGENTS.md)。不同宿主的安装/注册机制自行配置，本包不隐式修改宿主。
2. 提供目标工程路径、需求、RTL/top/filelist、接口时序及测试点。生成物放独立工程目录，原始RTL默认只读。
3. 从包根目录使用Python 3.10+检查：

```powershell
python -B -m agent.doctor
python -B -m unittest discover -s tests -p 'test_*.py'
python -B -m bt_uvm --help
```

核心命令只需Python标准库。Excel读取等可选依赖和打包校验见 [RELEASE.md](RELEASE.md)。工具未配置时仍可完成无依赖的设计/代码，明确not_compiled。

示例请求：“根据项目RTL、接口说明和测试点生成UVM验证平台，保持RTL只读；先完成有效sanity，再扩展用例。远端工具未配置时交付源码和阻塞项。”

## 导航

| 入口 | 职责 |
| --- | --- |
| [总agent](SKILL.md) / [执行手册](references/agent-runbook.md) | 架构、任务路由、追溯、失败处理及交付 |
| [UVM合同](references/uvm-generation-contract.md) | 标准API、组件ABI、独立RM和有效比较要求 |
| [BFM子技能](logic-verify-uvm-bfm-gen/SKILL.md) | 接口、driver、monitor与协议行为 |
| [平台子技能](logic-verify-uvm-platform-gen/SKILL.md) | legacy模板、骨架创建器及agent集成 |
| [TC子技能](logic-verify-uvm-tc-gen/SKILL.md) | 从prepared或Excel测试点生成用例及追溯 |
| [RTL子技能](rtl-gen/SKILL.md) | 单独授权的DUT设计/修复 |
| [组件流程](references/component-authoring.md) | 总agent负责GEN/RM/checker/SVA/coverage |
| [门禁CLI](references/runtime-guide.md) | 已实现的本地结构、散列及运行证据判定 |
| [SSH合同](references/ssh-backend-contract.md) | 远端执行设计，尚无内置实现 |
| [能力与限制](references/capability-map.md) | 实际实现范围及legacy模板缺口 |
| [技能注册表](agent/registry.json) | 8项能力入口与依赖 |
| [项目状态](assets/project-state.example.json) / [交付模板](assets/handoff-template.md) | 工程记录；不是可直接执行的工作流 |

## 发布内容

包内保留运行入口、技能合同、源模板、Python工具与测试。历史J1–J8原文、项目评审、旧流程图、遥测配置、Python缓存、原宿主会话/GUI快照和仿真日志不随包发布。工作区清理时另作归档，不作为运行依赖。RTL子技能已去除重复目录层级。

打包器生成ZIP及逐文件SHA-256清单，可校验传输完整性；不会上传网络。发布版本和变化见 [CHANGELOG.md](CHANGELOG.md)。

**发布候选不等于公开开源授权或EDA验收通过。** 随包legacy模板和RTL规则的权利状态见 [RIGHTS.md](RIGHTS.md)。源码生成、真实编译、替身自检、真实DUT实测和计划闭合必须分别报告。
