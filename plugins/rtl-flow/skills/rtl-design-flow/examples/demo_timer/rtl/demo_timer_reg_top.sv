// -----------------------------------------------------------------------------
// Module : demo_timer_reg_top
// IP     : demo_timer  (doc: doc/05_rtl_structure.md)
// Brief  : APB3 从接口、地址译码与寄存器（04_registers、02_architecture §4）
// -----------------------------------------------------------------------------
module demo_timer_reg_top (
  input  logic        clk_i,
  input  logic        rst_ni,
  // APB3
  input  logic        psel_i,
  input  logic        penable_i,
  input  logic        pwrite_i,
  input  logic [11:0] paddr_i,
  input  logic [31:0] pwdata_i,
  output logic [31:0] prdata_o,
  output logic        pready_o,
  output logic        pslverr_o,
  // 硬件接口
  output logic        ctrl_en_o,
  output logic        ctrl_clr_o,
  output logic [31:0] cmp_val_o,
  output logic        intr_state_o,
  output logic        intr_enable_o,
  input  logic [31:0] count_val_i,
  input  logic        expire_i
);

  // 寄存器偏移，与 data/demo_timer.yaml 保持一致
  localparam logic [11:0] CtrlOffset       = 12'h000;
  localparam logic [11:0] CmpOffset        = 12'h004;
  localparam logic [11:0] CountOffset      = 12'h008;
  localparam logic [11:0] IntrStateOffset  = 12'h00C;
  localparam logic [11:0] IntrEnableOffset = 12'h010;

  localparam logic        ModeOneshot = 1'b0;

  // ---------------------------------------------------------------- 地址译码
  logic hit_ctrl, hit_cmp, hit_count, hit_intr_state, hit_intr_enable, addr_hit;

  assign hit_ctrl        = (paddr_i == CtrlOffset);
  assign hit_cmp         = (paddr_i == CmpOffset);
  assign hit_count       = (paddr_i == CountOffset);
  assign hit_intr_state  = (paddr_i == IntrStateOffset);
  assign hit_intr_enable = (paddr_i == IntrEnableOffset);
  assign addr_hit        = hit_ctrl | hit_cmp | hit_count | hit_intr_state | hit_intr_enable;

  logic access, wr_en;
  assign access = psel_i & penable_i;
  assign wr_en  = access & pwrite_i & addr_hit;

  assign pready_o  = 1'b1;
  assign pslverr_o = access & ~addr_hit;

  // ---------------------------------------------------------------- 寄存器
  logic        ctrl_en_q, ctrl_en_d;
  logic        ctrl_mode_q, ctrl_mode_d;
  logic [31:0] cmp_q, cmp_d;
  logic        intr_state_q, intr_state_d;
  logic        intr_enable_q, intr_enable_d;

  always_comb begin
    ctrl_en_d     = ctrl_en_q;
    ctrl_mode_d   = ctrl_mode_q;
    cmp_d         = cmp_q;
    intr_state_d  = intr_state_q;
    intr_enable_d = intr_enable_q;

    // CTRL.EN：单次模式到时硬件清零；软件写优先（DEC-002）
    if (expire_i && (ctrl_mode_q == ModeOneshot)) begin
      ctrl_en_d = 1'b0;
    end
    if (wr_en && hit_ctrl) begin
      ctrl_en_d   = pwdata_i[0];
      ctrl_mode_d = pwdata_i[1];
    end

    if (wr_en && hit_cmp) begin
      cmp_d = pwdata_i;
    end

    // INTR_STATE.EXPIRED：rw1c；硬件置位优先（DEC-003）
    if (wr_en && hit_intr_state && pwdata_i[0]) begin
      intr_state_d = 1'b0;
    end
    if (expire_i) begin
      intr_state_d = 1'b1;
    end

    if (wr_en && hit_intr_enable) begin
      intr_enable_d = pwdata_i[0];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ctrl_en_q     <= 1'b0;
      ctrl_mode_q   <= 1'b0;
      cmp_q         <= 32'hFFFF_FFFF;
      intr_state_q  <= 1'b0;
      intr_enable_q <= 1'b0;
    end else begin
      ctrl_en_q     <= ctrl_en_d;
      ctrl_mode_q   <= ctrl_mode_d;
      cmp_q         <= cmp_d;
      intr_state_q  <= intr_state_d;
      intr_enable_q <= intr_enable_d;
    end
  end

  // ---------------------------------------------------------------- 读数据
  always_comb begin
    prdata_o = '0;
    if (access && !pwrite_i) begin
      unique case (1'b1)
        hit_ctrl:        prdata_o = {30'd0, ctrl_mode_q, ctrl_en_q};
        hit_cmp:         prdata_o = cmp_q;
        hit_count:       prdata_o = count_val_i;
        hit_intr_state:  prdata_o = {31'd0, intr_state_q};
        hit_intr_enable: prdata_o = {31'd0, intr_enable_q};
        default:         prdata_o = '0;
      endcase
    end
  end

  assign ctrl_en_o     = ctrl_en_q;
  assign ctrl_clr_o    = wr_en & hit_ctrl & pwdata_i[2];  // CTRL.CLR：写 1 单周期脉冲（DEC-005）
  assign cmp_val_o     = cmp_q;
  assign intr_state_o  = intr_state_q;
  assign intr_enable_o = intr_enable_q;

endmodule
