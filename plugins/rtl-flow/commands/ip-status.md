---
description: 查看 IP 多 agent 流程的当前阶段、审核点状态、正在运行的 agent 和最近事件
argument-hint: "<ip_dir>"
---

使用 rtl-design-flow skill，运行 `python $SKILL/scripts/flow.py status $ARGUMENTS`，把结果简要汇报给我：当前阶段、各审核点状态（是否需要重新审核）、是否有上报待我决定的问题、最近一次回归结果。不要执行 `flow.py next`，也不要修改任何文件。
