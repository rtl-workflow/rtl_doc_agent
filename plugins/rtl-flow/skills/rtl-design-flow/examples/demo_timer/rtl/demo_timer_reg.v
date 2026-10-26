`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_reg.v
// Module name : demo_timer_reg
// Function    : APB3 从接口、地址译码与寄存器（04_registers、02_architecture §4）
// Version     : 3.0
// Date        : 2026-10-26
// Doc         : doc/05_rtl_structure.md
// History     : 见 CHANGELOG.md 与 doc/08_iteration_log.md
//==============================================================================
module demo_timer_reg (
    input               clk             ,   // 主时钟
    input               rst             ,   // 异步复位，极性由 define.v 的 RST_EDGE / RST_ACT 决定
    // APB3
    input               i_psel          ,
    input               i_penable       ,
    input               i_pwrite        ,
    input       [11:0]  i_paddr         ,
    input       [31:0]  i_pwdata        ,
    // 硬件接口
    input       [31:0]  i_count_val     ,   // COUNT.VAL
    input               i_expire        ,   // 到时事件
    // APB3
    output      [31:0]  o_prdata        ,
    output              o_pready        ,
    output              o_pslverr       ,
    // 硬件接口
    output              o_ctrl_en       ,   // CTRL.EN
    output              o_ctrl_clr      ,   // CTRL.CLR 写 1 单周期脉冲
    output      [31:0]  o_cmp_val       ,   // CMP.VAL
    output              o_intr_state    ,   // INTR_STATE.EXPIRED
    output              o_intr_enable       // INTR_ENABLE.EXPIRED
);

// 寄存器偏移，与 data/demo_timer.yaml 保持一致
localparam ADDR_CTRL        = 12'h000;
localparam ADDR_CMP         = 12'h004;
localparam ADDR_COUNT       = 12'h008;
localparam ADDR_INTR_STATE  = 12'h00C;
localparam ADDR_INTR_ENABLE = 12'h010;

localparam MODE_ONESHOT     = 1'b0;

wire            hit_ctrl;           // 地址命中 CTRL
wire            hit_cmp;            // 地址命中 CMP
wire            hit_count;          // 地址命中 COUNT
wire            hit_intr_state;     // 地址命中 INTR_STATE
wire            hit_intr_enable;    // 地址命中 INTR_ENABLE
wire            addr_hit;           // 地址合法
wire            access;             // APB 访问阶段
wire            wr_en;              // 合法地址写

reg             ctrl_en_r;          // CTRL.EN
reg             ctrl_mode_r;        // CTRL.MODE
reg     [31:0]  cmp_r;              // CMP.VAL
reg             intr_state_r;       // INTR_STATE.EXPIRED
reg             intr_enable_r;      // INTR_ENABLE.EXPIRED
reg     [31:0]  rd_data;            // 读数据选择

//------------------------------------------------------------------------------
// 地址译码
//------------------------------------------------------------------------------
assign hit_ctrl        = (i_paddr == ADDR_CTRL);
assign hit_cmp         = (i_paddr == ADDR_CMP);
assign hit_count       = (i_paddr == ADDR_COUNT);
assign hit_intr_state  = (i_paddr == ADDR_INTR_STATE);
assign hit_intr_enable = (i_paddr == ADDR_INTR_ENABLE);
assign addr_hit        = hit_ctrl | hit_cmp | hit_count | hit_intr_state | hit_intr_enable;

assign access = i_psel & i_penable;
assign wr_en  = access & i_pwrite & addr_hit;

//------------------------------------------------------------------------------
// 读数据
//------------------------------------------------------------------------------
always @(*) begin
    case (i_paddr)
        ADDR_CTRL        : rd_data = {30'd0, ctrl_mode_r, ctrl_en_r};
        ADDR_CMP         : rd_data = cmp_r;
        ADDR_COUNT       : rd_data = i_count_val;
        ADDR_INTR_STATE  : rd_data = {31'd0, intr_state_r};
        ADDR_INTR_ENABLE : rd_data = {31'd0, intr_enable_r};
        default          : rd_data = 32'd0;
    endcase
end

//------------------------------------------------------------------------------
// 寄存器
//------------------------------------------------------------------------------
// CTRL.EN：单次模式到时硬件清零；软件写优先（DEC-002）
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        ctrl_en_r <= #`U_DLY 1'b0;
    end
    else if ((wr_en == 1'b1) && (hit_ctrl == 1'b1)) begin
        ctrl_en_r <= #`U_DLY i_pwdata[0];
    end
    else if ((i_expire == 1'b1) && (ctrl_mode_r == MODE_ONESHOT)) begin
        ctrl_en_r <= #`U_DLY 1'b0;
    end
end

// CTRL.MODE
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        ctrl_mode_r <= #`U_DLY 1'b0;
    end
    else if ((wr_en == 1'b1) && (hit_ctrl == 1'b1)) begin
        ctrl_mode_r <= #`U_DLY i_pwdata[1];
    end
end

// CMP.VAL
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        cmp_r <= #`U_DLY 32'hFFFF_FFFF;
    end
    else if ((wr_en == 1'b1) && (hit_cmp == 1'b1)) begin
        cmp_r <= #`U_DLY i_pwdata;
    end
end

// INTR_STATE.EXPIRED：rw1c；硬件置位优先（DEC-003）
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        intr_state_r <= #`U_DLY 1'b0;
    end
    else if (i_expire == 1'b1) begin
        intr_state_r <= #`U_DLY 1'b1;
    end
    else if ((wr_en == 1'b1) && (hit_intr_state == 1'b1) && (i_pwdata[0] == 1'b1)) begin
        intr_state_r <= #`U_DLY 1'b0;
    end
end

// INTR_ENABLE.EXPIRED
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        intr_enable_r <= #`U_DLY 1'b0;
    end
    else if ((wr_en == 1'b1) && (hit_intr_enable == 1'b1)) begin
        intr_enable_r <= #`U_DLY i_pwdata[0];
    end
end

//------------------------------------------------------------------------------
// 输出
//------------------------------------------------------------------------------
// APB 零等待：PRDATA / PSLVERR 在访问阶段组合输出（05 §6 偏离 HW-33，DEC-007）
assign o_prdata      = ((access == 1'b1) && (i_pwrite == 1'b0)) ? rd_data : 32'd0;
assign o_pready      = 1'b1;
assign o_pslverr     = access & ~addr_hit;

assign o_ctrl_en     = ctrl_en_r;
assign o_ctrl_clr    = wr_en & hit_ctrl & i_pwdata[2];  // CTRL.CLR：写 1 单周期脉冲（DEC-005）
assign o_cmp_val     = cmp_r;
assign o_intr_state  = intr_state_r;
assign o_intr_enable = intr_enable_r;

endmodule
