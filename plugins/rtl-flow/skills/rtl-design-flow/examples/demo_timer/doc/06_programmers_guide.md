---
doc: 06_programmers_guide
ip: demo_timer
version: 1.1
status: Released
updated: 2026-10-22
owner: rtl-flow-example
---

# demo_timer 编程指南

示例代码使用自动生成的 `sw/demo_timer_regs.h`，并假设：

```c
#include <stdint.h>
#include "demo_timer_regs.h"
#define TIMER_BASE 0x40001000u   /* 由 SoC 地址映射决定 */
static inline void     wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(TIMER_BASE + off) = v; }
static inline uint32_t rd(uint32_t off)             { return *(volatile uint32_t *)(TIMER_BASE + off); }
```

## 1. 初始化 (Initialization)

1. 确认定时器处于停止状态：`CTRL.EN` = 0（复位后即为 0）。
2. 写 `INTR_STATE` = 1 清除可能残留的 `INTR_STATE.EXPIRED`。
3. 按需写 `INTR_ENABLE.EXPIRED` = 1 打开中断。

## 2. 典型操作流程 (Typical Operation)

定时 N 个时钟周期（N ≥ 1），`CMP.VAL` 写 N − 1：

```c
/* 单次定时 n 个周期 */
void timer_oneshot(uint32_t n) {
  wr(DEMO_TIMER_CTRL_REG_OFFSET, 0);                               /* 停止 */
  wr(DEMO_TIMER_CMP_REG_OFFSET, n - 1);
  wr(DEMO_TIMER_INTR_STATE_REG_OFFSET, 1u << DEMO_TIMER_INTR_STATE_EXPIRED_BIT);
  wr(DEMO_TIMER_CTRL_REG_OFFSET,
     (DEMO_TIMER_CTRL_MODE_VALUE_ONESHOT << DEMO_TIMER_CTRL_MODE_BIT) |
     (1u << DEMO_TIMER_CTRL_EN_BIT));                               /* 启动 */
}

/* 周期定时，每 n 个周期到时一次 */
void timer_periodic(uint32_t n) {
  wr(DEMO_TIMER_CTRL_REG_OFFSET, 0);
  wr(DEMO_TIMER_CMP_REG_OFFSET, n - 1);
  wr(DEMO_TIMER_CTRL_REG_OFFSET,
     (DEMO_TIMER_CTRL_MODE_VALUE_PERIODIC << DEMO_TIMER_CTRL_MODE_BIT) |
     (1u << DEMO_TIMER_CTRL_EN_BIT));
}
```

> 注意：停止 (`CTRL.EN` = 0) 不会清零 `COUNT.VAL`。需要从 0 重新计时时使用 `CTRL.CLR`：

```c
/* 计数清零：读-改-写，保持 EN/MODE 不变（DEC-005） */
void timer_restart(void) {
  uint32_t ctrl = rd(DEMO_TIMER_CTRL_REG_OFFSET);          /* CLR 读为 0 */
  wr(DEMO_TIMER_CTRL_REG_OFFSET, ctrl | (1u << DEMO_TIMER_CTRL_CLR_BIT));
}
```

## 3. 中断处理 (Interrupt Handling)

```c
void timer_isr(void) {
  if (rd(DEMO_TIMER_INTR_STATE_REG_OFFSET) & (1u << DEMO_TIMER_INTR_STATE_EXPIRED_BIT)) {
    wr(DEMO_TIMER_INTR_STATE_REG_OFFSET, 1u << DEMO_TIMER_INTR_STATE_EXPIRED_BIT);  /* 写 1 清除 */
    /* 用户处理 */
  }
}
```

`irq_o` 为电平中断，ISR 退出前必须清除 `INTR_STATE.EXPIRED`，否则会重复进入。轮询方式下可保持 `INTR_ENABLE.EXPIRED` = 0，直接读 `INTR_STATE`。

## 4. 错误处理 (Error Handling)

- 访问未映射或非对齐地址会返回 APB `pslverr`，处理器通常产生总线错误异常；读返回 0，写无效。
- 软件不应写 `COUNT`（只读），写入不会产生错误但无效果。

## 5. 注意事项 (Caveats)

- 定时周期为 `CMP.VAL` + 1 个周期，写 `CMP` 时注意减 1。
- 周期模式下 `CMP.VAL` = 0 会每周期置位中断状态，清除无效，应避免使用。
- 运行中把 `CMP.VAL` 改小到当前计数值以下会立即到时（≥ 比较）。
- 修改 `CMP.VAL` 时建议先停止定时器，避免中间态比较。
- 写 `CTRL` 时 bit 2 (`CLR`) 必须明确：直接写常量会同时改写 `EN`/`MODE`，清零操作必须读-改-写。
