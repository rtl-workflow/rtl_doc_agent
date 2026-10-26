---
description: 列出 rtl-flow 多 agent 流程中的全部角色 agent 及其职责、负责阶段、可用工具
---

读取 `${CLAUDE_PLUGIN_ROOT}/agents/` 下的每个 `.md` 文件（只看 frontmatter 和开头的职责说明），用一张表汇报给我：agent 名称（调用名为 `rtl-flow:<name>`）、负责阶段、主要产出、可用工具、模型。表后用一句话说明编排者由主会话通过 `flow.py` 担任，不是单独的 agent。不要修改任何文件，也不要派发 agent。
