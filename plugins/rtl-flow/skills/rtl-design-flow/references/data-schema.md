# IP 描述文件 Schema：`data/<ip>.yaml`

单一信息源，结构参考 OpenTitan 的 `ip.hjson`。支持 `.yaml` / `.yml` / `.json` / `.hjson`（后者需 `pip install hjson`）。`gen_docs.py` 会做校验，错误时退出码非 0。

## 顶层字段

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `name` | 是 | str | IP 名，小写 snake_case，与目录名一致 |
| `version` | 是 | str | IP 版本，语义化版本 `x.y.z` |
| `desc` | 是 | str | 一句话描述 |
| `top` | 是 | str | 顶层模块名 |
| `rtl_files` | 是 | list[str] | RTL 文件（相对 IP 目录），顶层所在文件放第一个 |
| `bus` | 否 | map | `protocol`（apb/ahb/axi4lite/tlul/wishbone/custom）、`data_width`（默认 32）、`addr_width` |
| `clocks` | 是 | list | 见下 |
| `resets` | 是 | list | 见下 |
| `params` | 否 | list | 见下 |
| `ports` | 是 | list | 顶层全部端口（**包括**时钟、复位、总线端口） |
| `interrupts` | 否 | list | 见下 |
| `registers` | 否 | list | 见下 |

## clocks[]
`name`（以 `clk` 开头，如 `clk`、`clk_apb`）、`freq_mhz`（目标频率）、`desc`

## resets[]
`name`（以 `rst` 开头；低有效以 `_n` 结尾，如 `rst_n`）、`active`（low/high）、`type`（async / sync / async_assert_sync_deassert）、`clock`（关联时钟）、`desc`

## params[]
`name`（全大写 UPPER_SNAKE_CASE，不超过 20 字符）、`type`（可选，如 `[7:0]`；不写时 Verilog 参数无类型）、`default`、`desc`、`local`（bool，localparam 为 true，不出现在端口参数表中）

## ports[]
| 字段 | 说明 |
|---|---|
| `name` | 端口名，小写；输入 `i_`、输出 `o_`、双向 `io_` 前缀；时钟、复位端口用 `clocks` / `resets` 中的名字，不加前缀 |
| `dir` | `input` / `output` / `inout` |
| `width` | 整数，或参数表达式字符串（如 `"DATA_WIDTH"`）；1 bit 写 1 |
| `clock` | 所属时钟域（异步信号写 `async`） |
| `desc` | 描述 |

端口必须按「输入 → 双向 → 输出」排列（与 RTL 一致，见 rtl-coding-style HW-30）。`gen_docs.py` 校验上述命名与顺序。

`check_docs.py --stage rtl` 会把 `width: N` 对应到 RTL 中的 `[N-1:0]`，`width: "Expr"` 对应 `[Expr-1:0]`，1 对应无位宽。

## interrupts[]
`name`、`type`（event / status）、`desc`

## registers[]
| 字段 | 说明 |
|---|---|
| `name` | 大写 `UPPER_SNAKE` |
| `offset` | 字节偏移，整数或 `"0x10"`，按 `data_width/8` 对齐，不得重复 |
| `desc` | 描述 |
| `fields` | 字段列表 |

### fields[]
| 字段 | 说明 |
|---|---|
| `name` | 大写 |
| `bits` | `"7:0"` 或 `"3"` |
| `swaccess` | 见 glossary §3 |
| `hwaccess` | 见 glossary §4 |
| `resval` | 复位值（整数或 `"0x.."`），必须能放进位宽 |
| `desc` | 描述 |
| `enum` | 可选，`[{value: 0, name: IDLE, desc: ...}]` |

字段之间不得重叠，不得超出 `data_width`。

## 最小示例

```yaml
name: demo_timer
version: 0.1.0
desc: 32 bit 可编程定时器，计数到比较值时产生中断。
top: demo_timer
rtl_files: [rtl/demo_timer.v]
bus: {protocol: apb, data_width: 32, addr_width: 12}
clocks:
  - {name: clk, freq_mhz: 100, desc: 主时钟}
resets:
  - {name: rst_n, active: low, type: async_assert_sync_deassert, clock: clk, desc: 主复位}
params:
  - {name: CNT_WIDTH, default: 32, desc: 计数器位宽}
ports:
  - {name: clk, dir: input, width: 1, clock: clk, desc: 主时钟}
  - {name: rst_n, dir: input, width: 1, clock: async, desc: 低有效复位}
  - {name: o_irq, dir: output, width: 1, clock: clk, desc: 定时到中断}
interrupts:
  - {name: expired, type: event, desc: 计数值等于比较值}
registers:
  - name: CTRL
    offset: 0x0
    desc: 控制寄存器
    fields:
      - {name: EN, bits: "0", swaccess: rw, hwaccess: hro, resval: 0, desc: 计数使能}
```
