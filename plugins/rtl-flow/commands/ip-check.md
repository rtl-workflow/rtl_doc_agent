---
description: 重新生成接口/寄存器文档并按指定阶段检查 IP 文档
argument-hint: "<ip_dir> [req|spec|arch|rtl|dv|signoff]"
---

使用 rtl-design-flow skill 对 IP 做文档检查。参数：$ARGUMENTS

1. 运行 skill 的 `scripts/gen_docs.py <ip_dir>`；阶段为 rtl 及以后时再运行 `scripts/run_lint.py <ip_dir>`。
2. 运行 `scripts/check_docs.py <ip_dir> --stage <阶段>`（未给阶段时按 IP 当前进度判断：有 RTL 用 rtl，有 TP 用 dv）。
3. 如果 `<ip_dir>/.flow/state.json` 存在（IP 由多 agent 流程管理）：**不要自己修改文件**，只汇报 ERROR / WARN 及其归属角色（00/01/06/yaml → spec-author，02/09 → architect，rtl/05/lint → rtl-engineer，07/dv → tb-engineer），并建议用 `/rtl-flow:ip-run` 继续流程或用 `/rtl-flow:ip-iter` 处理问题。签核阶段需要手工修改时，先征得我同意再运行 `flow.py guard <ip_dir> off`，改完后恢复为 on。
4. 不是多 agent 流程管理的 IP：逐条修复 ERROR（不得通过删除必填章节或 ID 来规避）；无法自行修复的列出并说明原因。
5. 审核类 ERROR（not approved / re-review required）不得自行填写 `approved` 消除，应列出并请我审核。
6. 最后报告：ERROR/WARN 数量变化、修改了哪些文件。
