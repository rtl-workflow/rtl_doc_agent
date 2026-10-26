# RTL 编码规范 (RTL Coding Style)

> 以华为 Verilog 编码规范（2001 版，71 条）为基线整理，结合 Cummings SNUG 系列论文的赋值与 FSM 规则补充。团队可按自身规范覆盖本文件。
> 规则编号 `HW-xx` 供评审、lint 报告与 `05_rtl_structure.md` §6「编码约定与偏离」引用。**标「自动」的规则由 `run_lint.py` 检查，违反即 lint error。**
> 情态词：`必须`（强制）/ `应`（推荐，偏离须在 05 §6 写明原因，重要偏离记 DEC）。

## 1. 语言与文件

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-01 | RTL 必须使用可综合 Verilog-2001（IEEE 1364-2001）。禁止 SystemVerilog 语法：`logic`、`bit`、`always_ff`、`always_comb`、`always_latch`、`typedef`、`enum`、`struct`、`interface`、`package`、`import`、`unique`、`priority`、`'0`/`'1`、`++`/`+=`、`.name` 隐式端口连接 | 自动 |
| HW-02 | 一个文件只包含一个模块；文件名 = 模块名，后缀 `.v` | 自动 |
| HW-03 | 每个文件第一行必须是 `` `timescale 1ns / 1ps `` | 自动 |
| HW-04 | 每个文件开头必须有文件头（格式见 §8），写明文件名、模块名、功能、版本、日期 | 自动（检查 `Module name` / `Function` / `Version` / `Date` 字段） |
| HW-05 | RTL 中不使用 `` `include ``；常量用 `parameter` / `localparam` 在模块内定义 | 自动 |
| HW-06 | 不使用 Verilog / VHDL / SystemVerilog 保留字作为名字 | lint |

## 2. 命名

| 编号 | 对象 | 规则 | 示例 |
|---|---|---|---|
| HW-10 | 模块、文件 | 全小写 `lower_snake_case`，以 IP 名为前缀 | `uart_lite_tx` |
| HW-11 | `reg` / `wire` / 端口 | 全小写 `lower_snake_case` | `tx_cnt` |
| HW-12 | 输入 / 输出 / 双向端口 | 前缀 `i_` / `o_` / `io_`（时钟、复位端口除外，见 HW-14） | `i_paddr`, `o_irq`, `io_sda` |
| HW-13 | `parameter` / `localparam` / `` `define `` | 全大写 `UPPER_SNAKE_CASE`，**不超过 20 个字符** | `DATA_WIDTH`, `ADDR_CTRL` |
| HW-14 | 时钟 / 复位 | 时钟以 `clk` 为前缀，复位以 `rst` 为前缀；端口不加 `i_` | `clk`, `clk_apb`, `rst_n`, `rst_apb_n` |
| HW-15 | 低有效信号 | 以 `_n` 结尾 | `rst_n`, `o_cs_n` |
| HW-16 | 三态输出寄存器 | 以 `_z` 结尾 | `sda_out_z` |
| HW-17 | 时序寄存器 | 以 `_r` 结尾；打拍信号依次 `_r1` / `_r2` | `cnt_r`, `req_r1` |
| HW-18 | 跨时钟域同步后的信号 | 以 `_sync` 结尾 | `req_sync` |
| HW-19 | 例化名 | `U_<子模块名去掉 IP 前缀>`；同一模块多次例化时加序号 `_0`、`_1` | `U_core`, `U_sync_0` |
| HW-20 | generate 块 | 以 `GEN_` 为前缀的块名 | `GEN_LANE` |
| HW-21 | FSM | 状态编码用 `localparam`，名字以 `ST_` 为前缀；状态寄存器 `cur_state`，次态 `nxt_state` | `ST_IDLE` |
| HW-22 | 向量 | 降序定义，最低位为 0：`[N-1:0]` | `reg [7:0] data_r;` |

HW-11（端口）、HW-12、HW-13 由 `run_lint.py` 自动检查；顶层端口名还会由 `gen_docs.py` 在 `data/<ip>.yaml` 中检查。

## 3. 端口与例化

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-30 | 使用 Verilog-2001 ANSI 端口声明；端口顺序：时钟、复位、其余输入，然后双向，最后输出 | 自动（方向顺序） |
| HW-31 | 例化必须按端口名连接 `.port(sig)`，禁止按位置连接，禁止悬空端口；不用的输出写 `.o_xxx()` 并注释原因 | lint |
| HW-32 | 每个模块至少一个输入、一个输出，不写空模块 | lint |
| HW-33 | 顶层模块的输出应经寄存器输出；协议要求组合输出（如 APB 零等待的 `PRDATA`）时在 05 §6 说明 | 评审 |
| HW-34 | 三态逻辑只允许出现在芯片顶层，IP 内部不使用 | 自动（`'bz`） |

## 4. 时钟与复位

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-40 | 同步设计；一个时序 `always` 块只有一个时钟、只在一个沿动作，写作 `posedge clk` / `negedge clk` | lint |
| HW-41 | 默认复位方案：低有效异步复位、同步释放（复位同步器在 IP 外部或独立模块中），写法固定为 `always @(posedge clk or negedge rst_n)` | 评审 |
| HW-42 | 复位判断必须写成比较形式：低有效 `if (rst_n == 1'b0)`，高有效 `if (rst == 1'b1)` | 自动 |
| HW-43 | 时钟、复位路径上不加门控、不加 buffer；不在模块内生成时钟（分频用使能代替）；时钟不作为数据使用 | 评审 |
| HW-44 | 不用向量定义一组时钟；顶层时钟必须是独立端口 | 评审 |
| HW-45 | 控制通路寄存器必须复位；纯数据通路寄存器可不复位，但须在 05 中说明；有复位与无复位的寄存器分别写在不同 `always` 块中 | 评审 |
| HW-46 | 用复位初始化，不在声明处赋初值，不使用 `initial` | 自动 |

## 5. 赋值与过程块

| 编号 | 规则 | 检查 |
|---|---|---|
| HW-50 | 时序逻辑：`always @(posedge clk or negedge rst_n)`，只用非阻塞赋值 `<=`，赋值不带延时 | 自动（`<= #`） |
| HW-51 | 组合逻辑：`always @(*)` 或 `assign`，只用阻塞赋值 `=`；`always @(*)` 自动保证敏感列表完整 | 自动（`always @(` 电平列表） |
| HW-52 | 组合 `always` 块首先给所有输出赋默认值，或在 `if` / `case` 所有分支中赋值，**禁止产生锁存器** | 综合检查 |
| HW-53 | 一个 `reg` 只能在一个 `always` 块中赋值；同一 `always` 块不混合时序与组合 | lint |
| HW-54 | `case` 必须有 `default`；不使用 `casex` / `casez`（常量中不得出现 `?`、`x`、`z`）；不使用 `full_case` / `parallel_case` 综合指令；优先级译码用 `if` / `else if` | 自动 |
| HW-55 | 赋值两侧位宽一致；常量写明位宽（`1'b0`、`8'hFF`、`{DATA_WIDTH{1'b0}}`），禁止魔数 | lint |
| HW-56 | 移位量必须是常数；`if` 嵌套不超过 4 层，否则改写为 `case` 或拆分逻辑 | 评审 |
| HW-57 | 避免异步反馈环路与组合环 | lint |

## 6. 禁用的语法

| 编号 | 禁止项 | 检查 |
|---|---|---|
| HW-60 | `initial`、`#` 延时、`wait`、`fork`/`join`、`disable`、`force`/`release`、过程 `assign`/`deassign`、`event` | 自动 |
| HW-61 | 系统任务与函数（`$display`、`$clog2`、`$random` 等）、PLI、UDP、`specify` | 自动 |
| HW-62 | `===`、`!==`，条件表达式中的 `x` / `z` | 自动 |
| HW-63 | `real`、`realtime`、`time`、`integer` 类型（`for` 循环变量用 `genvar` 或固定位宽 `reg`） | 自动 |
| HW-64 | `forever`、`repeat`、`while`；`task` | 自动 |
| HW-65 | `tri0`/`tri1`/`triand`/`trior`/`trireg`、驱动强度、`supply0`/`supply1` 赋值、门级开关原语（`nmos`、`pmos`、`cmos`、`tran` 等） | 自动 |

> 位宽需要对数运算时，由调用方以参数传入（如 `ADDR_WIDTH`），或在模块内写常量 `function`；不使用 `$clog2`。

## 7. FSM

- 采用**三段式**：① 时序块更新 `cur_state`；② 组合块根据 `cur_state` 与输入计算 `nxt_state`；③ 时序块产生寄存器输出。
- `case` 必须有 `default`，次态回到安全状态（通常为 `ST_IDLE`）。
- 状态名、转移条件与 `02_architecture.md` 的状态转移表一一对应。

```verilog
localparam ST_IDLE = 2'd0;
localparam ST_BUSY = 2'd1;

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        cur_state <= ST_IDLE;
    end
    else begin
        cur_state <= nxt_state;
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

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        o_busy <= 1'b0;
    end
    else begin
        o_busy <= (nxt_state == ST_BUSY);
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
- testbench 同样使用 Verilog-2001，文件 `dv/tb/<ip>_tb.v`（可拆成多个 `dv/tb/*.v`），模块 `<ip>_tb`，DUT 例化名 `U_dut`。testbench 不受 HW-46、HW-60 ~ HW-64 限制（可用 `initial`、`task`、`#` 延时、系统任务、`===`）。
- **黑盒**：testbench 只通过顶层端口访问 DUT，禁止 `U_dut.xxx` 层次引用。验证由 tb-engineer 只根据规格独立编写，`run_regress.py --stub` 用端口桩代替 RTL 编译 testbench，层次引用会在这里报错。
- **运行约定**（`run_regress.py` 依赖）：
  - 用例选择 `+TEST=<name>`、`+SEED=<n>`；名字含 `random` 的用例按多个种子运行。用例名来自 `07_dv_plan.md` §3 的「用例」列（反引号）。
  - 检查失败打印 `[<time>] ERROR: <说明>`；功能覆盖打印 `COVER <名字>=<命中次数>`（为 0 视为未覆盖，回归失败）。
  - 结束时打印 `TEST <name> SEED <n> PASSED|FAILED errors=<n>` 并 `$finish`。
  - 必须有看门狗：超时后打印 `TEST <name> FAILED errors=<n>` 并 `$finish`（桩检查时 DUT 输出恒 0，依赖看门狗结束）。

## 11. Lint

- `run_lint.py` 先做本规范的风格检查（标「自动」的规则），再运行 `verilator --lint-only -Wall --default-language 1364-2001`（或 `verible-verilog-lint`）。
- 交付前零 error；保留的 warning 在 `05_rtl_structure.md` §7 说明豁免原因，规范偏离在 §6 说明。
