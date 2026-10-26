`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer.v
// Module name : demo_timer
// Function    : 顶层：APB3 32 bit 定时器，单次 / 周期模式，电平中断
// Version     : 3.0
// Date        : 2026-10-26
// Doc         : doc/05_rtl_structure.md
// History     : 见 CHANGELOG.md 与 doc/08_iteration_log.md
//==============================================================================
module demo_timer (
    input               clk         ,   // 主时钟，100 MHz
    input               rst         ,   // 异步复位，极性由 define.v 的 RST_EDGE / RST_ACT 决定
    input               i_psel      ,   // APB 片选
    input               i_penable   ,   // APB 访问阶段指示
    input               i_pwrite    ,   // APB 写使能
    input       [11:0]  i_paddr     ,   // APB 字节地址
    input       [31:0]  i_pwdata    ,   // APB 写数据
    output      [31:0]  o_prdata    ,   // APB 读数据
    output              o_pready    ,   // APB 就绪，恒为 1
    output              o_pslverr   ,   // APB 错误响应
    output              o_irq           // 到时中断，高电平有效
);

wire            ctrl_en;            // CTRL.EN
wire            ctrl_clr;           // CTRL.CLR 脉冲
wire    [31:0]  cmp_val;            // CMP.VAL
wire    [31:0]  count_val;          // COUNT.VAL
wire            intr_state;         // INTR_STATE.EXPIRED
wire            intr_enable;        // INTR_ENABLE.EXPIRED
wire            expire;             // 到时事件

demo_timer_reg U_reg (
    .clk            (clk            ),
    .rst            (rst            ),
    .i_psel         (i_psel         ),
    .i_penable      (i_penable      ),
    .i_pwrite       (i_pwrite       ),
    .i_paddr        (i_paddr        ),
    .i_pwdata       (i_pwdata       ),
    .i_count_val    (count_val      ),
    .i_expire       (expire         ),
    .o_prdata       (o_prdata       ),
    .o_pready       (o_pready       ),
    .o_pslverr      (o_pslverr      ),
    .o_ctrl_en      (ctrl_en        ),
    .o_ctrl_clr     (ctrl_clr       ),
    .o_cmp_val      (cmp_val        ),
    .o_intr_state   (intr_state     ),
    .o_intr_enable  (intr_enable    )
);

demo_timer_core U_core (
    .clk            (clk            ),
    .rst            (rst            ),
    .i_en           (ctrl_en        ),
    .i_clr          (ctrl_clr       ),
    .i_cmp          (cmp_val        ),
    .o_count        (count_val      ),
    .o_expire       (expire         )
);

// REQ-FUNC-005：电平中断（组合输出，05 §6 偏离 HW-33，DEC-007）
assign o_irq = intr_state & intr_enable;

endmodule
