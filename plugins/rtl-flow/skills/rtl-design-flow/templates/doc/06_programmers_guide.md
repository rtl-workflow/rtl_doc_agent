---
doc: 06_programmers_guide
ip: {{ip}}
version: 0.1
status: Draft
updated: {{date}}
owner: {{owner}}
---

# {{ip}} 编程指南

## 1. 初始化 (Initialization)

1. {{步骤，引用寄存器写作 `REG.FIELD`}}

## 2. 典型操作流程 (Typical Operation)

```c
// 示例代码使用生成的 sw/{{ip}}_regs.h
```

## 3. 中断处理 (Interrupt Handling)

{{中断使能、查询、清除顺序。}}

## 4. 错误处理 (Error Handling)

{{错误状态如何读取、如何恢复。}}

## 5. 注意事项 (Caveats)

{{访问顺序限制、需要等待的周期数等。}}
