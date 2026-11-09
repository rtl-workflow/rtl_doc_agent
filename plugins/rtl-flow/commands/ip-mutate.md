---
description: 对 IP 做变异测试，向 RTL 注入单点缺陷，检查测试平台能否发现
argument-hint: "<ip_dir> [--max N] [--jobs N]"
---

使用 rtl-design-flow skill，处理以下输入：

$ARGUMENTS

1. 运行 `python $SKILL/scripts/run_mutation.py <ip_dir> [选项]`。可能耗时较长，放到后台运行。
2. 汇报变异得分，并逐条列出存活的变异体（`reports/mutation.json`）。
3. 存活的变异体可能是测试平台的漏洞，也可能是等价变异（行为不变），逐条给出你的判断和依据，由我决定如何处理。
4. 结果含 RTL 内容，不要转给 tb-engineer；需要补充用例时，只用规格层面的语言描述缺失的检查。
5. 脚本以 `ERROR:` 结束属于基线回归失败或环境问题，不要为此修改 RTL 或测试平台。
