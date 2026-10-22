---
doc: 05_rtl_structure
ip: {{ip}}
version: 0.1
status: Draft
updated: {{date}}
owner: {{owner}}
---

# {{ip}} RTL 代码架构

## 1. 文件清单 (File List)

| 文件 | 模块 | 说明 |
|---|---|---|
| `rtl/{{ip}}.sv` | `{{ip}}` | 顶层 |

## 2. 模块层次 (Hierarchy)

```text
{{ip}}
├── u_reg_top   ({{ip}}_reg_top)
└── u_core      ({{ip}}_core)
```

## 3. 模块职责与接口 (Module Responsibilities)

### 3.1 {{module}}

- 职责：{{职责}}
- 对应架构：02_architecture §{{x}}
- 关键信号：{{信号及含义}}

## 4. 参数传递 (Parameters)

| 参数 | 定义位置 | 传递到 | 说明 |
|---|---|---|---|

## 5. 编译与文件顺序 (Compile Order)

```text
rtl/{{ip}}_pkg.sv
rtl/{{ip}}.sv
```

## 6. 编码约定与偏离 (Conventions & Deviations)

遵循 `rtl-coding-style.md`。偏离项：

| 位置 | 偏离内容 | 原因 | DEC |
|---|---|---|---|

## 7. Lint 豁免 (Lint Waivers)

| 工具 | 规则 | 位置 | 原因 |
|---|---|---|---|
