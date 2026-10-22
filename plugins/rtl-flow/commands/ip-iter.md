---
description: 处理一次验证失败或需求变更，按 P5 迭代规则修改并记录 ITR
argument-hint: "<ip_dir> <失败现象 / 变更内容>"
---

使用 rtl-design-flow skill 的 P5 迭代流程处理：$ARGUMENTS

1. 分析根因并归类（Spec 错误 / 需求变化 / RTL bug / TB bug / 工具问题）。
2. 按根因类别规定的顺序修改文档、yaml、RTL、DV。
   若修改了已审核的 00 / 01 / 02（提升 version），先改完这些文档并提交我审核，通过后更新 `approved` 再改 yaml / RTL。
3. 在 `doc/08_iteration_log.md` 新增 ITR（必要时新增 BUG、DEC），对外可见变化写入 `CHANGELOG.md`。
4. 运行 gen_docs.py、run_lint.py（改了 RTL 时）、check_docs.py --stage dv 和回归，把结果写回 ITR。
