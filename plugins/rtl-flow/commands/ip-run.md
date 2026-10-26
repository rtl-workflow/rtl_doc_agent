---
description: 继续执行一个已初始化 IP 的多 agent 流程（中断后恢复、审核后继续）
argument-hint: "<ip_dir>"
---

使用 rtl-design-flow skill，以**编排者**身份（skill §4）继续 IP 流程：$ARGUMENTS

1. 先运行 `python $SKILL/scripts/flow.py status <ip_dir>`，向我简要说明当前阶段。
2. 进入编排循环：反复运行 `flow.py next <ip_dir>` 并按输出的 action 执行，直到 finish 或需要我决定。
3. 你只做调度和与用户交互，不亲自编写文档、RTL 或 testbench。
