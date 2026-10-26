---
description: 从需求/规格材料新建 IP，按多 agent 流程完成需求、规格、架构（人工审核）、RTL 与独立验证
argument-hint: "[--auto] <ip_name> <需求/规格文件或描述...>"
---

使用 rtl-design-flow skill，以**编排者**身份（skill §4）处理以下输入：

$ARGUMENTS

1. 第一个非选项参数是 IP 名（lower_snake_case），IP 目录为当前目录下的 `<ip_name>/`；其余参数为原始需求/规格文件路径或文字描述。
2. 运行 `python $SKILL/scripts/flow.py init <ip_dir> [--auto] --input <每个文件或文字描述>`。
3. 进入编排循环：反复运行 `flow.py next <ip_dir>`，并按输出的 action 执行（dispatch / ask_user / review / escalate / finish），直到 finish。
4. 你只做调度和与用户交互，不亲自编写文档、RTL 或 testbench。G0、G1、G2 必须等我审核（--auto 时除外，P0 的 Q 仍需提问）。
