---
description: 重新生成接口/寄存器文档并按指定阶段检查 IP 文档
argument-hint: "<ip_dir> [req|spec|arch|rtl|dv|signoff]"
---

使用 rtl-design-flow skill 对 IP 做文档检查。参数：$ARGUMENTS

1. 运行 skill 的 `scripts/gen_docs.py <ip_dir>`；阶段为 rtl 及以后时再运行 `scripts/run_lint.py <ip_dir>`。
2. 运行 `scripts/check_docs.py <ip_dir> --stage <阶段>`（未给阶段时按 IP 当前进度判断：有 RTL 用 rtl，有 TP 用 dv）。
3. 逐条修复 ERROR（不得通过删除必填章节或 ID 来规避）；无法自行修复的列出并说明原因。审核类 ERROR（not approved / re-review required）不得自行填写 `approved` 消除，应列出并请我审核。
4. 最后报告：ERROR/WARN 数量变化、修改了哪些文件。
