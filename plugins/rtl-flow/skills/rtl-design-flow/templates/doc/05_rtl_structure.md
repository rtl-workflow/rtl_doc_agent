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
| `rtl/{{ip}}.v` | `{{ip}}` | 顶层 |

## 2. 模块层次 (Hierarchy)

```text
{{ip}}
├── U_reg   ({{ip}}_reg)
└── U_core  ({{ip}}_core)
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
rtl/{{ip}}.v
rtl/{{ip}}_reg.v
rtl/{{ip}}_core.v
```

## 6. 编码约定与偏离 (Conventions & Deviations)

遵循 `rtl-coding-style.md`（华为 Verilog 编码规范）。偏离项（引用规则编号 HW-xx）：

| 位置 | 规则 | 偏离内容 | 原因 | DEC |
|---|---|---|---|---|

## 7. Lint 豁免 (Lint Waivers)

| 工具 | 规则 | 位置 | 原因 |
|---|---|---|---|
