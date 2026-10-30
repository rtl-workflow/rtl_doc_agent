`timescale 1ns / 1ps
//==============================================================================
// File name   : demo_timer_tb.v
// Module name : demo_timer_tb
// Function    : 黑盒自检查测试平台，只通过顶层端口访问 DUT。
//               定向测试 + 参考模型 + 逐周期端口监视器（DEC-004）+ 功能覆盖点
// Version     : 2.1
// Date        : 2026-10-25
// Doc         : doc/07_dv_plan.md
// Usage       : vvp tb.vvp +TEST=<name> [+SEED=<n>]
//==============================================================================
module demo_timer_tb;

localparam ADDR_CTRL        = 12'h000;
localparam ADDR_CMP         = 12'h004;
localparam ADDR_COUNT       = 12'h008;
localparam ADDR_INTR_STATE  = 12'h00C;
localparam ADDR_INTR_ENABLE = 12'h010;

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
reg             clk     = 1'b0;
reg             rst     = 1'b0;   // 低有效（data/demo_timer.yaml resets）
reg             psel    = 1'b0;
reg             penable = 1'b0;
reg             pwrite  = 1'b0;
reg     [11:0]  paddr   = 12'd0;
reg     [31:0]  pwdata  = 32'd0;
wire    [31:0]  prdata;
wire            pready;
wire            pslverr;
wire            irq;

always #5 clk = ~clk;  // 100 MHz

// 驱动与采样点：posedge 后 2 ns，晚于 RTL 输出变化（时钟沿后 1 ns，rtl-coding-style HW-50 / §10）
localparam TB_SKEW = 2;

demo_timer U_dut (
    .clk        (clk        ),
    .rst        (rst        ),
    .i_psel     (psel       ),
    .i_penable  (penable    ),
    .i_pwrite   (pwrite     ),
    .i_paddr    (paddr      ),
    .i_pwdata   (pwdata     ),
    .o_prdata   (prdata     ),
    .o_pready   (pready     ),
    .o_pslverr  (pslverr    ),
    .o_irq      (irq        )
);

//------------------------------------------------------------------------------
// 结果统计
//------------------------------------------------------------------------------
integer         errors = 0;
reg [8*32-1:0]  test;
reg [8*100-1:0] mon_msg;            // 监视器报错信息
reg [8*100-1:0] tst_msg;            // 测试用例报错信息
integer         cyc = 0;            // 复位释放后的时钟沿计数，用于测量时间间隔

always @(posedge clk) begin
    if (rst == 1'b1) cyc <= cyc + 1;
end

// 只打印前 100 条错误（如 --stub 下每拍都报错），计数不受影响
task automatic fail(input [8*100-1:0] msg);
    begin
        errors = errors + 1;
        if (errors <= 100) $display("[%0t] ERROR: %0s", $time, msg);
        if (errors == 100) $display("[%0t] (further errors not printed)", $time);
    end
endtask

//------------------------------------------------------------------------------
// 参考模型（按 01_spec 独立编写）
//------------------------------------------------------------------------------
reg             m_en;
reg             m_mode;
reg             m_st;
reg             m_ie;
reg     [31:0]  m_cmp;
reg     [31:0]  m_cnt;
wire            m_wr     = psel & penable & pwrite;
wire            m_expire = m_en && (m_cnt >= m_cmp);

always @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        m_en <= 1'b0; m_mode <= 1'b0; m_cmp <= 32'hFFFF_FFFF;
        m_cnt <= 32'd0; m_st <= 1'b0; m_ie <= 1'b0;
    end
    else begin
        if (m_wr && paddr == ADDR_CTRL && pwdata[2]) m_cnt <= 32'd0;  // CTRL.CLR 优先 (REQ-FUNC-006)
        else if (m_expire) m_cnt <= 32'd0;
        else if (m_en) m_cnt <= m_cnt + 32'd1;

        if (m_wr && paddr == ADDR_CTRL) begin  // 软件写优先 (DEC-002)
            m_en <= pwdata[0]; m_mode <= pwdata[1];
        end
        else if (m_expire && !m_mode) begin
            m_en <= 1'b0;
        end

        if (m_wr && paddr == ADDR_CMP) m_cmp <= pwdata;

        if (m_expire) m_st <= 1'b1;  // 置位优先 (DEC-003)
        else if (m_wr && paddr == ADDR_INTR_STATE && pwdata[0]) m_st <= 1'b0;

        if (m_wr && paddr == ADDR_INTR_ENABLE) m_ie <= pwdata[0];
    end
end

function [31:0] model_read(input [11:0] a);
    case (a)
        ADDR_CTRL        : model_read = {30'd0, m_mode, m_en};
        ADDR_CMP         : model_read = m_cmp;
        ADDR_COUNT       : model_read = m_cnt;
        ADDR_INTR_STATE  : model_read = {31'd0, m_st};
        ADDR_INTR_ENABLE : model_read = {31'd0, m_ie};
        default          : model_read = 32'd0;
    endcase
endfunction

function addr_valid(input [11:0] a);
    addr_valid = (a == ADDR_CTRL) || (a == ADDR_CMP) || (a == ADDR_COUNT) ||
                 (a == ADDR_INTR_STATE) || (a == ADDR_INTR_ENABLE);
endfunction

//------------------------------------------------------------------------------
// 逐周期监视器（07_dv_plan §4）：只观测顶层端口，内部状态经 APB 读（A7）与 o_irq（A6）比对
//------------------------------------------------------------------------------
always @(negedge clk) begin
    if (rst == 1'b0) begin
        // clk = 1'b0 at declaration is an X->0 edge at time 0, before the DUT's asynchronous reset may
        // have been evaluated (VCS); the first real falling edge is at 10 ns
        if ($time != 0 && irq !== 1'b0) fail("A1: o_irq not low during reset");
    end
    else begin
        if ((^{prdata, pready, pslverr, irq}) === 1'bx)         fail("A2: X on outputs");
        if (pready !== 1'b1)                                    fail("A3: o_pready not 1");
        if (pslverr && !(psel && penable))                      fail("A4: o_pslverr outside access phase");
        if (psel && penable && (pslverr !== !addr_valid(paddr))) fail("A5: o_pslverr mismatch");
        if (irq !== (m_st & m_ie))                              fail("A6: o_irq != EXPIRED & ENABLE");
        if (psel && penable && !pwrite && prdata !== model_read(paddr)) begin
            $sformat(mon_msg, "A7: read 0x%03h dut=0x%08h model=0x%08h", paddr, prdata, model_read(paddr));
            fail(mon_msg);
        end
    end
end

//------------------------------------------------------------------------------
// 功能覆盖点
//------------------------------------------------------------------------------
integer cv_expire_oneshot = 0, cv_expire_periodic = 0, cv_set_vs_clear = 0, cv_sw_vs_hw_en = 0;
integer cv_err_read = 0, cv_err_write = 0, cv_cmp_zero_periodic = 0, cv_cmp_below_count = 0;
integer cv_irq_masked = 0, cv_pause_resume = 0;
integer cv_clr_running = 0, cv_clr_stopped = 0, cv_clr_vs_expire = 0;
reg             prev_en    = 1'b0;
reg     [31:0]  paused_cnt = 32'd0;
reg             paused     = 1'b0;

always @(posedge clk) begin
    if (rst == 1'b1) begin
        if (m_expire && !m_mode) cv_expire_oneshot = cv_expire_oneshot + 1;
        if (m_expire &&  m_mode) cv_expire_periodic = cv_expire_periodic + 1;
        if (m_expire && m_wr && paddr == ADDR_INTR_STATE && pwdata[0]) cv_set_vs_clear = cv_set_vs_clear + 1;
        if (m_expire && !m_mode && m_wr && paddr == ADDR_CTRL) cv_sw_vs_hw_en = cv_sw_vs_hw_en + 1;
        if (psel && penable && !addr_valid(paddr) && !pwrite) cv_err_read = cv_err_read + 1;
        if (psel && penable && !addr_valid(paddr) &&  pwrite) cv_err_write = cv_err_write + 1;
        if (m_expire && m_mode && m_cmp == 0) cv_cmp_zero_periodic = cv_cmp_zero_periodic + 1;
        if (m_wr && paddr == ADDR_CMP && m_en && pwdata < m_cnt) cv_cmp_below_count = cv_cmp_below_count + 1;
        if (m_st && !m_ie) cv_irq_masked = cv_irq_masked + 1;
        if (m_wr && paddr == ADDR_CTRL && pwdata[2] &&  m_en && m_cnt != 0) cv_clr_running = cv_clr_running + 1;
        if (m_wr && paddr == ADDR_CTRL && pwdata[2] && !m_en && m_cnt != 0) cv_clr_stopped = cv_clr_stopped + 1;
        if (m_wr && paddr == ADDR_CTRL && pwdata[2] && m_expire) cv_clr_vs_expire = cv_clr_vs_expire + 1;
        if (prev_en && !m_en && m_cnt != 0) begin paused = 1'b1; paused_cnt = m_cnt; end
        if (paused && m_en && m_cnt == paused_cnt) begin cv_pause_resume = cv_pause_resume + 1; paused = 1'b0; end
        prev_en = m_en;
    end
end

task report_cover;
    begin
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
    end
endtask

//------------------------------------------------------------------------------
// APB 任务（调用时位于 posedge 后 TB_SKEW，返回时同样）
//------------------------------------------------------------------------------
task automatic apb_write(input [11:0] a, input [31:0] d, input exp_err);
    begin
        psel = 1'b1; pwrite = 1'b1; paddr = a; pwdata = d; penable = 1'b0;
        @(posedge clk); #TB_SKEW;
        penable = 1'b1;
        #1;
        if (pslverr !== exp_err) begin
            $sformat(tst_msg, "write 0x%03h: pslverr=%0b expected %0b", a, pslverr, exp_err);
            fail(tst_msg);
        end
        @(posedge clk); #TB_SKEW;
        psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
    end
endtask

task automatic apb_read(input [11:0] a, output [31:0] d, input exp_err);
    begin
        psel = 1'b1; pwrite = 1'b0; paddr = a; penable = 1'b0;
        @(posedge clk); #TB_SKEW;
        penable = 1'b1;
        #1;
        d = prdata;
        if (pslverr !== exp_err) begin
            $sformat(tst_msg, "read 0x%03h: pslverr=%0b expected %0b", a, pslverr, exp_err);
            fail(tst_msg);
        end
        @(posedge clk); #TB_SKEW;
        psel = 1'b0; penable = 1'b0;
    end
endtask

task automatic wr(input [11:0] a, input [31:0] d);
    apb_write(a, d, 1'b0);
endtask

task automatic rd_check(input [11:0] a, input [31:0] exp);
    reg [31:0] d;
    begin
        apb_read(a, d, 1'b0);
        if (d !== exp) begin
            $sformat(tst_msg, "read 0x%03h = 0x%08h, expected 0x%08h", a, d, exp);
            fail(tst_msg);
        end
    end
endtask

task automatic idle(input integer n);
    begin
        repeat (n) @(posedge clk);
        #TB_SKEW;
    end
endtask

// 等待到 posedge 后 TB_SKEW 且参考模型 COUNT == v（用于构造同拍冲突）。
// DUT 内部计数值不可见，按参考模型对齐；DUT 若偏离，后续检查与 A7 会报错
task automatic wait_count(input [31:0] v);
    integer k;
    begin
        k = 0;
        while (m_cnt !== v && k < 10000) begin @(posedge clk); #TB_SKEW; k = k + 1; end
        if (m_cnt !== v) fail("wait_count timeout");
    end
endtask

// 计数值归零：用 CMP=0 的单次模式立即到时（会置位 INTR_STATE.EXPIRED）
task automatic zero_count;
    begin
        wr(ADDR_CMP, 32'd0);
        wr(ADDR_CTRL, 32'h1);
        idle(2);
        rd_check(ADDR_COUNT, 32'h0);
        rd_check(ADDR_CTRL, 32'h0);
    end
endtask

// 等待 o_irq 拉高，返回经过的时钟沿数（调用前需已使能中断）
task automatic measure_irq(output integer k);
    begin
        k = 0;
        while (irq !== 1'b1 && k < 10000) begin @(posedge clk); #TB_SKEW; k = k + 1; end
    end
endtask

task automatic do_reset;
    begin
        rst = 1'b0;
        psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
        idle(3);
        rst = 1'b1;
        idle(1);
    end
endtask

//------------------------------------------------------------------------------
// 测试用例
//------------------------------------------------------------------------------
// TP-001 复位值与复位后静止；运行中复位
task automatic test_reset;
    begin
        rd_check(ADDR_CTRL, 32'h0);
        rd_check(ADDR_CMP, 32'hFFFF_FFFF);
        rd_check(ADDR_COUNT, 32'h0);
        rd_check(ADDR_INTR_STATE, 32'h0);
        rd_check(ADDR_INTR_ENABLE, 32'h0);
        idle(50);
        rd_check(ADDR_COUNT, 32'h0);
        if (irq !== 1'b0) fail("irq high after reset");
        // 运行中复位
        wr(ADDR_CMP, 32'd3); wr(ADDR_INTR_ENABLE, 32'd1); wr(ADDR_CTRL, 32'h3);
        idle(20);
        if (irq !== 1'b1) fail("irq expected high before mid-run reset");
        do_reset;
        rd_check(ADDR_CTRL, 32'h0);
        rd_check(ADDR_CMP, 32'hFFFF_FFFF);
        rd_check(ADDR_COUNT, 32'h0);
        rd_check(ADDR_INTR_STATE, 32'h0);
        rd_check(ADDR_INTR_ENABLE, 32'h0);
    end
endtask

// TP-002 寄存器读写与只读属性
task automatic test_reg_rw;
    begin
        wr(ADDR_CTRL, 32'hFFFF_FFFE);        rd_check(ADDR_CTRL, 32'h2);        // 只有 [1:0] 有效，EN=0
        wr(ADDR_CTRL, 32'h0);                rd_check(ADDR_CTRL, 32'h0);
        wr(ADDR_CMP, 32'hA5A5_A5A5);         rd_check(ADDR_CMP, 32'hA5A5_A5A5);
        wr(ADDR_CMP, 32'h5A5A_5A5A);         rd_check(ADDR_CMP, 32'h5A5A_5A5A);
        wr(ADDR_INTR_ENABLE, 32'hFFFF_FFFF); rd_check(ADDR_INTR_ENABLE, 32'h1);
        wr(ADDR_INTR_ENABLE, 32'h0);         rd_check(ADDR_INTR_ENABLE, 32'h0);
        wr(ADDR_COUNT, 32'h1234);            rd_check(ADDR_COUNT, 32'h0);       // 只读
        wr(ADDR_INTR_STATE, 32'h0);          rd_check(ADDR_INTR_STATE, 32'h0);
    end
endtask

// TP-003 非法 / 非对齐地址
function [11:0] bad_addr(input [2:0] i);
    case (i)
        3'd0    : bad_addr = 12'h014;
        3'd1    : bad_addr = 12'h100;
        3'd2    : bad_addr = 12'hFFC;
        3'd3    : bad_addr = 12'h001;
        3'd4    : bad_addr = 12'h002;
        default : bad_addr = 12'h006;
    endcase
endfunction

task automatic test_apb_err;
    reg [31:0] d;
    integer i;
    begin
        for (i = 0; i < 6; i = i + 1) begin
            apb_read(bad_addr(i), d, 1'b1);
            if (d !== 32'h0) begin
                $sformat(tst_msg, "error read 0x%03h returned 0x%08h", bad_addr(i), d);
                fail(tst_msg);
            end
            apb_write(bad_addr(i), 32'hDEAD_BEEF, 1'b1);
        end
        rd_check(ADDR_CTRL, 32'h0);
        rd_check(ADDR_CMP, 32'hFFFF_FFFF);
        rd_check(ADDR_INTR_ENABLE, 32'h0);
    end
endtask

// TP-004 单次模式：到时时刻、EN 自动清零、不再触发、可重新启动
function [31:0] oneshot_cmp(input [1:0] i);
    case (i)
        2'd0    : oneshot_cmp = 32'd9;
        2'd1    : oneshot_cmp = 32'd0;
        default : oneshot_cmp = 32'd37;
    endcase
endfunction

task automatic test_oneshot;
    integer i, k;
    reg [31:0] cmp;
    begin
        wr(ADDR_INTR_ENABLE, 32'd1);
        for (i = 0; i < 3; i = i + 1) begin
            cmp = oneshot_cmp(i);
            wr(ADDR_CMP, cmp);
            wr(ADDR_CTRL, 32'h1);                   // ONESHOT, EN=1
            measure_irq(k);
            if (k != cmp + 1) begin
                $sformat(tst_msg, "oneshot CMP=%0d: irq after %0d edges, expected %0d", cmp, k, cmp + 1);
                fail(tst_msg);
            end
            rd_check(ADDR_CTRL, 32'h0);             // EN 已被硬件清零
            rd_check(ADDR_COUNT, 32'h0);
            rd_check(ADDR_INTR_STATE, 32'h1);
            wr(ADDR_INTR_STATE, 32'd1);
            if (irq !== 1'b0) fail("irq not cleared");
            idle(3 * cmp + 10);                     // 停止后不再到时
            if (irq !== 1'b0) fail("oneshot fired again while stopped");
            rd_check(ADDR_INTR_STATE, 32'h0);
            rd_check(ADDR_COUNT, 32'h0);
        end
    end
endtask

// TP-005 中断屏蔽、轮询、W1C 语义
task automatic test_irq;
    begin
        wr(ADDR_CMP, 32'd4);
        wr(ADDR_CTRL, 32'h1);
        idle(10);
        if (irq !== 1'b0) fail("irq high while INTR_ENABLE=0");
        rd_check(ADDR_INTR_STATE, 32'h1);           // 可轮询
        wr(ADDR_INTR_ENABLE, 32'd1);
        if (irq !== 1'b1) fail("irq not high after enable");
        wr(ADDR_INTR_STATE, 32'h0);                 // 写 0 无效
        if (irq !== 1'b1) fail("write 0 cleared INTR_STATE");
        wr(ADDR_INTR_ENABLE, 32'd0);
        if (irq !== 1'b0) fail("irq high after disable");
        rd_check(ADDR_INTR_STATE, 32'h1);
        wr(ADDR_INTR_ENABLE, 32'd1);
        wr(ADDR_INTR_STATE, 32'h1);                 // W1C
        if (irq !== 1'b0) fail("irq high after W1C");
        rd_check(ADDR_INTR_STATE, 32'h0);
    end
endtask

// TP-006 周期模式：周期 = CMP+1；暂停与恢复
function [31:0] periodic_cmp(input [1:0] i);
    case (i)
        2'd0    : periodic_cmp = 32'd4;
        2'd1    : periodic_cmp = 32'd0;
        default : periodic_cmp = 32'd13;
    endcase
endfunction

task automatic test_periodic;
    integer i, k, last, cnt;
    reg [31:0] cmp;
    reg [31:0] held;
    reg [31:0] d;
    begin
        wr(ADDR_INTR_ENABLE, 32'd1);
        for (i = 0; i < 3; i = i + 1) begin
            cmp = periodic_cmp(i);
            zero_count;
            wr(ADDR_INTR_STATE, 32'd1);             // 清除 zero_count 产生的到时状态
            wr(ADDR_CMP, cmp);
            wr(ADDR_CTRL, 32'h3);                   // PERIODIC, EN=1
            if (cmp == 0) begin
                // 每拍到时：COUNT 恒为 0；W1C 每拍都与到时同拍，EXPIRED 无法清除 (DEC-003)
                idle(10);
                rd_check(ADDR_COUNT, 32'h0);
                rd_check(ADDR_COUNT, 32'h0);
                wr(ADDR_INTR_STATE, 32'd1);
                rd_check(ADDR_INTR_STATE, 32'h1);
            end
            else begin
                // 测量相邻两次 o_irq 上升沿的间隔；每次拉高后立即 W1C（2 拍，小于周期）
                last = -1; cnt = 0;
                while (cnt < 6) begin
                    measure_irq(k);
                    if (irq !== 1'b1) fail("periodic: irq timeout");
                    if (last >= 0 && cyc - last != cmp + 1) begin
                        $sformat(tst_msg, "periodic CMP=%0d: interval %0d, expected %0d", cmp, cyc - last, cmp + 1);
                        fail(tst_msg);
                    end
                    last = cyc; cnt = cnt + 1;
                    wr(ADDR_INTR_STATE, 32'd1);
                end
            end
            rd_check(ADDR_CTRL, 32'h3);             // EN 保持
        end
        // 暂停/恢复
        wr(ADDR_CMP, 32'd1000);
        idle(20);
        wr(ADDR_CTRL, 32'h2);                       // 暂停
        apb_read(ADDR_COUNT, held, 1'b0);
        idle(10);
        rd_check(ADDR_COUNT, held);
        wr(ADDR_CTRL, 32'h3);                       // 恢复
        idle(5);
        apb_read(ADDR_COUNT, d, 1'b0);
        if (d <= held) fail("count did not resume from held value");
        wr(ADDR_CTRL, 32'h0);
    end
endtask

// TP-007 边界：运行中把 CMP 改到计数值以下立即到时 (DEC-001)
task automatic test_cmp_boundary;
    begin
        wr(ADDR_INTR_ENABLE, 32'd1);
        wr(ADDR_CMP, 32'd1000);
        wr(ADDR_CTRL, 32'h3);
        idle(50);
        wr(ADDR_CMP, 32'd10);                       // 写入沿之后的第一拍即应到时
        if (irq !== 1'b0) fail("expired before CMP write took effect");
        @(posedge clk); #TB_SKEW;                   // 到时在下一个沿置位 EXPIRED
        if (irq !== 1'b1) fail("expire not immediate after CMP lowered below COUNT");
        wr(ADDR_INTR_STATE, 32'd1);                 // 计数已归零，只到时一次，W1C 应能清除
        rd_check(ADDR_INTR_STATE, 32'h0);
        wr(ADDR_CTRL, 32'h0);
    end
endtask

// TP-008 同拍冲突优先级 (DEC-002, DEC-003)
task automatic test_priority;
    integer k, t0;
    reg [31:0] d;
    begin
        // DEC-003：W1C 与到时同拍，置位优先
        wr(ADDR_CMP, 32'd9);
        wr(ADDR_CTRL, 32'h3);
        wait_count(32'd8);                          // 建立周期 COUNT=8，访问周期 COUNT=9=CMP
        wr(ADDR_INTR_STATE, 32'd1);
        apb_read(ADDR_INTR_STATE, d, 1'b0);
        if (d !== 32'h1) fail("DEC-003: clear won over set");
        wr(ADDR_CTRL, 32'h0);
        wr(ADDR_INTR_STATE, 32'd1);                 // 非同拍时可正常清除
        apb_read(ADDR_INTR_STATE, d, 1'b0);
        if (d !== 32'h0) fail("normal W1C failed");
        // DEC-002：单次模式到时与软件写 CTRL 同拍，软件优先
        zero_count;
        wr(ADDR_CMP, 32'd9);
        wr(ADDR_CTRL, 32'h1);
        wait_count(32'd8);
        wr(ADDR_CTRL, 32'h1);                       // 访问周期恰为到时周期
        t0 = cyc;                                   // 写入沿：计数归零并重新计时
        apb_read(ADDR_CTRL, d, 1'b0);
        if (d !== 32'h1) fail("DEC-002: HW clear won over SW write");
        wr(ADDR_INTR_STATE, 32'd1);                 // 清除同拍到时置位的状态，再开中断
        wr(ADDR_INTR_ENABLE, 32'd1);
        measure_irq(k);                             // COUNT 0..9，第 CMP+1 = 10 个沿置位 EXPIRED
        if (cyc - t0 != 10) begin
            $sformat(tst_msg, "DEC-002 restart: irq %0d edges after write, expected 10", cyc - t0);
            fail(tst_msg);
        end
    end
endtask

// TP-011 计数清零 CTRL.CLR (REQ-FUNC-006, DEC-005)
task automatic test_clr;
    reg [31:0] ctrl;
    begin
        // 运行中清零：下一周期为 0 并继续计数，CLR 读为 0，不影响中断状态
        wr(ADDR_CMP, 32'd1000);
        wr(ADDR_CTRL, 32'h3);
        idle(50);
        apb_read(ADDR_CTRL, ctrl, 1'b0);
        wr(ADDR_CTRL, ctrl | 32'h4);                // 读-改-写，写入沿归零
        idle(5);
        rd_check(ADDR_COUNT, 32'd6);                // 写入沿后 5 个沿 + 建立周期到访问周期的 1 个沿
        rd_check(ADDR_CTRL, 32'h3);
        rd_check(ADDR_INTR_STATE, 32'h0);
        // 停止时清零：变为 0 并保持
        wr(ADDR_CTRL, 32'h2);
        wr(ADDR_CTRL, 32'h6);
        idle(10);
        rd_check(ADDR_COUNT, 32'h0);
        rd_check(ADDR_CTRL, 32'h2);
        // 与到时同拍：计数归零，到时仍置位中断状态
        wr(ADDR_CMP, 32'd9);
        wr(ADDR_CTRL, 32'h3);
        wait_count(32'd8);
        wr(ADDR_CTRL, 32'h7);
        apb_read(ADDR_INTR_STATE, ctrl, 1'b0);
        if (ctrl !== 32'h1) fail("CLR vs expire: EXPIRED not set");
        rd_check(ADDR_COUNT, 32'd3);                // 写入沿归零，第二次读的访问周期在其后第 3 拍
        // 清零不清除已置位的中断状态
        wr(ADDR_CTRL, 32'h6);
        rd_check(ADDR_INTR_STATE, 32'h1);
    end
endtask

// TP-009 随机激励 + 参考模型
task automatic test_random(input integer seed);
    integer s, n, op, gap;
    reg [11:0] a;
    reg [31:0] d;
    begin
        s = seed;
        for (n = 0; n < 3000; n = n + 1) begin
            op = $unsigned($random(s)) % 100;
            case ($unsigned($random(s)) % 6)
                0       : a = ADDR_CTRL;
                1       : a = ADDR_CMP;
                2       : a = ADDR_COUNT;
                3       : a = ADDR_INTR_STATE;
                4       : a = ADDR_INTR_ENABLE;
                // 非法地址：越界地址，或合法寄存器偏移 + 1~3 的非对齐地址（ITR-003）
                default : a = ($unsigned($random(s)) % 2) ? 12'h014 + 4 * ($unsigned($random(s)) % 8)
                                                          : 4 * ($unsigned($random(s)) % 5) + 1 + $unsigned($random(s)) % 3;
            endcase
            d = $random(s);
            if (a == ADDR_CMP) d = d % 24;           // 小比较值以产生大量到时事件
            if (op < 50) apb_write(a, d, !addr_valid(a));
            else         apb_read(a, d, !addr_valid(a));
            gap = $unsigned($random(s)) % 4;
            if (gap) idle(gap);
        end
    end
endtask

//------------------------------------------------------------------------------
// 主流程
//------------------------------------------------------------------------------
initial begin : MAIN
    integer seed;
    if (!$value$plusargs("TEST=%s", test)) test = "test_reset";
    if (!$value$plusargs("SEED=%d", seed)) seed = 1;
    do_reset;
    if      (test == "test_reset")        test_reset;
    else if (test == "test_reg_rw")       test_reg_rw;
    else if (test == "test_apb_err")      test_apb_err;
    else if (test == "test_oneshot")      test_oneshot;
    else if (test == "test_irq")          test_irq;
    else if (test == "test_periodic")     test_periodic;
    else if (test == "test_cmp_boundary") test_cmp_boundary;
    else if (test == "test_priority")     test_priority;
    else if (test == "test_random")       test_random(seed);
    else if (test == "test_clr")          test_clr;
    else begin
        $sformat(tst_msg, "unknown test %0s", test);
        fail(tst_msg);
    end
    idle(5);
    report_cover;
    $display("TEST %0s SEED %0d %0s errors=%0d", test, seed, (errors != 0) ? "FAILED" : "PASSED", errors);
    $finish;
end

initial begin
    #5_000_000;  // 5 ms
    fail("timeout");
    $display("TEST %0s FAILED errors=%0d", test, errors);
    $finish;
end

endmodule
