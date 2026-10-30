# RTL 编码规范 (RTL Coding Style)

> 以华为 Verilog 编码规范（2001 版，71 条）为基线整理，结合 Cummings SNUG 系列论文的赋值与 FSM 规则补充。团队可按自身规范覆盖本文件。
> 规则编号 `HW-xx` 供评审、lint 报告与 `05_rtl_structure.md` §6「编码约定与偏离」引用。**标「自动」的规则由 `run_lint.py` 检查，违反即 lint error。**
> 情态词：`必须`（强制）/ `应`（推荐，偏离须在 05 §6 写明原因，重要偏离记 DEC）。

## 1. 语言与文件

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-01 | RTL 必须使用可综合 Verilog-2001（IEEE 1364-2001），唯一例外是 `$clog2`（来自 1364-2005，用法见 HW-61）。禁止 SystemVerilog 语法：`logic`、`bit`、`always_ff`、`always_comb`、`always_latch`、`typedef`、`enum`、`struct`、`interface`、`package`、`import`、`unique`、`priority`、`'0`/`'1`、`++`/`+=`、`.name` 隐式端口连接；禁止 Verilog-2005 新增的 `uwire` | 自动 |
| HW-02 | 一个文件只包含一个模块；文件名 = 模块名，后缀 `.v`（`define.v` 不含模块，见 HW-07） | 自动 |
| HW-03 | 每个文件（不含 `define.v`）第一行必须是 `` `timescale 1ns / 1ps `` | 自动 |
| HW-04 | 每个文件开头必须有文件头（格式见 §8），写明文件名、模块名、功能、版本、日期；`define.v` 不写模块名 | 自动（检查 `Module name` / `Function` / `Version` / `Date` 字段） |
| HW-05 | RTL 中不使用 `` `include ``；宏只在 `define.v` 中定义（HW-07），模块常量用 `parameter` / `localparam` 在模块内定义 | 自动 |
| HW-06 | 不使用 Verilog / VHDL / SystemVerilog 保留字作为名字 | lint |
| HW-07 | 全部宏定义放在一个 `rtl/define.v` 文件中：该文件只包含 `` `define ``，不包含模块或任何功能逻辑；其他 RTL 文件不得出现 `` `define `` / `` `undef ``。`define.v` 必须是编译列表（`data/<ip>.yaml` 的 `rtl_files`）的第一项，后续文件靠编译顺序看到这些宏。`define.v` 必须定义 `RST_EDGE`、`RST_ACT`、`U_DLY`（见 §1.1） | 自动 |
| HW-08 | 比较基础、多个模块可以共用的功能（如同步器、FIFO、计数器）应做成基础重用模块，有效代码应小于 500 行；功能大的要拆分 | 评审 |
| HW-09 | 基础重用模块与包封模块（HW-36）以外的普通模块，有效代码应控制在 300 ~ 1000 行：超过 1000 行拆分，不足 300 行应合并或在 05 §6 说明原因 | 评审 |

有效代码行：扣除空行、纯注释行、端口定义、信号与参数声明（`reg` / `wire` / `parameter` / `localparam`）、模块例化之后剩下的行数。

### 1.1 define.v

```verilog
//==============================================================================
// File name   : define.v
// Function    : 全局宏定义：复位极性、仿真延时
// Version     : 1.0
// Date        : 2026-10-26
//==============================================================================
`define RST_EDGE negedge    // 复位有效沿：低有效 negedge，高有效 posedge
`define RST_ACT  1'b0       // 复位有效电平：与 RST_EDGE 对应，negedge 配 1'b0，posedge 配 1'b1
`define U_DLY    1          // 非阻塞赋值的仿真延时（timescale 单位，即 1 ns），综合时忽略
```

| 宏 | 取值 | 用途 |
|---|---|---|
| `RST_EDGE` | `negedge` / `posedge` | 时序块敏感列表中的复位沿（HW-41） |
| `RST_ACT` | `1'b0` / `1'b1`，与 `RST_EDGE` 对应 | 复位判断（HW-42） |
| `U_DLY` | 默认 `1` | 非阻塞赋值延时 `` <= #`U_DLY ``（HW-50） |

宏的取值与 `data/<ip>.yaml` 中内部复位（未标 `std_if`，见 HW-14）的 `active` 一致：`low` 对应 `negedge` / `1'b0`，`high` 对应 `posedge` / `1'b1`。标准接口复位不使用这两个宏。

## 2. 命名

| 编号 | 对象 | 规则 | 示例 |
|---|---|---|---|
| HW-10 | 模块、文件 | 全小写 `lower_snake_case`，以 IP 名为前缀（`define.v` 除外） | `uart_lite_tx` |
| HW-11 | `reg` / `wire` / 端口 | 全小写 `lower_snake_case` | `tx_cnt` |
| HW-12 | 输入 / 输出 / 双向端口 | 前缀 `i_` / `o_` / `io_`（时钟、复位端口除外，见 HW-14） | `i_paddr`, `o_irq`, `io_sda` |
| HW-13 | `parameter` / `localparam` / `` `define `` | 全大写 `UPPER_SNAKE_CASE`，**不超过 20 个字符** | `DATA_WIDTH`, `ADDR_CTRL` |
| HW-14 | 时钟 / 复位 | 时钟以 `clk` 为前缀，复位以 `rst` 为前缀；端口不加 `i_`。复位分两类：① **内部复位**：极性由 `define.v` 的 `RST_EDGE` / `RST_ACT` 决定，名字不加后缀；② **标准接口复位**：接口协议规定了极性（如 APB 的 `PRESETn` 低有效），在 `data/<ip>.yaml` 的 `resets` 中标 `std_if: true`，低有效以 `_n` 结尾，高有效不加后缀 | `clk`, `clk_apb`, `rst`, `rst_apb_n` |
| HW-15 | 低有效信号 | 以 `_n` 结尾（内部复位除外，见 HW-14） | `o_cs_n`, `rst_apb_n` |
| HW-16 | 三态输出寄存器 | 以 `_z` 结尾 | `sda_out_z` |
| HW-17 | 时序寄存器 | 以 `_r` 结尾；打拍信号依次 `_r1` / `_r2` | `cnt_r`, `req_r1` |
| HW-18 | 跨时钟域同步后的信号 | 以 `_sync` 结尾 | `req_sync` |
| HW-19 | 例化名 | `U_<子模块名去掉 IP 前缀>`；同一模块多次例化时加序号 `_0`、`_1` | `U_core`, `U_sync_0` |
| HW-20 | generate 块 | 以 `GEN_` 为前缀的块名 | `GEN_LANE` |
| HW-21 | FSM | 状态编码用 `localparam`，名字以 `ST_` 为前缀；状态寄存器 `cur_state`，次态 `nxt_state` | `ST_IDLE` |
| HW-22 | 向量 | 降序定义，最低位为 0：`[N-1:0]` | `reg [7:0] data_r;` |

HW-11（端口）、HW-12、HW-13 由 `run_lint.py` 自动检查；顶层端口名还会由 `gen_docs.py` 在 `data/<ip>.yaml` 中检查（内部复位名不以 `_n` 结尾且极性相同；标准接口复位低有效以 `_n` 结尾、高有效不加 `_n`）。

## 3. 端口与例化

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-30 | 使用 Verilog-2001 ANSI 端口声明；端口顺序：时钟、复位、其余输入，然后双向，最后输出 | 自动（方向顺序） |
| HW-31 | 例化必须按端口名连接 `.port(sig)`，禁止按位置连接，禁止悬空端口；不用的输出写 `.o_xxx()` 并注释原因 | lint |
| HW-32 | 每个模块至少一个输入、一个输出，不写空模块 | lint |
| HW-33 | 顶层模块的输出应经寄存器输出；协议要求组合输出（如 APB 零等待的 `PRDATA`）时在 05 §6 说明 | 评审 |
| HW-34 | 三态逻辑只允许出现在芯片顶层，IP 内部不使用 | 自动（`'bz`） |
| HW-35 | 一个模块例化了 3 个及以上子模块时（`generate` 中对同一模块的多次例化计为 1 个），该模块应只做例化与连接，不再写 `always`、`assign` 等功能逻辑，即写成包封模块（HW-36 ~ HW-39） | 评审 |
| HW-36 | 只例化子模块、不做功能处理的模块称为包封模块。包封模块之间的例化不超过两级：一级包封模块可以例化二级包封模块，二级包封模块例化的必须是功能模块 | 评审 |
| HW-37 | 包封模块不得只例化一个子模块而无其他内容；这种情况直接用被例化的模块代替该包封模块 | 评审 |
| HW-38 | 包封模块应只做例化与连接，不写 `always` 和含逻辑运算的 `assign`；数据连线（位选、拼接、改名）可以用不含逻辑运算的 `assign` | 评审 |
| HW-39 | 包封模块的有效代码行数不受 HW-08 / HW-09 限制 | 评审 |

## 4. 时钟与复位

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-40 | 同步设计；一个时序 `always` 块只有一个时钟、只在一个沿动作，写作 `posedge clk` / `negedge clk` | lint |
| HW-41 | 默认复位方案：异步复位、同步释放（复位同步器在 IP 外部或独立模块中）。内部复位的高低有效由 `define.v` 统一决定，所有内部复位极性相同，时序块固定写作 `` always @(posedge clk or `RST_EDGE rst) ``，不直接写 `posedge rst` / `negedge rst`。标准接口复位（HW-14）极性固定，直接写 `always @(posedge clk or negedge rst_n)`（低有效）或 `always @(posedge clk or posedge rst)`（高有效），沿与 yaml 中的 `active` 一致。大位宽数据只做打拍时可以不复位，写作 `always @(posedge clk)`（见 HW-45） | 自动（内部复位必须写 `` `RST_EDGE ``；标准接口复位的沿与 `active` 一致） |
| HW-42 | 复位判断必须写成比较形式：内部复位固定为 `` if (rst == `RST_ACT) ``；标准接口复位与常量比较，`if (rst_n == 1'b0)`（低有效）或 `if (rst == 1'b1)`（高有效），常量与 `active` 一致。不写 `if (!rst_n)`、`if (rst)` | 自动 |
| HW-43 | 时钟、复位路径上不加门控、不加 buffer；不在模块内生成时钟（分频用使能代替）；时钟不作为数据使用 | 评审 |
| HW-44 | 不用向量定义一组时钟；顶层时钟必须是独立端口 | 评审 |
| HW-45 | 控制通路寄存器必须复位；纯数据通路寄存器（如大位宽数据打拍）可不复位，但须在 05 中说明；有复位与无复位的寄存器分别写在不同 `always` 块中 | 评审 |
| HW-46 | 用复位初始化，不在声明处赋初值，不使用 `initial` | 自动 |

## 5. 赋值与过程块

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-50 | 时序逻辑写在 `` always @(posedge clk or `RST_EDGE rst) ``（带复位）或 `always @(posedge clk)`（无复位）中，只用非阻塞赋值，固定写作 `` <= #`U_DLY ``，延时只用 `U_DLY` 宏 | 自动（非阻塞赋值缺少 `` #`U_DLY ``） |
| HW-51 | 组合逻辑：`always @(*)` 或 `assign`，只用阻塞赋值 `=`；`always @(*)` 自动保证敏感列表完整 | 自动（`always @(` 电平列表） |
| HW-52 | 组合 `always` 块首先给所有输出赋默认值，或在 `if` / `case` 所有分支中赋值，**禁止产生锁存器** | 综合检查 |
| HW-53 | 一个 `reg` 只能在一个 `always` 块中赋值；同一 `always` 块不混合时序与组合 | lint |
| HW-54 | `case` / `casez` 必须有 `default`；不使用 `casex`；可以使用 `casez`，`?` 只能出现在 `casez` 的分支常量中，不得出现 `x`、`z`；不使用 `full_case` / `parallel_case` 综合指令；优先级译码用 `if` / `else if` 或 `casez` | 自动 |
| HW-55 | 赋值两侧位宽一致；常量写明位宽（`1'b0`、`8'hFF`、`{DATA_WIDTH{1'b0}}`），禁止魔数 | lint |
| HW-56 | 移位量必须是常数；`if` 嵌套不超过 4 层，否则改写为 `case` 或拆分逻辑 | 评审 |
| HW-57 | 避免异步反馈环路与组合环 | lint |

## 6. 禁用的语法

| 编号 | 禁止项 | 检查 |
|---|---|---|
| HW-60 | `initial`、`#` 延时（HW-50 的 `` <= #`U_DLY `` 除外）、`wait`、`fork`/`join`、`disable`、`force`/`release`、过程 `assign`/`deassign`、`event` | 自动 |
| HW-61 | 系统任务与函数（`$display`、`$random` 等）、PLI、UDP、`specify`。例外：`$clog2` 只能用在 `parameter` / `localparam` 声明的右侧（如 `localparam CNT_W = $clog2(DEPTH);`），端口、信号声明和逻辑表达式中改用该参数 | 自动 |
| HW-62 | `===`、`!==`，条件表达式中的 `x` / `z`；含 `?` 的常量（`casez` 分支常量除外） | 自动 |
| HW-63 | `real`、`realtime`、`time`、`integer` 类型（`for` 循环变量用 `genvar` 或固定位宽 `reg`） | 自动 |
| HW-64 | `forever`、`repeat`、`while`；`task` | 自动 |
| HW-65 | `tri0`/`tri1`/`triand`/`trior`/`trireg`、驱动强度、`supply0`/`supply1` 赋值、门级开关原语（`nmos`、`pmos`、`cmos`、`tran` 等） | 自动 |

## 7. FSM

- 采用**三段式**：① 时序块更新 `cur_state`；② 组合块根据 `cur_state` 与输入计算 `nxt_state`；③ 时序块产生寄存器输出。
- `case` 必须有 `default`，次态回到安全状态（通常为 `ST_IDLE`）。
- 状态名、转移条件与 `02_architecture.md` 的状态转移表一一对应。

```verilog
localparam ST_IDLE = 2'd0;
localparam ST_BUSY = 2'd1;

always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        cur_state <= #`U_DLY ST_IDLE;
    end
    else begin
        cur_state <= #`U_DLY nxt_state;
    end
end

always @(*) begin
    nxt_state = cur_state;
    case (cur_state)
        ST_IDLE : if (i_start == 1'b1) nxt_state = ST_BUSY;
        ST_BUSY : if (done == 1'b1)    nxt_state = ST_IDLE;
        default : nxt_state = ST_IDLE;
    endcase
end

always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        o_busy <= #`U_DLY 1'b0;
    end
    else begin
        o_busy <= #`U_DLY (nxt_state == ST_BUSY);
    end
end
```

## 8. 文件头与排版

```verilog
`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_core.v
// Module name : demo_timer_core
// Function    : 32 bit 递增计数器与到时比较
// Version     : 1.0
// Date        : 2026-10-23
// Doc         : doc/05_rtl_structure.md
// History     : 见 CHANGELOG.md 与 doc/08_iteration_log.md
//==============================================================================
```

`define.v` 的文件头见 §1.1。

- 缩进 4 个空格，不用 Tab；每行不超过 100 字符。
- `begin` 与 `if` / `else` / `always` 同行，`end` 单独一行；`else` 另起一行。
- `if` / `else` 分支即使只有一条语句也写 `begin ... end`（单行 `case` 项除外）。
- 每个信号一行声明，行尾注释说明含义；关键逻辑注释引用 REQ / DEC 编号。
- 模块内顺序：端口 → `localparam` → 内部信号声明 → 组合逻辑 → 时序逻辑 → 子模块例化 → 输出赋值。

## 9. CDC

- 单 bit 跨时钟域：两级同步器，统一使用同步器模块（如 `<ip>_sync_2ff`），同步后信号以 `_sync` 结尾。
- 多 bit：握手、异步 FIFO 或格雷码，禁止直接两级同步多 bit 总线。
- 所有 CDC 路径列在 `02_architecture.md` 的 CDC 表中。

## 10. 断言与 testbench

- RTL 中不写 SVA 与任何仿真语句（HW-60、HW-61）。协议与不变式检查放在 testbench 的监视器 `always` 块中，并列入 `07_dv_plan.md` §4。
- testbench 同样使用 Verilog-2001，文件 `dv/tb/<ip>_tb.v`（可拆成多个 `dv/tb/*.v`），模块 `<ip>_tb`，DUT 例化名 `U_dut`。testbench 不受 HW-42、HW-46、HW-50、HW-60 ~ HW-64 限制（可用 `initial`、`task`、`#` 延时、系统任务、`===`）。
- testbench 不使用 `define.v` 中的宏（`--stub` 模式不编译 RTL 文件），复位按 `data/<ip>.yaml` 中复位的 `active` 驱动。
- RTL 寄存器输出在时钟沿后 1 ns（`U_DLY`）变化。testbench 在时钟沿后 2 ns 驱动输入并采样输出（或在下降沿采样），不要在沿后 1 ns 采样，否则与 DUT 更新同时发生，读到旧值。
- `reg clk = 1'b0;` 这类声明初值在 0 时刻产生一次 X→0 跳变，`@(negedge clk)` 会在 0 时刻触发，而此时 DUT 的异步复位可能还没有求值（VCS 下必然出现）。下降沿采样的监视器要跳过 0 时刻（`if ($time != 0 && ...)`），真正的第一个下降沿在半个周期之后。
- **黑盒**：testbench 只通过顶层端口访问 DUT，禁止 `U_dut.xxx` 层次引用。验证由 tb-engineer 只根据规格独立编写，`run_regress.py --stub` 用端口桩代替 RTL 编译 testbench，层次引用会在这里报错。
- **运行约定**（`run_regress.py` 依赖）：
  - 用例选择 `+TEST=<name>`、`+SEED=<n>`；名字含 `random` 的用例按多个种子运行。用例名来自 `07_dv_plan.md` §3 的「用例」列（反引号）。
  - 检查失败打印 `[<time>] ERROR: <说明>`；功能覆盖打印 `COVER <名字>=<命中次数>`（为 0 视为未覆盖，回归失败）。
  - 结束时打印 `TEST <name> SEED <n> PASSED|FAILED errors=<n>` 并 `$finish`。
  - 必须有看门狗：超时后打印 `TEST <name> FAILED errors=<n>` 并 `$finish`（桩检查时 DUT 输出恒 0，依赖看门狗结束）。

## 11. Lint

- `run_lint.py` 先做本规范的风格检查（标「自动」的规则），再按 `rtl_files` 的顺序（`define.v` 在最前）运行 SpyGlass `lint/lint_rtl`（rtl_handoff 方法学，Fatal / Error 计为 error，Warning 计为 warning），或用 `--tool vcs` 运行 `vcs +lint=all`。两者都按 Verilog-2005 读入（为了 `$clog2`），其余 Verilog-2005 新增语法由风格检查拦截（HW-01）。工具的完整输出在 `dv/build/lint/`。
- 交付前零 error；保留的 warning 在 `05_rtl_structure.md` §7 说明豁免原因，规范偏离在 §6 说明。
