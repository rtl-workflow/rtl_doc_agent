`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_reg.v
// Module name : demo_timer_reg
// Function    : APB3 从接口、地址译码与寄存器（04_registers、02_architecture §4）
// Version     : 4.0
// Date        : 2026-11-24
// Doc         : doc/05_rtl_structure.md
//==============================================================================
module demo_timer_reg (
    input  wire        i_clk,          // 主时钟
    input  wire        i_rst,          // 异步复位，极性由 define.v 的 RST_EDGE / RST_ACT 决定
    // APB3
    input  wire        i_psel,
    input  wire        i_penable,
    input  wire        i_pwrite,
    input  wire [11:0] i_paddr,
    input  wire [31:0] i_pwdata,
    // 硬件接口
    input  wire [31:0] i_count_val,     // COUNT.VAL
    input  wire        i_expire,        // 到时事件
    // APB3
    output wire [31:0] o_prdata,
    output wire        o_pready,
    output wire        o_pslverr,
    // 硬件接口
    output wire        o_ctrl_en,       // CTRL.EN
    output wire        o_ctrl_clr,      // CTRL.CLR 写 1 单周期脉冲
    output wire [31:0] o_cmp_val,       // CMP.VAL
    output wire        o_intr_state,    // INTR_STATE.EXPIRED
    output wire        o_intr_enable    // INTR_ENABLE.EXPIRED
);

// 寄存器偏移，与 data/demo_timer.yaml 保持一致
localparam ADDR_CTRL        = 12'h000;
localparam ADDR_CMP         = 12'h004;
localparam ADDR_COUNT       = 12'h008;
localparam ADDR_INTR_STATE  = 12'h00C;
localparam ADDR_INTR_ENABLE = 12'h010;

localparam MODE_ONESHOT     = 1'b0;

reg        ctrl_en_r;       // CTRL.EN
reg        ctrl_mode_r;     // CTRL.MODE
reg [31:0] cmp_r;           // CMP.VAL
reg        intr_state_r;    // INTR_STATE.EXPIRED
reg        intr_enable_r;   // INTR_ENABLE.EXPIRED
reg [31:0] w_rd_data;       // 组合读数据选择

wire w_hit_ctrl;         // 地址命中 CTRL
wire w_hit_cmp;          // 地址命中 CMP
wire w_hit_count;        // 地址命中 COUNT
wire w_hit_intr_state;   // 地址命中 INTR_STATE
wire w_hit_intr_enable;  // 地址命中 INTR_ENABLE
wire w_addr_hit;         // 地址合法
wire w_access;           // APB 访问阶段
wire w_wr_en;            // 合法地址写

//------------------------------------------------------------------------------
// 地址译码
//------------------------------------------------------------------------------
assign w_hit_ctrl        = (i_paddr == ADDR_CTRL);
assign w_hit_cmp         = (i_paddr == ADDR_CMP);
assign w_hit_count       = (i_paddr == ADDR_COUNT);
assign w_hit_intr_state  = (i_paddr == ADDR_INTR_STATE);
assign w_hit_intr_enable = (i_paddr == ADDR_INTR_ENABLE);
assign w_addr_hit        = w_hit_ctrl | w_hit_cmp | w_hit_count |
                           w_hit_intr_state | w_hit_intr_enable;

assign w_access = i_psel & i_penable;
assign w_wr_en  = w_access & i_pwrite & w_addr_hit;

//------------------------------------------------------------------------------
// 读数据
//------------------------------------------------------------------------------
always @(*) begin
    case (i_paddr)
        ADDR_CTRL :
            w_rd_data = {30'd0, ctrl_mode_r, ctrl_en_r};
        ADDR_CMP :
            w_rd_data = cmp_r;
        ADDR_COUNT :
            w_rd_data = i_count_val;
        ADDR_INTR_STATE :
            w_rd_data = {31'd0, intr_state_r};
        ADDR_INTR_ENABLE :
            w_rd_data = {31'd0, intr_enable_r};
        default :
            w_rd_data = 32'd0;
    endcase
end

//------------------------------------------------------------------------------
// 寄存器
//------------------------------------------------------------------------------
// CTRL.EN：单次模式到时硬件清零；软件写优先（DEC-002）
always @(posedge i_clk or `RST_EDGE i_rst) begin
    if (i_rst == `RST_ACT) begin
        ctrl_en_r <= #`U_DLY 1'b0;
    end
    else if ((w_wr_en == 1'b1) && (w_hit_ctrl == 1'b1)) begin
        ctrl_en_r <= #`U_DLY i_pwdata[0];
    end
    else if ((i_expire == 1'b1) && (ctrl_mode_r == MODE_ONESHOT)) begin
        ctrl_en_r <= #`U_DLY 1'b0;
    end
end

// CTRL.MODE
always @(posedge i_clk or `RST_EDGE i_rst) begin
    if (i_rst == `RST_ACT) begin
        ctrl_mode_r <= #`U_DLY 1'b0;
    end
    else if ((w_wr_en == 1'b1) && (w_hit_ctrl == 1'b1)) begin
        ctrl_mode_r <= #`U_DLY i_pwdata[1];
    end
end

// CMP.VAL
always @(posedge i_clk or `RST_EDGE i_rst) begin
    if (i_rst == `RST_ACT) begin
        cmp_r <= #`U_DLY 32'hFFFF_FFFF;
    end
    else if ((w_wr_en == 1'b1) && (w_hit_cmp == 1'b1)) begin
        cmp_r <= #`U_DLY i_pwdata;
    end
end

// INTR_STATE.EXPIRED：rw1c；硬件置位优先（DEC-003）
always @(posedge i_clk or `RST_EDGE i_rst) begin
    if (i_rst == `RST_ACT) begin
        intr_state_r <= #`U_DLY 1'b0;
    end
    else if (i_expire == 1'b1) begin
        intr_state_r <= #`U_DLY 1'b1;
    end
    else if ((w_wr_en == 1'b1) && (w_hit_intr_state == 1'b1) && (i_pwdata[0] == 1'b1)) begin
        intr_state_r <= #`U_DLY 1'b0;
    end
end

// INTR_ENABLE.EXPIRED
always @(posedge i_clk or `RST_EDGE i_rst) begin
    if (i_rst == `RST_ACT) begin
        intr_enable_r <= #`U_DLY 1'b0;
    end
    else if ((w_wr_en == 1'b1) && (w_hit_intr_enable == 1'b1)) begin
        intr_enable_r <= #`U_DLY i_pwdata[0];
    end
end

//------------------------------------------------------------------------------
// 输出
//------------------------------------------------------------------------------
// APB 零等待：PRDATA / PSLVERR 在访问阶段组合输出（05 §6 偏离 RTL-33，DEC-007）
assign o_prdata      = ((w_access == 1'b1) && (i_pwrite == 1'b0)) ? w_rd_data : 32'd0;
assign o_pready      = 1'b1;
assign o_pslverr     = w_access & ~w_addr_hit;

assign o_ctrl_en     = ctrl_en_r;
assign o_ctrl_clr    = w_wr_en & w_hit_ctrl & i_pwdata[2];  // CTRL.CLR：写 1 单周期脉冲（DEC-005）
assign o_cmp_val     = cmp_r;
assign o_intr_state  = intr_state_r;
assign o_intr_enable = intr_enable_r;

endmodule
