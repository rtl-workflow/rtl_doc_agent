//**********************************************
//
//Copyright(c) 2013, Huawei Technologies Co.,Ltd.
//All rights reserved
//
//Project name    :  JFSK QCC 
//
//File name       :  crg_checker_macro.sv
//
//Created_date    :  Thu Apr 21 18:45:48 CST 2013
//
//Author          :  Mao Zheming / 168753
//                   que Min     / 190342
//
//Email           :  maozheming@huawei.com
//     
//Module_name     :  CRG_CHECKER_MACRO

// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef CRG_CHECKER_MACRO__SV
`define CRG_CHECKER_MACRO__SV


//---------------------------------CLK_CHECK--------------------------------------------- //

// ---------------------------------------------------------------------
// Checker Name: CLK_CHECK
// Desc: check the attributes of clock
//       1)clock frequency
//       2)"X/Z" state
//       3)clock glitch 
//       4)clock duty
// ---------------------------------------------------------------------
    
    `define V_CLK_CHECK_DEFINE_SW(__clk_name, __pos_half_cycle, __neg_half_cycle)   \
    realtime  __clk_name``_timeout = 1000;  \
    realtime  __clk_name``_stime;  \
    realtime  __clk_name``_etime;  \
    realtime  __clk_name``_time[$];  \
    bit __clk_name``_en = 1'b0;  \
    bit __clk_name``_is_first_time = 1'b1; \
    real __clk_name``_hcycle1;  \
    real __clk_name``_hcycle2 = __pos_half_cycle;  \
    real __clk_name``_hcycle3 = __neg_half_cycle;  \
    real __clk_name``_err;  \
    string __clk_name``_name = "__clk_name";  \
    int    __clk_name``_edge_cnt = 0; 


    `define V_CLK_CHECK_DEFINE(__clk_name)   \
       realtime  __clk_name``_timeout = 1000;  \
       realtime  __clk_name``_stime;  \
       realtime  __clk_name``_etime;  \
       realtime  __clk_name``_time[$];  \
       bit       __clk_name``_en = 1'b0;  \
       bit       __clk_name``_is_first_time = 1'b1; \
       real      __clk_name``_err;  \
       string    __clk_name``_name = "__clk_name";  \
       int       __clk_name``_edge_cnt = 0; 


    `define V_CLK_CHECK(__clk_name, __clk_signal, __clk_jitter,__pos_half_cycle, __neg_half_cycle, __uvm_info)   \
    begin  \
        real __clk_name``_hcycle1;  \
        real __clk_name``_hcycle2 = __pos_half_cycle;  \
        real __clk_name``_hcycle3 = __neg_half_cycle;  \
        wait (__clk_name``_en == 1'b1); \
        `uvm_info(__uvm_info, $psprintf("CLK_CHECK : start to check %s, pos_half_cycle=%0g,neg_half_cycle=%0g", __clk_name``_name,__pos_half_cycle, __neg_half_cycle,),UVM_NONE); \
        while (1) begin  \
            if (__clk_signal === 1'bx || __clk_signal === 1'bz) begin \
                `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s is x or z", __clk_name``_name));   \
            end \
            @(posedge __clk_signal);  \
            if (__clk_name``_en == 1'b1) begin  \
                __clk_name``_etime = $realtime;          \
                __clk_name``_hcycle1 = __clk_name``_etime - __clk_name``_stime;  \
                __clk_name``_err = $abs(__clk_name``_hcycle1 - __clk_name``_hcycle2) ;\
                if (__clk_name``_err > __clk_jitter && __clk_name``_is_first_time != 1'b1) begin  \
                    `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s posedge_half_cycle error(err:%f), actual:%f ns expect:%f ns", __clk_name``_name, __clk_name``_err, __clk_name``_hcycle1, __clk_name``_hcycle2));   \
                end  \
                __clk_name``_stime = $realtime;          \
                __clk_name``_is_first_time = 1'b0; \
            end \
            else begin  \
                __clk_name``_err = 0;  \
                __clk_name``_stime = 0; \
                __clk_name``_etime = 0;  \
                __clk_name``_is_first_time = 1'b1; \
            end   \
            if (__clk_signal === 1'bx || __clk_signal === 1'bz) begin \
                `uvm_error(__uvm_info, $psprintf("CLK_CHECK@%0t : %s is x or z", $realtime, __clk_name``_name));   \
            end \
            @(negedge __clk_signal);  \
            if (__clk_name``_en == 1'b1) begin  \
                __clk_name``_etime = $realtime;          \
                __clk_name``_hcycle1 = __clk_name``_etime - __clk_name``_stime;  \
                __clk_name``_err = $abs(__clk_name``_hcycle1 - __clk_name``_hcycle3) ;\
                if (__clk_name``_err > __clk_jitter && __clk_name``_is_first_time != 1'b1) begin  \
                    `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s negedge_half_cycle error(err:%f), actual:%f ns expect:%f ns", __clk_name``_name, __clk_name``_err, __clk_name``_hcycle1, __clk_name``_hcycle3));   \
                end  \
                __clk_name``_stime = $realtime;          \
                __clk_name``_is_first_time = 1'b0; \
            end \
            else begin  \
                __clk_name``_err = 0;  \
                __clk_name``_stime = 0; \
                __clk_name``_etime = 0;  \
                __clk_name``_is_first_time = 1'b1; \
            end   \
        end \
    end


    `define V_CLK_CHECK_SW(__clk_name, __clk_signal, __clk_jitter,__uvm_info)   \
    begin  \
        wait (__clk_name``_en == 1'b1); \
        `uvm_info(__uvm_info, $psprintf("CLK_CHECK_SW : start to check %s, pos_half_cycle=%0g,neg_half_cycle=%0g", __clk_name``_name,__clk_name``_hcycle2, __clk_name``_hcycle3),UVM_NONE); \
        while (1) begin  \
            if (__clk_signal === 1'bx || __clk_signal === 1'bz) begin \
                `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s is x or z", __clk_name``_name));   \
            end \
            @(posedge __clk_signal);  \
            if (__clk_name``_en == 1'b1) begin  \
                __clk_name``_etime = $realtime;          \
                __clk_name``_hcycle1 = __clk_name``_etime - __clk_name``_stime;  \
                __clk_name``_err = $abs(__clk_name``_hcycle1 - __clk_name``_hcycle2) ;\
                if (__clk_name``_err > __clk_jitter && __clk_name``_is_first_time != 1'b1) begin  \
                    `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s posedge_half_cycle error(err:%f), actual:%f ns expect:%f ns", __clk_name``_name, __clk_name``_err, __clk_name``_hcycle1, __clk_name``_hcycle2));   \
                end  \
                __clk_name``_stime = $realtime;          \
                __clk_name``_is_first_time = 1'b0; \
            end \
            else begin  \
                __clk_name``_err = 0;  \
                __clk_name``_stime = 0; \
                __clk_name``_etime = 0;  \
                __clk_name``_is_first_time = 1'b1; \
            end   \
            if (__clk_signal === 1'bx || __clk_signal === 1'bz) begin \
                `uvm_error(__uvm_info, $psprintf("CLK_CHECK@%0t : %s is x or z", $realtime, __clk_name``_name));   \
            end \
            @(negedge __clk_signal);  \
            if (__clk_name``_en == 1'b1) begin  \
                __clk_name``_etime = $realtime;          \
                __clk_name``_hcycle1 = __clk_name``_etime - __clk_name``_stime;  \
                __clk_name``_err = $abs(__clk_name``_hcycle1 - __clk_name``_hcycle3) ;\
                if (__clk_name``_err > __clk_jitter && __clk_name``_is_first_time != 1'b1) begin  \
                    `uvm_error(__uvm_info, $psprintf("CLK_CHECK : %s negedge_half_cycle error(err:%f), actual:%f ns expect:%f ns", __clk_name``_name, __clk_name``_err, __clk_name``_hcycle1, __clk_name``_hcycle3));   \
                end  \
                __clk_name``_stime = $realtime;          \
                __clk_name``_is_first_time = 1'b0; \
            end \
            else begin  \
                __clk_name``_err = 0;  \
                __clk_name``_stime = 0; \
                __clk_name``_etime = 0;  \
                __clk_name``_is_first_time = 1'b1; \
            end   \
        end \
    end

    `define V_CLK_GATE_CHECK(__clk_name, __clk_signal, __clk_test_period, __uvm_info)   \
    begin  \
        wait (__clk_name``_en == 1'b1); \
        `uvm_info(__uvm_info, $psprintf("CLK_GATE_CHECK : start to check %s gate function", __clk_name``_name),UVM_NONE); \
        __clk_name``_edge_cnt = 0;  \
        fork   \
           begin  \
              ovpm#()::ovp_delay_ns(__clk_test_period); \
           end  \
           begin  \
              while (1) begin  \
                @(posedge __clk_signal);  \
                __clk_name``_edge_cnt ++;  \
              end  \
           end  \
        join_any  \
        if (__clk_name``_edge_cnt != 0) begin  \
            `uvm_error(__uvm_info, $psprintf("CLK_GATE_CHECK : %s not gating! total %0d clock rising edge in %0d ns", __clk_name``_name, __clk_name``_edge_cnt,__clk_test_period));   \
        end   \
        else begin \
            `uvm_info(__uvm_info, $psprintf("OK! CLK_GATE_CHECK : %s is gating!", __clk_name``_name),UVM_NONE);   \
        end   \
    end
    
    `define V_CLK_NORM_CHECK(__clk_name, __clk_signal, __clk_test_period, __uvm_info)   \
    begin  \
        wait (__clk_name``_en == 1'b1); \
        `uvm_info(__uvm_info, $psprintf("CLK_NORM_CHECK : start to check %s normal runing", __clk_name``_name),UVM_NONE); \
        __clk_name``_edge_cnt = 0;  \
        fork   \
           begin  \
              ovpm#()::ovp_delay_ns(__clk_test_period); \
           end  \
           begin  \
              while (1) begin  \
                @(posedge __clk_signal);  \
                __clk_name``_edge_cnt ++;  \
              end  \
           end  \
        join_any  \
        if (__clk_name``_edge_cnt == 0) begin  \
            `uvm_error(__uvm_info, $psprintf("CLK_NORM_CHECK : %s not runing! total %0d clock rising edge in %0d ns", __clk_name``_name, __clk_name``_edge_cnt,__clk_test_period));   \
        end   \
        else begin \
            `uvm_info(__uvm_info, $psprintf("OK! CLK_NORM_CHECK : %s is always runing!", __clk_name``_name),UVM_NONE);   \
        end   \
    end


// ---------------------------------------------------------------------
// Checker Name: CLK_PHASE
// Desc: check the phase between two clocks
// ---------------------------------------------------------------------
    `define V_CLK_PHASE_CHECK(__clk_1_name, __clk_1_signal, __clk_2_name, __clk_2_signal, __gap, __jitter, __uvm_info) \
    begin \
        int i; \
        bit flag; \
        bit is_first = 1'b1; \
        wait (__clk_1_name``_en == 1'b1 && __clk_2_name``_en == 1'b1); \
        `uvm_info(__uvm_info, $psprintf("CLK_PHASE : start to check phase %s & %s",  __clk_1_name``_name, __clk_2_name``_name),UVM_NONE); \
        while (1) begin \
            fork \
                begin \
                    flag = 1; \
                    @ (posedge __clk_1_signal); \
                    __clk_1_name``_time.push_back($realtime); \
                    flag = 0; \
                end \
                begin \
                    while (flag) begin \
                    @ (posedge __clk_2_signal); \
                    __clk_2_name``_time.push_back($realtime); \
                    end \
                end \
            join \
            if (__clk_1_name``_en == 1'b1 && __clk_2_name``_en == 1'b1) begin  \
                if ( is_first != 1) begin \
                    for (i=0; i<__clk_2_name``_time.size; i++) begin \
                        if ( ((__gap - __jitter) <= $abs(__clk_1_name``_time[0] - __clk_2_name``_time[i])) && \
                             ((__gap + __jitter) >= $abs(__clk_1_name``_time[0] - __clk_2_name``_time[i])) ) begin \
                            break; \
                        end \
                        //$display("__clk_1_time[0]   = %0g",__clk_1_name``_time[0]); \
                        //$display("__clk_2_time[%0d] = %0g",i,__clk_2_name``_time[i]); \
                        //$display("__gap - __jitter  = %0g",__gap - __jitter);  \
                        //$display("__gap + __jitter  = %0g",__gap + __jitter); \
                    end \
                    if (i == __clk_2_name``_time.size) begin \
                        `uvm_error(__uvm_info, $psprintf("CLK_PHASE : %0s & %0s phase error", __clk_1_name``_name, __clk_2_name``_name)); \
                    end \
                end \
                is_first = 1'b0; \
            end \
            else begin \
                is_first = 1'b1; \
            end \
            __clk_1_name``_time = {}; \
            __clk_2_name``_time = {}; \
        end \
    end 


`endif

//--------------------------------------------
// Modification History
// $Log: crg_checker_macro.sv,v $
//
//**********************************************


