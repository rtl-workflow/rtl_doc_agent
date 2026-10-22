---
doc: CHANGELOG
ip: demo_timer
version: 1.1
status: Released
updated: 2026-10-22
owner: rtl-flow-example
---

# 变更记录

格式参考 [Keep a Changelog](https://keepachangelog.com/)。只记录对外可见的变化（端口、寄存器、行为、时序、参数）。

## [Unreleased]

无。

## [1.1.0] - 2026-10-22

### Added
- `CTRL.CLR`（bit 2，只写，读为 0）：写 1 使计数值在下一周期归零（REQ-FUNC-006，DEC-005，ITR-005）。

### Changed
- 写 `CTRL` 时 bit 2 不再被忽略。旧软件写 `CTRL` 时 bit 2 为 0，行为不变。

## [1.0.0] - 2026-10-22

### Added
- 初始版本：APB3 从接口、32 bit 计数器、单次 / 周期模式、电平中断；寄存器 `CTRL`、`CMP`、`COUNT`、`INTR_STATE`、`INTR_ENABLE`。
