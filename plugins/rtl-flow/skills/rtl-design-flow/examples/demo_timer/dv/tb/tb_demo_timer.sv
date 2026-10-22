// -----------------------------------------------------------------------------
// Testbench : tb_demo_timer
// IP        : demo_timer  (doc: doc/07_dv_plan.md)
// Brief     : 自检查测试平台。定向测试 + 逐周期参考模型监视器（DEC-004）+ 功能覆盖点
// Usage     : vvp tb.vvp +TEST=<name> [+SEED=<n>]
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_demo_timer;

  localparam logic [11:0] CTRL        = 12'h000;
  localparam logic [11:0] CMP         = 12'h004;
  localparam logic [11:0] COUNT       = 12'h008;
  localparam logic [11:0] INTR_STATE  = 12'h00C;
  localparam logic [11:0] INTR_ENABLE = 12'h010;

  // ------------------------------------------------------------------ DUT
  logic        clk = 1'b0;
  logic        rst_n = 1'b0;
  logic        psel = 1'b0, penable = 1'b0, pwrite = 1'b0;
  logic [11:0] paddr = '0;
  logic [31:0] pwdata = '0;
  wire  [31:0] prdata;
  wire         pready, pslverr, irq;

  always #5 clk = ~clk;  // 100 MHz

  demo_timer dut (
    .clk_i     (clk),
    .rst_ni    (rst_n),
    .psel_i    (psel),
    .penable_i (penable),
    .pwrite_i  (pwrite),
    .paddr_i   (paddr),
    .pwdata_i  (pwdata),
    .prdata_o  (prdata),
    .pready_o  (pready),
    .pslverr_o (pslverr),
    .irq_o     (irq)
  );

  // ------------------------------------------------------------------ 结果统计
  integer errors = 0;
  string  test;

  task automatic fail(input string msg);
    errors = errors + 1;
    $display("[%0t] ERROR: %s", $time, msg);
  endtask

  // ------------------------------------------------------------------ 参考模型（按 01_spec 独立编写）
  logic        m_en, m_mode, m_st, m_ie;
  logic [31:0] m_cmp, m_cnt;
  wire         m_wr     = psel & penable & pwrite;
  wire         m_expire = m_en && (m_cnt >= m_cmp);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_en <= 1'b0; m_mode <= 1'b0; m_cmp <= 32'hFFFF_FFFF;
      m_cnt <= '0;  m_st <= 1'b0;   m_ie <= 1'b0;
    end else begin
      if (m_wr && paddr == CTRL && pwdata[2]) m_cnt <= '0;  // CTRL.CLR 优先 (REQ-FUNC-006)
      else if (m_expire) m_cnt <= '0;
      else if (m_en) m_cnt <= m_cnt + 1;

      if (m_wr && paddr == CTRL) begin  // 软件写优先 (DEC-002)
        m_en <= pwdata[0]; m_mode <= pwdata[1];
      end else if (m_expire && !m_mode) begin
        m_en <= 1'b0;
      end

      if (m_wr && paddr == CMP) m_cmp <= pwdata;

      if (m_expire) m_st <= 1'b1;  // 置位优先 (DEC-003)
      else if (m_wr && paddr == INTR_STATE && pwdata[0]) m_st <= 1'b0;

      if (m_wr && paddr == INTR_ENABLE) m_ie <= pwdata[0];
    end
  end

  function automatic logic [31:0] model_read(input logic [11:0] a);
    case (a)
      CTRL:        return {30'd0, m_mode, m_en};
      CMP:         return m_cmp;
      COUNT:       return m_cnt;
      INTR_STATE:  return {31'd0, m_st};
      INTR_ENABLE: return {31'd0, m_ie};
      default:     return 32'd0;
    endcase
  endfunction

  function automatic logic addr_valid(input logic [11:0] a);
    return a == CTRL || a == CMP || a == COUNT || a == INTR_STATE || a == INTR_ENABLE;
  endfunction

  // ------------------------------------------------------------------ 逐周期监视器（07_dv_plan §4）
  always @(negedge clk) begin
    if (!rst_n) begin
      if (irq !== 1'b0) fail("A1: irq_o not low during reset");
    end else begin
      if ((^{prdata, pready, pslverr, irq}) === 1'bx)       fail("A2: X on outputs");
      if (pready !== 1'b1)                                  fail("A3: pready_o not 1");
      if (pslverr && !(psel && penable))                    fail("A4: pslverr_o outside access phase");
      if (psel && penable && (pslverr !== !addr_valid(paddr))) fail("A5: pslverr_o mismatch");
      if (irq !== (m_st & m_ie))                            fail("A6: irq_o != EXPIRED & ENABLE");
      if (dut.count_val   !== m_cnt)  fail($sformatf("A7: COUNT dut=%0d model=%0d", dut.count_val, m_cnt));
      if (dut.ctrl_en     !== m_en)   fail($sformatf("A7: CTRL.EN dut=%0b model=%0b", dut.ctrl_en, m_en));
      if (dut.u_reg_top.ctrl_mode_q !== m_mode) fail("A7: CTRL.MODE mismatch");
      if (dut.cmp_val     !== m_cmp)  fail("A7: CMP mismatch");
      if (dut.intr_state  !== m_st)   fail("A7: INTR_STATE mismatch");
      if (dut.intr_enable !== m_ie)   fail("A7: INTR_ENABLE mismatch");
      if (dut.expire      !== m_expire) fail("A7: expire mismatch");
      if (psel && penable && !pwrite && prdata !== model_read(paddr))
        fail($sformatf("A8: read 0x%03h dut=0x%08h model=0x%08h", paddr, prdata, model_read(paddr)));
    end
  end

  // ------------------------------------------------------------------ 功能覆盖点
  integer cv_expire_oneshot = 0, cv_expire_periodic = 0, cv_set_vs_clear = 0, cv_sw_vs_hw_en = 0;
  integer cv_err_read = 0, cv_err_write = 0, cv_cmp_zero_periodic = 0, cv_cmp_below_count = 0;
  integer cv_irq_masked = 0, cv_pause_resume = 0;
  integer cv_clr_running = 0, cv_clr_stopped = 0, cv_clr_vs_expire = 0;
  logic   prev_en = 1'b0;
  logic [31:0] paused_cnt = '0;
  logic   paused = 1'b0;

  always @(posedge clk) begin
    if (rst_n) begin
      if (m_expire && !m_mode) cv_expire_oneshot++;
      if (m_expire &&  m_mode) cv_expire_periodic++;
      if (m_expire && m_wr && paddr == INTR_STATE && pwdata[0]) cv_set_vs_clear++;
      if (m_expire && !m_mode && m_wr && paddr == CTRL) cv_sw_vs_hw_en++;
      if (psel && penable && !addr_valid(paddr) && !pwrite) cv_err_read++;
      if (psel && penable && !addr_valid(paddr) &&  pwrite) cv_err_write++;
      if (m_expire && m_mode && m_cmp == 0) cv_cmp_zero_periodic++;
      if (m_wr && paddr == CMP && m_en && pwdata < m_cnt) cv_cmp_below_count++;
      if (m_st && !m_ie) cv_irq_masked++;
      if (m_wr && paddr == CTRL && pwdata[2] &&  m_en && m_cnt != 0) cv_clr_running++;
      if (m_wr && paddr == CTRL && pwdata[2] && !m_en && m_cnt != 0) cv_clr_stopped++;
      if (m_wr && paddr == CTRL && pwdata[2] && m_expire) cv_clr_vs_expire++;
      if (prev_en && !m_en && m_cnt != 0) begin paused = 1'b1; paused_cnt = m_cnt; end
      if (paused && m_en && m_cnt == paused_cnt) begin cv_pause_resume++; paused = 1'b0; end
      prev_en = m_en;
    end
  end

  task automatic report_cover();
    $display("COVER expire_oneshot=%0d",    cv_expire_oneshot);
    $display("COVER expire_periodic=%0d",   cv_expire_periodic);
    $display("COVER set_vs_clear=%0d",      cv_set_vs_clear);
    $display("COVER sw_vs_hw_en=%0d",       cv_sw_vs_hw_en);
    $display("COVER err_read=%0d",          cv_err_read);
    $display("COVER err_write=%0d",         cv_err_write);
    $display("COVER cmp_zero_periodic=%0d", cv_cmp_zero_periodic);
    $display("COVER cmp_below_count=%0d",   cv_cmp_below_count);
    $display("COVER irq_masked=%0d",        cv_irq_masked);
    $display("COVER pause_resume=%0d",      cv_pause_resume);
    $display("COVER clr_running=%0d",       cv_clr_running);
    $display("COVER clr_stopped=%0d",       cv_clr_stopped);
    $display("COVER clr_vs_expire=%0d",     cv_clr_vs_expire);
  endtask

  // ------------------------------------------------------------------ APB 任务（调用时位于 posedge 后 1 ns，返回时同样）
  task automatic apb_write(input logic [11:0] a, input logic [31:0] d, input logic exp_err);
    psel = 1'b1; pwrite = 1'b1; paddr = a; pwdata = d; penable = 1'b0;
    @(posedge clk); #1;
    penable = 1'b1;
    #1;
    if (pslverr !== exp_err) fail($sformatf("write 0x%03h: pslverr=%0b expected %0b", a, pslverr, exp_err));
    @(posedge clk); #1;
    psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
  endtask

  task automatic apb_read(input logic [11:0] a, output logic [31:0] d, input logic exp_err);
    psel = 1'b1; pwrite = 1'b0; paddr = a; penable = 1'b0;
    @(posedge clk); #1;
    penable = 1'b1;
    #1;
    d = prdata;
    if (pslverr !== exp_err) fail($sformatf("read 0x%03h: pslverr=%0b expected %0b", a, pslverr, exp_err));
    @(posedge clk); #1;
    psel = 1'b0; penable = 1'b0;
  endtask

  task automatic wr(input logic [11:0] a, input logic [31:0] d);
    apb_write(a, d, 1'b0);
  endtask

  task automatic rd_check(input logic [11:0] a, input logic [31:0] exp);
    logic [31:0] d;
    apb_read(a, d, 1'b0);
    if (d !== exp) fail($sformatf("read 0x%03h = 0x%08h, expected 0x%08h", a, d, exp));
  endtask

  task automatic idle(input integer n);
    repeat (n) @(posedge clk);
    #1;
  endtask

  // 等待到 posedge 后 1 ns 且 COUNT == v（用于构造同拍冲突）
  task automatic wait_count(input logic [31:0] v);
    while (dut.count_val !== v) begin @(posedge clk); #1; end
  endtask

  // 计数值归零：用 CMP=0 的单次模式立即到时（软件无直接清零手段，见 01_spec §9）
  task automatic zero_count();
    wr(CMP, 0);
    wr(CTRL, 32'h1);
    idle(2);
    if (dut.count_val !== 32'h0 || dut.ctrl_en !== 1'b0) fail("zero_count failed");
  endtask

  task automatic do_reset();
    rst_n = 1'b0;
    psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
    idle(3);
    rst_n = 1'b1;
    idle(1);
  endtask

  // ------------------------------------------------------------------ 测试用例
  // TP-001 复位值与复位后静止；运行中复位
  task automatic test_reset();
    rd_check(CTRL, 32'h0);
    rd_check(CMP, 32'hFFFF_FFFF);
    rd_check(COUNT, 32'h0);
    rd_check(INTR_STATE, 32'h0);
    rd_check(INTR_ENABLE, 32'h0);
    idle(50);
    rd_check(COUNT, 32'h0);
    if (irq !== 1'b0) fail("irq high after reset");
    // 运行中复位
    wr(CMP, 3); wr(INTR_ENABLE, 1); wr(CTRL, 32'h3);
    idle(20);
    if (irq !== 1'b1) fail("irq expected high before mid-run reset");
    do_reset();
    rd_check(CTRL, 32'h0);
    rd_check(CMP, 32'hFFFF_FFFF);
    rd_check(COUNT, 32'h0);
    rd_check(INTR_STATE, 32'h0);
    rd_check(INTR_ENABLE, 32'h0);
  endtask

  // TP-002 寄存器读写与只读属性
  task automatic test_reg_rw();
    wr(CTRL, 32'hFFFF_FFFE);    rd_check(CTRL, 32'h2);      // 只有 [1:0] 有效，EN=0
    wr(CTRL, 32'h0);            rd_check(CTRL, 32'h0);
    wr(CMP, 32'hA5A5_A5A5);     rd_check(CMP, 32'hA5A5_A5A5);
    wr(CMP, 32'h5A5A_5A5A);     rd_check(CMP, 32'h5A5A_5A5A);
    wr(INTR_ENABLE, 32'hFFFF_FFFF); rd_check(INTR_ENABLE, 32'h1);
    wr(INTR_ENABLE, 32'h0);     rd_check(INTR_ENABLE, 32'h0);
    wr(COUNT, 32'h1234);        rd_check(COUNT, 32'h0);     // 只读
    wr(INTR_STATE, 32'h0);      rd_check(INTR_STATE, 32'h0);
  endtask

  // TP-003 非法 / 非对齐地址
  task automatic test_apb_err();
    logic [31:0] d;
    logic [11:0] bad [0:5];
    bad[0] = 12'h014; bad[1] = 12'h100; bad[2] = 12'hFFC;
    bad[3] = 12'h001; bad[4] = 12'h002; bad[5] = 12'h006;
    for (int i = 0; i < 6; i++) begin
      apb_read(bad[i], d, 1'b1);
      if (d !== 32'h0) fail($sformatf("error read 0x%03h returned 0x%08h", bad[i], d));
      apb_write(bad[i], 32'hDEAD_BEEF, 1'b1);
    end
    rd_check(CTRL, 32'h0);
    rd_check(CMP, 32'hFFFF_FFFF);
    rd_check(INTR_ENABLE, 32'h0);
  endtask

  // 启动后测量到 irq 拉高经过的时钟沿数（调用前需已使能中断）
  task automatic measure_irq(output integer k);
    k = 0;
    while (irq !== 1'b1 && k < 10000) begin @(posedge clk); #1; k++; end
  endtask

  // TP-004 单次模式：到时时刻、EN 自动清零、不再触发、可重新启动
  task automatic test_oneshot();
    integer k, n0;
    logic [31:0] cmps [0:2];
    cmps[0] = 9; cmps[1] = 0; cmps[2] = 37;
    wr(INTR_ENABLE, 1);
    for (int i = 0; i < 3; i++) begin
      wr(CMP, cmps[i]);
      wr(CTRL, 32'h1);                         // ONESHOT, EN=1
      measure_irq(k);
      if (k != cmps[i] + 1) fail($sformatf("oneshot CMP=%0d: irq after %0d edges, expected %0d", cmps[i], k, cmps[i] + 1));
      rd_check(CTRL, 32'h0);                   // EN 已被硬件清零
      rd_check(COUNT, 32'h0);
      rd_check(INTR_STATE, 32'h1);
      n0 = cv_expire_oneshot;
      idle(3 * cmps[i] + 10);
      if (cv_expire_oneshot != n0) fail("oneshot fired again while stopped");
      wr(INTR_STATE, 1);
      if (irq !== 1'b0) fail("irq not cleared");
    end
  endtask

  // TP-005 中断屏蔽、轮询、W1C 语义
  task automatic test_irq();
    wr(CMP, 4);
    wr(CTRL, 32'h1);
    idle(10);
    if (irq !== 1'b0) fail("irq high while INTR_ENABLE=0");
    rd_check(INTR_STATE, 32'h1);               // 可轮询
    wr(INTR_ENABLE, 1);
    if (irq !== 1'b1) fail("irq not high after enable");
    wr(INTR_STATE, 32'h0);                     // 写 0 无效
    if (irq !== 1'b1) fail("write 0 cleared INTR_STATE");
    wr(INTR_ENABLE, 0);
    if (irq !== 1'b0) fail("irq high after disable");
    rd_check(INTR_STATE, 32'h1);
    wr(INTR_ENABLE, 1);
    wr(INTR_STATE, 32'h1);                     // W1C
    if (irq !== 1'b0) fail("irq high after W1C");
    rd_check(INTR_STATE, 32'h0);
  endtask

  // TP-006 周期模式：周期 = CMP+1；暂停与恢复
  task automatic test_periodic();
    integer last, cnt, now;
    logic [31:0] cmps [0:2];
    logic [31:0] held;
    logic [31:0] d;
    cmps[0] = 4; cmps[1] = 0; cmps[2] = 13;
    for (int i = 0; i < 3; i++) begin
      zero_count();
      wr(CMP, cmps[i]);
      wr(CTRL, 32'h3);                         // PERIODIC, EN=1
      last = -1; cnt = 0; now = 0;
      while (cnt < 6) begin                    // 测量相邻到时事件间隔
        @(posedge clk); #1; now++;
        if (dut.expire) begin
          if (last >= 0 && now - last != cmps[i] + 1)
            fail($sformatf("periodic CMP=%0d: interval %0d, expected %0d", cmps[i], now - last, cmps[i] + 1));
          last = now; cnt++;
        end
      end
      rd_check(CTRL, 32'h3);                   // EN 保持
    end
    // 暂停/恢复
    wr(CMP, 1000);
    idle(20);
    wr(CTRL, 32'h2);                           // 暂停
    apb_read(COUNT, held, 1'b0);
    idle(10);
    rd_check(COUNT, held);
    wr(CTRL, 32'h3);                           // 恢复
    idle(5);
    apb_read(COUNT, d, 1'b0);
    if (d <= held) fail("count did not resume from held value");
    wr(CTRL, 32'h0);
  endtask

  // TP-007 边界：运行中把 CMP 改到计数值以下立即到时 (DEC-001)
  task automatic test_cmp_boundary();
    integer n0;
    wr(INTR_ENABLE, 1);
    wr(CMP, 1000);
    wr(CTRL, 32'h3);
    idle(50);
    n0 = cv_expire_periodic;
    wr(CMP, 10);                               // 写入沿之后的第一拍即应到时
    if (dut.expire !== 1'b1) fail("expire not immediate after CMP lowered below COUNT");
    @(posedge clk); #1;
    if (cv_expire_periodic != n0 + 1) fail("expected exactly one immediate expire");
    rd_check(INTR_STATE, 32'h1);
    wr(CTRL, 32'h0);
  endtask

  // TP-008 同拍冲突优先级 (DEC-002, DEC-003)
  task automatic test_priority();
    integer k;
    // DEC-003：W1C 与到时同拍，置位优先
    wr(CMP, 9);
    wr(CTRL, 32'h3);
    wait_count(8);                             // 建立周期 COUNT=8，访问周期 COUNT=9=CMP
    wr(INTR_STATE, 1);
    if (dut.intr_state !== 1'b1) fail("DEC-003: clear won over set");
    wr(CTRL, 32'h0);
    wr(INTR_STATE, 1);                         // 非同拍时可正常清除
    if (dut.intr_state !== 1'b0) fail("normal W1C failed");
    // DEC-002：单次模式到时与软件写 CTRL 同拍，软件优先
    zero_count();
    wr(CMP, 9);
    wr(CTRL, 32'h1);
    wait_count(8);
    wr(CTRL, 32'h1);                           // 访问周期恰为到时周期
    if (dut.ctrl_en !== 1'b1) fail("DEC-002: HW clear won over SW write");
    if (dut.count_val !== 32'h0) fail("DEC-002: count not restarted from 0");
    k = 0;                                     // 重新计时：9 个沿后 COUNT=9=CMP 再次到时
    while (!dut.expire && k < 100) begin @(posedge clk); #1; k++; end
    if (k != 9) fail($sformatf("DEC-002 restart: expire after %0d edges, expected 9", k));
  endtask

  // TP-011 计数清零 CTRL.CLR (REQ-FUNC-006, DEC-005)
  task automatic test_clr();
    logic [31:0] ctrl;
    // 运行中清零：下一周期为 0 并继续计数，CLR 读为 0，不影响中断状态
    wr(CMP, 1000);
    wr(CTRL, 32'h3);
    idle(50);
    apb_read(CTRL, ctrl, 1'b0);
    wr(CTRL, ctrl | 32'h4);                    // 读-改-写
    if (dut.count_val !== 32'h0) fail("CLR while running: count not 0");
    idle(5);
    rd_check(COUNT, 32'd6);                    // 写入沿后 5 个沿 + 建立周期到访问周期的 1 个沿
    rd_check(CTRL, 32'h3);
    rd_check(INTR_STATE, 32'h0);
    // 停止时清零：变为 0 并保持
    wr(CTRL, 32'h2);
    wr(CTRL, 32'h6);
    idle(10);
    rd_check(COUNT, 32'h0);
    rd_check(CTRL, 32'h2);
    // 与到时同拍：计数归零，到时仍置位中断状态
    wr(CMP, 9);
    wr(CTRL, 32'h3);
    wait_count(8);
    wr(CTRL, 32'h7);
    if (dut.count_val !== 32'h0) fail("CLR vs expire: count not 0");
    if (dut.intr_state !== 1'b1) fail("CLR vs expire: EXPIRED not set");
    // 清零不清除已置位的中断状态
    wr(CTRL, 32'h6);
    rd_check(INTR_STATE, 32'h1);
  endtask

  // TP-009 随机激励 + 参考模型
  task automatic test_random(input integer seed);
    integer s, n, op, gap;
    logic [11:0] a;
    logic [31:0] d;
    s = seed;
    for (n = 0; n < 3000; n++) begin
      op = $unsigned($random(s)) % 100;
      case ($unsigned($random(s)) % 6)
        0: a = CTRL; 1: a = CMP; 2: a = COUNT; 3: a = INTR_STATE; 4: a = INTR_ENABLE;
        // 非法地址：越界地址，或合法寄存器偏移 + 1~3 的非对齐地址（ITR-003）
        default: a = ($unsigned($random(s)) % 2) ? 12'h014 + 4 * ($unsigned($random(s)) % 8)
                                                 : 4 * ($unsigned($random(s)) % 5) + 1 + $unsigned($random(s)) % 3;
      endcase
      d = $random(s);
      if (a == CMP) d = d % 24;                // 小比较值以产生大量到时事件
      if (op < 50) apb_write(a, d, !addr_valid(a));
      else         apb_read(a, d, !addr_valid(a));
      gap = $unsigned($random(s)) % 4;
      if (gap) idle(gap);
    end
  endtask

  // ------------------------------------------------------------------ 主流程
  initial begin
    integer seed;
    if (!$value$plusargs("TEST=%s", test)) test = "test_reset";
    if (!$value$plusargs("SEED=%d", seed)) seed = 1;
    do_reset();
    // iverilog 不支持对 string 使用 case，改用 if 链（见 ITR-002）
    if      (test == "test_reset")        test_reset();
    else if (test == "test_reg_rw")       test_reg_rw();
    else if (test == "test_apb_err")      test_apb_err();
    else if (test == "test_oneshot")      test_oneshot();
    else if (test == "test_irq")          test_irq();
    else if (test == "test_periodic")     test_periodic();
    else if (test == "test_cmp_boundary") test_cmp_boundary();
    else if (test == "test_priority")     test_priority();
    else if (test == "test_random")       test_random(seed);
    else if (test == "test_clr")          test_clr();
    else fail($sformatf("unknown test %s", test));
    idle(5);
    report_cover();
    $display("TEST %s SEED %0d %s errors=%0d", test, seed, errors ? "FAILED" : "PASSED", errors);
    $finish;
  end

  initial begin
    #5_000_000;  // 5 ms
    fail("timeout");
    $display("TEST %s FAILED errors=%0d", test, errors);
    $finish;
  end

endmodule
