---
description: 处理一次验证失败或需求变更：由 debugger 定位或 spec-author 变更，按多 agent 流程修改、重开审核并回归
argument-hint: "<ip_dir> <失败现象 / 变更内容>"
---

使用 rtl-design-flow skill，以**编排者**身份（skill §4）处理：$ARGUMENTS

1. 判断这是**验证失败 / 问题报告**（kind=failure）还是**需求变更**（kind=change）；无法判断时问我。
2. 把描述原样写入 `<ip_dir>/.flow/inputs/` 下的一个新文件，运行
   `python $SKILL/scripts/flow.py iter <ip_dir> --kind failure|change --file <该文件>`。
3. 进入编排循环：反复运行 `flow.py next <ip_dir>` 并按输出的 action 执行，直到 finish。
   - failure：debugger 定位根因 → rtl-engineer / tb-engineer 修复 → 回归；根因为规格问题时会上报给我决定。
   - change：spec-author 修改 00 → 01 → yaml → 已审核文档提升 version 后重开审核 → architect（如受影响）→ rtl-engineer ‖ tb-engineer → 回归。
4. 你只做调度和与用户交互，不亲自修改文档、RTL 或 testbench。
