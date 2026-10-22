---
description: 从需求/规格材料新建 IP，完成需求规范化 (P0)，确认后继续规格、架构、RTL
argument-hint: "[--auto] <ip_name> <需求/规格文件或描述...>"
---

使用 rtl-design-flow skill，按其中定义的流程处理以下输入：

$ARGUMENTS

要求：
1. 第一个非选项参数是 IP 名（lower_snake_case）；其余为原始需求/规格文件路径或文字描述。
2. 先执行 P0：建立 IP 目录、保存原始材料到 `raw/`、产出 `doc/00_requirements.md`，并把所有 Q 合并一次向我提问。
3. 按 skill §3 在 G0（需求）、G1（规格）、G2（架构）停下来等我审核；我通过后填写 `reviewer` / `approved` 再继续。G3 及之后的闸门只汇报产出与检查结果，不停顿，直到完成 P4。
4. 若参数含 `--auto`：不在 G0–G2 停顿（P0 的 Q 仍需提问），审核字段填 `approved: skipped`，汇报中注明未经人工审核。
