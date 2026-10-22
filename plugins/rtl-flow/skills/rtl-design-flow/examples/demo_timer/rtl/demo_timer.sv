// -----------------------------------------------------------------------------
// Module : demo_timer
// IP     : demo_timer  (doc: doc/05_rtl_structure.md)
// Brief  : 顶层：APB3 32 bit 定时器，单次/周期模式，电平中断
// -----------------------------------------------------------------------------
module demo_timer (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        psel_i,
  input  logic        penable_i,
  input  logic        pwrite_i,
  input  logic [11:0] paddr_i,
  input  logic [31:0] pwdata_i,
  output logic [31:0] prdata_o,
  output logic        pready_o,
  output logic        pslverr_o,
  output logic        irq_o
);

  logic        ctrl_en, ctrl_clr;
  logic [31:0] cmp_val, count_val;
  logic        intr_state, intr_enable;
  logic        expire;

  demo_timer_reg_top u_reg_top (
    .clk_i,
    .rst_ni,
    .psel_i,
    .penable_i,
    .pwrite_i,
    .paddr_i,
    .pwdata_i,
    .prdata_o,
    .pready_o,
    .pslverr_o,
    .ctrl_en_o     (ctrl_en),
    .ctrl_clr_o    (ctrl_clr),
    .cmp_val_o     (cmp_val),
    .intr_state_o  (intr_state),
    .intr_enable_o (intr_enable),
    .count_val_i   (count_val),
    .expire_i      (expire)
  );

  demo_timer_core u_core (
    .clk_i,
    .rst_ni,
    .en_i     (ctrl_en),
    .clr_i    (ctrl_clr),
    .cmp_i    (cmp_val),
    .count_o  (count_val),
    .expire_o (expire)
  );

  // REQ-FUNC-005：电平中断
  assign irq_o = intr_state & intr_enable;

endmodule
