`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer.v
// Module name : demo_timer
// Function    : 顶层：APB3 32 bit 定时器，单次 / 周期模式，电平中断
// Version     : 4.0
// Date        : 2026-11-24
// Doc         : doc/05_rtl_structure.md
//==============================================================================
module demo_timer (
    input  wire        i_clk,      // 主时钟，100 MHz
    input  wire        i_rst,      // 异步复位，极性由 define.v 的 RST_EDGE / RST_ACT 决定
    input  wire        i_psel,     // APB 片选
    input  wire        i_penable,  // APB 访问阶段指示
    input  wire        i_pwrite,   // APB 写使能
    input  wire [11:0] i_paddr,    // APB 字节地址
    input  wire [31:0] i_pwdata,   // APB 写数据
    output wire [31:0] o_prdata,   // APB 读数据
    output wire        o_pready,   // APB 就绪，恒为 1
    output wire        o_pslverr,  // APB 错误响应
    output wire        o_irq       // 到时中断，高电平有效
);

wire        w_ctrl_en;       // CTRL.EN
wire        w_ctrl_clr;      // CTRL.CLR 脉冲
wire [31:0] w_cmp_val;       // CMP.VAL
wire [31:0] w_count_val;     // COUNT.VAL
wire        w_intr_state;    // INTR_STATE.EXPIRED
wire        w_intr_enable;   // INTR_ENABLE.EXPIRED
wire        w_expire;        // 到时事件

demo_timer_reg U_reg (
    .i_clk         (i_clk        ),
    .i_rst         (i_rst        ),
    .i_psel        (i_psel       ),
    .i_penable     (i_penable    ),
    .i_pwrite      (i_pwrite     ),
    .i_paddr       (i_paddr      ),
    .i_pwdata      (i_pwdata     ),
    .i_count_val   (w_count_val  ),
    .i_expire      (w_expire     ),
    .o_prdata      (o_prdata     ),
    .o_pready      (o_pready     ),
    .o_pslverr     (o_pslverr    ),
    .o_ctrl_en     (w_ctrl_en    ),
    .o_ctrl_clr    (w_ctrl_clr   ),
    .o_cmp_val     (w_cmp_val    ),
    .o_intr_state  (w_intr_state ),
    .o_intr_enable (w_intr_enable)
);

demo_timer_core U_core (
    .i_clk    (i_clk      ),
    .i_rst    (i_rst      ),
    .i_en     (w_ctrl_en  ),
    .i_clr    (w_ctrl_clr ),
    .i_cmp    (w_cmp_val  ),
    .o_count  (w_count_val),
    .o_expire (w_expire   )
);

// REQ-FUNC-005：电平中断（组合输出，05 §6 偏离 RTL-33，DEC-007）
assign o_irq = w_intr_state & w_intr_enable;

endmodule
