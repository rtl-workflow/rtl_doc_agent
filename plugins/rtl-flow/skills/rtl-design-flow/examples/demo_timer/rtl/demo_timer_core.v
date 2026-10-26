`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_core.v
// Module name : demo_timer_core
// Function    : 32 bit 递增计数器与到时比较（02_architecture §3、§4）
// Version     : 3.0
// Date        : 2026-10-26
// Doc         : doc/05_rtl_structure.md
// History     : 见 CHANGELOG.md 与 doc/08_iteration_log.md
//==============================================================================
module demo_timer_core (
    input               clk     ,   // 主时钟
    input               rst     ,   // 异步复位，极性由 define.v 的 RST_EDGE / RST_ACT 决定
    input               i_en    ,   // CTRL.EN
    input               i_clr   ,   // CTRL.CLR 写 1 脉冲
    input       [31:0]  i_cmp   ,   // CMP.VAL
    output      [31:0]  o_count ,   // COUNT.VAL
    output              o_expire    // 到时事件，单周期脉冲
);

reg     [31:0]  count_r;            // 计数值

// DEC-001：使用 >= 比较
assign o_expire = (i_en == 1'b1) && (count_r >= i_cmp);

always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        count_r <= #`U_DLY 32'd0;
    end
    else if ((i_clr == 1'b1) || (o_expire == 1'b1)) begin    // 清零优先级最高（REQ-FUNC-006）
        count_r <= #`U_DLY 32'd0;
    end
    else if (i_en == 1'b1) begin
        count_r <= #`U_DLY count_r + 32'd1;
    end
end

assign o_count = count_r;

endmodule
