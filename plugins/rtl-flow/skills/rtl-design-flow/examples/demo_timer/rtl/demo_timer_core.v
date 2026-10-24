`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_core.v
// Module name : demo_timer_core
// Function    : 32 bit 递增计数器与到时比较（02_architecture §3、§4）
// Version     : 2.0
// Date        : 2026-10-23
// Doc         : doc/05_rtl_structure.md
// History     : 见 CHANGELOG.md 与 doc/08_iteration_log.md
//==============================================================================
module demo_timer_core (
    input               clk     ,   // 主时钟
    input               rst_n   ,   // 低有效异步复位
    input               i_en    ,   // CTRL.EN
    input               i_clr   ,   // CTRL.CLR 写 1 脉冲
    input       [31:0]  i_cmp   ,   // CMP.VAL
    output      [31:0]  o_count ,   // COUNT.VAL
    output              o_expire    // 到时事件，单周期脉冲
);

reg     [31:0]  count_r;            // 计数值

// DEC-001：使用 >= 比较
assign o_expire = (i_en == 1'b1) && (count_r >= i_cmp);

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        count_r <= 32'd0;
    end
    else if ((i_clr == 1'b1) || (o_expire == 1'b1)) begin    // 清零优先级最高（REQ-FUNC-006）
        count_r <= 32'd0;
    end
    else if (i_en == 1'b1) begin
        count_r <= count_r + 32'd1;
    end
end

assign o_count = count_r;

endmodule
