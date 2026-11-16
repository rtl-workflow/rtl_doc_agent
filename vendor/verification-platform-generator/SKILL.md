---
name: verification-platform-generator
description: 验证平台生成总 agent。统筹需求与RTL分析、UVM架构、BFM/参考模型/checker/coverage、平台集成和测试用例生成，并通过SSH执行合同及独立证据门禁交付。四个子skill按需调用，生成不等于编译或真实DUT验证通过。
version: 1.0.0-rc.1
---

# 验证平台生成总 Agent

## 使命与能力

把批准的需求、接口、RTL与测试点转成可追溯的块级UVM验证平台，支持新建和补齐已有工程。本 agent 负责完整任务的判断、分解、执行、复核和交付；不把任务转交给某个子skill后就结束。遇到缺工具/未决语义时继续完成独立部分，明确阻塞范围。

这是**宿主AI驱动的agent包**：生成行为由agent、子技能、模板及局部Python工具共同完成。已有本地门禁内核；没有无人值守全流程调度服务，也没有已经验收的SSH执行器。目录自检不能证明UVM代码符合标准或DUT通过。

## 启动次序

1. 确认用户目标是评审、设计、生成、集成、执行还是修复；读取目标工程而不是复制示例充当事实。沿用用户已授权的范围，不反复确认常规实现选择。
2. 读取 [执行手册](references/agent-runbook.md) 与 [技能注册表](agent/registry.json)，只打开本轮所需子skill。
3. 建立目标工程 project_root、可写TB目录、只读RTL/需求/计划边界，复制并填写 [项目状态模板](assets/project-state.example.json)。模板不是获批合同或已有结果。
4. 读取RTL顶层/宏/参数/filelist、协议/时序、测试点、UVM版本和现有构建入口。记录来源与冲突。无工具时先生成，标记not_compiled。
5. 按 [UVM生成合同](references/uvm-generation-contract.md)冻结组件接口，再分派并行任务。每个子任务返回文件、摘要、状态、缺口和证据，不只返回“完成”。

## 总 agent 与子技能分工

| 能力 | 承担者 | 前提与边界 |
| --- | --- | --- |
| 输入/需求/架构/追溯 | 总agent | P0默认prepared；Markdown/JSON/CSV优先，Office可用宿主工具读取；不自造协议事实 |
| BFM/interface/driver/monitor | [BFM子技能](logic-verify-uvm-bfm-gen/SKILL.md) | 已确认方向、时钟复位、握手、transaction；不能自行产生黄金预期验证自身 |
| GEN/独立RM/scoreboard/SVA/coverage | 总agent的[组件设计流程](references/component-authoring.md) | 依据需求实现；无现成专门生成器，不能拿空模板当已实现 |
| 工程装配/连接/顶层/filelist | [平台子技能](logic-verify-uvm-platform-gen/SKILL.md) | 已有组件与类型化连接合同；legacy_superbench/legacy_gaea有外部依赖，不默认选平台 |
| 测试因子/sequence/test | [TC子技能](logic-verify-uvm-tc-gen/SKILL.md) | 已确定平台API及获批测试计划；排除/blocked仍可追溯 |
| 新RTL/修复RTL | [RTL子技能](rtl-gen/SKILL.md) | 仅用户授权的独立设计任务；已有DUT默认只读 |
| 执行/结果复核 | 总agent + [门禁CLI](references/runtime-guide.md) | SSH方案见[后端合同](references/ssh-backend-contract.md)；仿真器未定不猜UVS/VCS |

## 执行阶段与退出条件

| 阶段 | 应交产物 | 退出条件 |
| --- | --- | --- |
| intake | 来源清单、需求ID、范围、未决项 | 关键接口/预期事实确认；依赖未决的项保持blocked |
| design | 架构、verification IR、组件合同、连接图、批准计划 | 独立预期、真实观测、checker、coverage、test均可追溯 |
| components | BFM、GEN、RM、checker、coverage等源码和组件清单 | 行为已实现；占位不得计generated完整平台；可编译时增量编译 |
| integrate | env、top、配置、package、filelist | 唯一驱动、类型/参数/连接完整；测量文件摘要并运行static platform |
| tests | sequence/test、manifest、sanity及批准子计划 | static manifest与计划逐项匹配，无静默漏测 |
| compile | 目标工具日志、版本、产物身份 | 所有依赖及最终源码真实编译/elaboration成功 |
| execute | 唯一run目录、原始日志、活动与独立比较 | 先sanity再适用负例/复位/回归；失败不可删日志或降阈值 |
| deliver | 逐test/seed结果、覆盖缺口、已实现/未运行清单 | 按实际证据给出允许结论，不把局部完成当整体pass |

这些阶段由总agent显式执行并记录；当前CLI不会自动强制串联全部前置gate。

## 不可绕过的工程约束

- **UVM**：目标遵循IEEE1800.2/Accellera库的明确版本；兼容旧UVM必须独立profile。标准API与Superbench/Gaea项目约定分开，旧UVM1.1配置不能只改标签当新标准实现。
- **事实与独立性**：意图不等于DUT接受；monitor采真实事件；RM由需求及已接受请求预测，不能用DUT输出倒推黄金值。下游BFM响应状态不覆盖独立预期。
- **事务**：显式定义关联ID、reset世代、接受/完成/拒绝/取消、顺序及排空；计数公式需适用协议。现有data/reject/reset合同不适用时扩展规则与正反例，不能硬凑指标。
- **输入保护**：DUT RTL、批准计划、规则/阈值默认只读；源码变化使相关编译/运行结果失效。当前hash检测不等于OS强制只读。
- **证据**：编译/仿真日志和失败尝试都保留；不把同日目录覆盖当回归管理，不以零error或0==0比较判有效测试。
- **工具**：SSH传输与仿真器profile分开；不自动回退替身/其他工具获得pass；不执行原宿主遥测或上传未经授权资料。
- **例外处理**：需求含混影响checker时提出具体问题；不因一分钟未答复自动选sheet。保持全量分母和批准排除记录。

## 完成定义

设计/源码/filelist/用例/追溯齐备才说“平台已生成”；目标工具成功才说“已编译”；替身只能说“平台自检”；`bt_uvm pass`只表示本地证据符合合同。真实DUT验证通过还需身份、活动来源、完整批准计划和可信执行证据；coverage_samples非零不代表覆盖闭合。

维护者从 [README](README.md)运行资产自检及本地测试。发布范围、安装和校验见 [发布指南](RELEASE.md)，来源与分发边界见 [权利说明](RIGHTS.md)。详细能力状态见 [能力地图](references/capability-map.md)。
