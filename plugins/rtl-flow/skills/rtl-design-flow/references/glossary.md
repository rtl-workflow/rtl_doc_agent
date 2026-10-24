# 术语表 (Glossary)

> 团队可直接在本文件追加术语。所有文档必须使用「标准用语」列，避免「禁用同义词」列。

## 1. 通用术语

| 标准用语 | 英文 | 禁用同义词 | 说明 |
|---|---|---|---|
| 复位 | reset | 重置、清零（指复位时） | |
| 异步复位同步释放 | async assert, sync deassert | | 默认复位方案 |
| 时钟域 | clock domain | | |
| 跨时钟域 | CDC (clock domain crossing) | 跨时钟 | |
| 周期 | cycle | 拍、个时钟 | 注明所属时钟 |
| 握手 | handshake | | valid/ready 等 |
| 背压 | backpressure | 反压 | |
| 吞吐率 | throughput | | 单位：数据/周期 或 bit/s |
| 延迟 | latency | 时延 | 单位：周期 |
| 拉高 / 拉低 | assert high / low | 置 1 / 置 0（指信号有效） | |
| 有效 / 无效 | asserted / deasserted | | |
| 置位 / 清零 | set / clear | | 指寄存器位 |
| 中断 | interrupt | | |
| 软件 | software (SW) | 固件（除非确指固件） | |
| 硬件 | hardware (HW) | | |
| 测试点 | test point | 测试项 | |
| 待定 | TBD | 待补充、暂定 | 必须写作 `TBD(Q-xxx)` |

## 2. 信号命名前缀 / 后缀（华为 Verilog 编码规范，详见 rtl-coding-style §2）

| 前缀 / 后缀 | 含义 | 示例 |
|---|---|---|
| `i_` | 模块输入 | `i_data` |
| `o_` | 模块输出 | `o_irq` |
| `io_` | 双向 | `io_sda` |
| `clk` / `clk_<domain>` | 时钟（端口不加 `i_`） | `clk`, `clk_apb` |
| `rst_n` / `rst_<domain>_n` | 低有效复位（端口不加 `i_`） | `rst_n`, `rst_apb_n` |
| `_n` | 低有效 | `o_cs_n` |
| `_z` | 三态输出寄存器 | `sda_out_z` |
| `_r` / `_r1`、`_r2` | 时序寄存器 / 打拍 | `cnt_r`, `req_r1` |
| `_en` / `_we` | 使能 / 写使能 | `cnt_en` |
| `_sync` | 已同步到本时钟域 | `req_sync` |
| `cur_state` / `nxt_state` | FSM 当前状态 / 次态 | |
| `ST_` | FSM 状态编码（`localparam`） | `ST_IDLE` |
| `U_` | 例化名 | `U_core`, `U_sync_0` |
| 全大写 | `parameter` / `localparam` / `` `define ``，不超过 20 字符 | `DATA_WIDTH` |

## 3. 寄存器软件访问类型 (swaccess)

| 类型 | 读 | 写 | 说明 |
|---|---|---|---|
| `ro` | 返回值 | 忽略 | 只读，硬件更新 |
| `rw` | 返回值 | 写入 | 读写 |
| `wo` | 返回 0 | 写入 | 只写 |
| `rc` | 返回值，读后清零 | 忽略 | 读清 |
| `rw1c` | 返回值 | 写 1 清零，写 0 无影响 | 常用于中断状态 |
| `rw1s` | 返回值 | 写 1 置位，写 0 无影响 | |
| `rw0c` | 返回值 | 写 0 清零，写 1 无影响 | |
| `r0w1c` | 返回 0 | 写 1 清零 | |

## 4. 寄存器硬件访问类型 (hwaccess)

| 类型 | 说明 |
|---|---|
| `hro` | 硬件只读（软件配置） |
| `hrw` | 硬件可读可写（如状态位由硬件置位） |
| `hwo` | 硬件只写（状态反馈） |
| `none` | 硬件不访问 |

## 5. 优先级

| 级别 | 含义 |
|---|---|
| P0 | 必须实现，缺失则不可交付 |
| P1 | 应实现，可协商延期 |
| P2 | 可选 |
