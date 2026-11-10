# IP 描述文件 Schema：`data/<ip>.yaml`

单一信息源，结构参考 OpenTitan 的 `ip.hjson`。支持 `.yaml` / `.yml` / `.json` / `.hjson`（后者需 `pip install hjson`）。`gen_docs.py` 会做校验，错误时退出码非 0。

## 顶层字段

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `name` | 是 | str | IP 原名，保留大小写，与目录名一致 |
| `version` | 是 | str | IP 版本，语义化版本 `x.y.z` |
| `desc` | 是 | str | 一句话描述 |
| `top` | 是 | str | 顶层模块名 |
| `rtl_files` | 是 | list[str] | RTL 文件（相对 IP 目录），即编译顺序：第一个必须是 `rtl/define.v`（rtl-coding-style HW-07），第二个是顶层所在文件 |
| `bus` | 否 | map | `protocol`（apb/ahb/axi4lite/tlul/wishbone/custom）、`data_width`（默认 32）、`addr_width` |
| `clocks` | 是 | list | 见下 |
| `resets` | 是 | list | 见下 |
| `params` | 否 | list | 见下 |
| `ports` | 是 | list | 顶层全部端口（**包括**时钟、复位、总线端口） |
| `interrupts` | 否 | list | 见下 |
| `registers` | 否 | list | 见下 |

## clocks[]
`name`（原始时钟名，如 `PCLK`）、`freq_mhz`（目标频率）、`desc`

## resets[]
`name`（原始复位名）、`active`（low/high）、`std_if`（bool，默认 false）、`type`（async / sync / async_assert_sync_deassert）、`clock`（关联时钟原名）、`desc`

复位分两类（rtl-coding-style HW-14、HW-41、HW-42）：
- **内部复位**（`std_if` 不写或为 false）：保留原名；全部内部复位极性相同，与 `rtl/define.v` 的 `RST_EDGE` / `RST_ACT` 一致。
- **标准接口复位**（`std_if: true`）：接口协议规定了极性，如 APB 的 `PRESETn`，保留原名；RTL 中直接写 `negedge PRESETn` / `if (PRESETn == 1'b0)`。不根据名称后缀推断极性。

## params[]
`name`（原始参数名，不限制大小写或20字符长度）、`type`（可选，如 `[7:0]`；不写时 Verilog 参数无类型）、`default`、`desc`、`local`（bool，localparam 为 true，不出现在端口参数表中）

## ports[]
| 字段 | 说明 |
|---|---|
| `name` | 原始端口名，保留大小写和前后缀；时钟、复位与 `clocks` / `resets` 中的名字一致 |
| `dir` | `input` / `output` / `inout` |
| `width` | 整数，或参数表达式字符串（如 `"DATA_WIDTH"`）；1 bit 写 1 |
| `clock` | 所属时钟域（异步信号写 `async`） |
| `desc` | 描述 |

端口必须按「输入 → 双向 → 输出」排列（与 RTL 一致，见 rtl-coding-style HW-30）。`gen_docs.py` 校验顺序，不施加命名风格。

`check_docs.py --stage rtl` 会把 `width: N` 对应到 RTL 中的 `[N-1:0]`，`width: "Expr"` 对应 `[Expr-1:0]`，1 对应无位宽。

## interrupts[]
`name`、`type`（event / status）、`desc`

## registers[]
| 字段 | 说明 |
|---|---|
| `name` | 原始寄存器名 |
| `offset` | 字节偏移，整数或 `"0x10"`，按 `data_width/8` 对齐，不得重复 |
| `desc` | 描述 |
| `fields` | 字段列表 |

### fields[]
| 字段 | 说明 |
|---|---|
| `name` | 原始字段名 |
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
rtl_files: [rtl/define.v, rtl/demo_timer.v]
bus: {protocol: apb, data_width: 32, addr_width: 12}
clocks:
  - {name: clk, freq_mhz: 100, desc: 主时钟}
resets:
  - {name: rst, active: low, type: async_assert_sync_deassert, clock: clk, desc: 主复位}
params:
  - {name: CNT_WIDTH, default: 32, desc: 计数器位宽}
ports:
  - {name: clk, dir: input, width: 1, clock: clk, desc: 主时钟}
  - {name: rst, dir: input, width: 1, clock: async, desc: 异步复位，低有效}
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
# 输入命名保留（可选）

所有名称原样保留。模块名与文件名不同时无需豁免；以下可选顶层字段仅用于追溯来源：

```yaml
source_naming:
  - module: SPI_WRAP
    file: rtl/spi_adapter.v
    source: raw/design.md §4（明确指定文件spi_adapter.v与模块SPI_WRAP）
```

该表由spec-author维护，架构§2同步记录名称来源。语法、单文件单模块等规则仍生效。未指定文件名时可用`<原模块名>.v`。生成C头文件时保留IP、寄存器、字段和枚举名称的大小写；组合宏使用这些原名，不再自动转为大写。
