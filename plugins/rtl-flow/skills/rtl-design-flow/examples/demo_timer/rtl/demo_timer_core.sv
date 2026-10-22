// -----------------------------------------------------------------------------
// Module : demo_timer_core
// IP     : demo_timer  (doc: doc/05_rtl_structure.md)
// Brief  : 32 bit 递增计数器与到时比较（02_architecture §3、§4）
// -----------------------------------------------------------------------------
module demo_timer_core (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        en_i,      // CTRL.EN
  input  logic        clr_i,     // CTRL.CLR 写 1 脉冲
  input  logic [31:0] cmp_i,     // CMP.VAL
  output logic [31:0] count_o,   // COUNT.VAL
  output logic        expire_o   // 到时事件，单周期脉冲
);

  logic [31:0] count_q, count_d;

  // DEC-001：使用 >= 比较
  assign expire_o = en_i && (count_q >= cmp_i);

  always_comb begin
    count_d = count_q;
    if (clr_i || expire_o) begin  // 清零优先级最高（REQ-FUNC-006）
      count_d = '0;
    end else if (en_i) begin
      count_d = count_q + 32'd1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      count_q <= '0;
    end else begin
      count_q <= count_d;
    end
  end

  assign count_o = count_q;

endmodule
