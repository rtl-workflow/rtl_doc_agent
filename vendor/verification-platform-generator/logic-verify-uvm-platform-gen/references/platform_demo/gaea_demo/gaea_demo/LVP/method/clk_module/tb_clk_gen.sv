/**********************************************************************************\
    Copyright(c) 2009, Huawei Technologies Co., Ltd, All right reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   tb_clk_gen.sv
    Author       :   shenyue/00159590
    ===============================================================================
    Description  :   generate clock for testbench
    ===============================================================================
    Modification History:
    Date        By        Rev.  Prj.    Change Description
    -------------------------------------------------------------------------------
    2011-04-03  shenyue   1.0   PL349   Create
    2012-07-01  shenyue   1.1   PL371   Use a function to calc the period time in module tb_clk_gen, so the period can be changed in running by calling this function.
    2014-06-24  xuhui     1.2   PL385   Optimize the period algorithm of tb_clk_gen to improve the precision of output clock.
    2014-06-24  shenyue   1.3   TD280   Add dynamic sampling of ref clk period in tb_clk_pll to work under the condition the period of ref clk varying.

\**********************************************************************************/

// The timescale MUST NOT be changed or the period of output clock will be wriong.
`timescale 1ns/1ps

module tb_rst_gen #(
    real INI_TIME = 10,   // initial time, unit: ns
    real RST_TIME = 100   // reset time, unit: ns
) (
    output reg rst_n);

    initial
    begin
        rst_n = 1'b1;
        # INI_TIME ;
        rst(RST_TIME);
    end

    task rst (input real rst_time = RST_TIME);
        rst_n = 1'b0;
        #rst_time ;
        rst_n = 1'b1;
    endtask
endmodule

// NAME : tb_clk_gen
// BRIEF: gennerate clk for testbench
module tb_clk_gen #(
    real     FREQUENCY   = 0       , // clock frequency, unit: Mhz
    real     PERIOD      = 0       , // half clock period, unit: ns
    int      SEED        = 1       , //
    string   NAME        = "tb_clk_gen"
) (
    output reg clk
);

    real      half_period_cnt   ;
    real      ini_delay         ;
    real      period            ;
    real      period_rsv        ;
    real      period_total      ;
    real      half_period_cnt_h ;
    real      half_period_cnt_l ;
    int       ini_delay_256     ;
    int       half_period_int   ;

    reg       start  ;

    initial begin
        clk = 0;
        start = 0 ;
        period_rsv = 0;
        set_freq(FREQUENCY, PERIOD);

        if (SEED <= 0) begin
            $display( "FATAL |%m | %s parameter set error, SEED should > 0", NAME);
            $stop();
        end

        // Set random seed, so the phase of output clock in different instances with same freq or period parameter woule be different
        void'($urandom(SEED));
        ini_delay_256    = $urandom & 32'hff;
        half_period_int  = int'(period / 2.0 * 1000) / 1000.0;
        ini_delay        = half_period_int / 256.0 * ini_delay_256;
        //$display("NOTE |%m |%s SEED = %0d, ini_delay_256 = %0d, ini_delay = %0f", NAME, SEED, ini_delay_256, ini_delay);
        #ini_delay;

        // start generate output clock
        clk = 0;
        start = 1;
        forever begin
            //If period was an odd number, the high and low time was different in one period, half_period_cnt_h = half_period_cnt_l + 1ps
            period_total = period + period_rsv;
            //$display("%m period_total %f ", period_total);
            half_period_cnt_h = int'(period_total / 2.0 * 1000) / 1000.0 ;
            half_period_cnt_l = int'((period_total - half_period_cnt_h) * 1000)/1000.0 ;
            period_rsv = period_total - half_period_cnt_h - half_period_cnt_l;

            //$display("%m period_rsv %f ", period_rsv);
            //$display("%m half_period_cnt_h %f ", half_period_cnt_h);
            //$display("%m half_period_cnt_l %f ", half_period_cnt_l);
            #half_period_cnt_h clk = ~clk;
            #half_period_cnt_l clk = ~clk;
        end
    end

    // calculate period by the input parameters
    task set_freq(input real freq_in = FREQUENCY, input real period_in = PERIOD);
        period_rsv = 0;
        //$display("%m freq_in = %f, period_in = %f", freq_in, period_in);
        if (FREQUENCY == 0) begin
            if (PERIOD > 0) begin
                period = period_in ;
            end
            else begin
                $display("FATAL |%m | %s parameter set error, FREQUENCY = %t, PERIOD = %t", NAME, FREQUENCY, PERIOD);
                $stop();
            end
        end
        else begin
            period = 1000.0/freq_in ;
        end
    endtask

endmodule: tb_clk_gen

// NAME : tb_pll
// BRIEF: pll for testbench
module tb_pll #(
    int    MUL_PARA = 11       ,
    int    DIV_PARA = 13       ,
    int    PHASE    = -1       ,
    string NAME     = "tb_pll"
)(
    input  wire clk_in      ,
    output reg  clk_out
    //output reg  locked
);

    real       start_time       ;
    real       end_time         ;
    real       in_period_time   ;
    real       out_period_time  ;
    real       cur_out_period   ;
    real       high_out_period  ;
    real       low_out_period   ;
    int        temp_int         ;
    real       time_queue [$];

    real       phase_time       ;

    int        lock_cnt         ;
    int        phase            ;
    logic      clk_mul          ;
    logic      clk_out_phase_0  ;
    int        diff_int;
    int        dif_cnt;

    real       pre_in_period = 0;
    bit        unlock = 1;

    bit        dynamic_sample_en = 1 ; // set 1 to enable dyname sample the period of input reference clock.

    // sample the ref clock to calc the period of ref clock and output clock
    task resample;
        //$timeformat(-9, 0, "ns" );
        @(posedge clk_in) start_time = $realtime;
        repeat(DIV_PARA) @(posedge clk_in);
        end_time   = $realtime;
        in_period_time = end_time - start_time ;
        out_period_time = in_period_time / MUL_PARA ;

        if (pre_in_period == in_period_time)
        begin
            unlock = 0;
            return;
        end

        unlock = 1;
        pre_in_period = in_period_time ;
        // convert the output period time to 1ns
        temp_int = out_period_time * 1000 ;
        out_period_time = temp_int * 1.0 / 1000;
        if (out_period_time * MUL_PARA > in_period_time ) begin
            out_period_time = out_period_time - 0.001 ;
        end
        diff_int = (in_period_time - out_period_time *MUL_PARA) * 1000 ;

        // conver the phase(unit:degree) to time(unit:ns)
        if (PHASE == -1) begin
            phase = $urandom_range(0, 359);
        end
        else begin
            phase = PHASE ;
        end
        if (phase >= 0 && phase < 360) begin
            phase_time = out_period_time * phase / 360.0 ;
        end
        else begin
            $display("FATAL |%m |%0t | PHASE set error, should be inside [-1, 359], but got %0d", $realtime, phase);
            $stop;
        end

        //$display("start_time       = %0f", start_time);
        //$display("end_time         = %0f", end_time);
        //$display("in_period_time   = %0f", in_period_time);
        //$display("out_period_time  = %0f", out_period_time);
        //$display("diff_int         = %0d", diff_int);
        //$display("%m PHASE = %0d, phase_time = %f", PHASE, phase_time);

        // calc the output clock period time of every period using sigma-delta
        for (int i = 0; i < MUL_PARA; i ++)begin
            dif_cnt = dif_cnt + diff_int ;
            cur_out_period = out_period_time ;
            if (dif_cnt / MUL_PARA >= 1) begin
                cur_out_period += 0.001;
            end
            dif_cnt = dif_cnt % MUL_PARA ;

            // calc the high and low time in one period
            temp_int = cur_out_period * 1000 / 2;
            high_out_period = temp_int *1.0 / 1000;
            low_out_period  = cur_out_period - high_out_period ;
            time_queue[i*2] = high_out_period;
            time_queue[i*2 + 1] = low_out_period;
        end
    endtask

    // LOCK MUL_CLK TO CLK_IN
    initial begin
        clk_out_phase_0 = 0;
        clk_out         = 0;
        // first sampling
        resample;

        // keep sampling if dynamic_sample_en enabled
        if (dynamic_sample_en == 1)
        begin
            fork
            begin
                forever resample();
            end
            join_none
        end

        // generate the output clock, the clk_out_phase_0 was 0 phase delay, clk_out was PHASE delay.
        forever begin
            for(int i = 0; i < MUL_PARA; i ++) begin
                # (time_queue[i*2 + 0]) clk_out_phase_0 = 0;
                fork
                begin
                    #phase_time ;
                    clk_out = 0;
                end
                join_none
                # (time_queue[i*2 + 1]) clk_out_phase_0 = 1;
                fork
                begin
                    #phase_time ;
                    clk_out = 1;
                end
                join_none
            end
        end
    end
endmodule: tb_pll

module cp_clk_gen #(
    longint     CLK_C       = 1       , // clock frequency, unit: Mhz use C/P
    longint     CLK_P       = 1       , // eg: 311.04Mhz => clk_c = 31104,clk_p = 100
    //int         SEED        = 1       , //
    string      NAME        = "cp_clk_gen"
) (
    output reg clk
);
    real        r_time_ns;
    real        half_period_ns_que[$];
    longint     half_period_c_ns;
    longint     half_period_p_ns;
    longint     time_ps;
    longint     sum_ps;
    int         ini_delay_ps;
    int         half_cycle_num;
    int         cnt;

    initial begin
        half_period_c_ns = 500*CLK_P; 
        half_period_p_ns = CLK_C; 
        half_cycle_num = 1;
        sum_ps = 0;
        while(1) begin
            time_ps = 1000*half_cycle_num*half_period_c_ns/half_period_p_ns - sum_ps;
            sum_ps = sum_ps + time_ps;
            r_time_ns = time_ps/1000.000;
            half_period_ns_que.push_back(r_time_ns);
            if(sum_ps*half_period_p_ns == 1000*half_cycle_num*half_period_c_ns) break;
            half_cycle_num++;
        end
        //init
        ini_delay_ps = $urandom_range(1,1000*half_period_c_ns/half_period_p_ns);
        r_time_ns = ini_delay_ps/1000.000;
        clk = 1'b0;
        #r_time_ns;
        clk = 1'b1;

        cnt = 0;
        forever begin
            r_time_ns = half_period_ns_que[cnt];
            #r_time_ns;
            clk = ~clk;
            cnt++;
            if(cnt == half_cycle_num) cnt = 0;
        end
    end
endmodule: cp_clk_gen


//-------------------------------------------------------------
// SHORTHARD MACRO DEFINITION
//-------------------------------------------------------------
`define GEN_CLK_BY_FREQ(clk_name, clk_freq, seed) \
`gen_clk_by_freq(clk_name, clk_freq, seed)

`define GEN_CLK_BY_INT_CP(clk_name, clk_c, clk_p) \
`gen_clk_by_cp(clk_name, clk_c, clk_p)

`define GEN_CLK_BY_PLL(clk_ref, clk_name, mul_para, div_para, phase) \
`gen_clk_by_pll(clk_ref, clk_name, mul_para, div_para, phase)

`define GEN_RST(rst_n, ini_time, rst_time) \
`gen_rst (rst_n, ini_time, rst_time)

`define gen_clk_by_freq(clk_name, clk_freq, seed) \
wire clk_name ; \
tb_clk_gen #(.FREQUENCY(clk_freq), .SEED(seed), .NAME(`"clk_name`")) clk_name``_gen (clk_name)

`define gen_clk_by_period(clk_name, clk_period, seed) \
wire clk_name ; \
tb_clk_gen #(.PERIOD(clk_period), .SEED(seed), .NAME(`"clk_name`")) clk_name``_gen (clk_name)

`define gen_clk_by_pll(clk_ref, clk_name, mul_para, div_para, phase) \
wire clk_name; \
tb_pll #( .MUL_PARA(mul_para), .DIV_PARA(div_para), .PHASE(phase), .NAME(`"clk_name`")) clk_name``_gen (clk_ref, clk_name)

`define gen_rst(rst_n, ini_time, rst_time) \
wire rst_n; \
tb_rst_gen #(.INI_TIME(ini_time), .RST_TIME(rst_time)) rst_n``_gen(rst_n)

`define gen_clk_by_int_cp(clk_name, clk_c, clk_p) \
wire clk_name ; \
cp_clk_gen #(.CLK_C(clk_c), .CLK_P(clk_p), .NAME(`"clk_name`")) clk_name``_gen (clk_name)
