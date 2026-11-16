// ---------------------------------------------------------------------
//                  Logic Verification Latest
//                  =================================
// File			    : public_define_func.sv
// Author		    : WangAoXiang w00574459
// Email            :   
// Created TIME		: Sept 25 2024
// VERSION          : 1.0
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef _PUBLIC_DEFINE_FUNC_
`define _PUBLIC_DEFINE_FUNC_

`ifndef CONNECT_MAX_LEN
    `define CONNECT_MAX_LEN 128
`endif

`define get_port_data(chn, data_in)\
begin\
    uvm_sequence_item data_ori;\
    chn.get(data_ori);\
    if(!$cast(data_in, data_ori))\
    begin\
        `uvm_fatal(get_type_name(), "cast type missmatch");\
    end\
end


`define peek_port_data(chn, data_in)\
begin\
    uvm_sequence_item data_ori;\
    chn.peek(data_ori);\
    if(!$cast(data_in, data_ori))\
    begin\
        `uvm_fatal(get_type_name(), "cast type missmatch");\
    end\
end


`define CONNECT_TEST(src_sig, des_sig, dly_time)                      \
begin\
    static logic [`CONNECT_MAX_LEN - 1 :0] test_data = $urandom_range(0,{`CONNECT_MAX_LEN{1'b1}});\
    force src_sig = test_data;\
    stb_realtime.delay(dly_time);\
    if(src_sig != des_sig) begin\
        `uvm_error("CONNECT_TEST",$sformatf("Error, src_sig(%b) != des_sig(%b)", src_sig, des_sig));\
    end\
    else begin\
        `uvm_info("CONNECT_TEST",$sformatf("PASSED, src_sig(%b) == des_sig(%b)", src_sig, des_sig),UVM_NONE);\
    end\
    release src_sig;\
end\


`define CONNECT_TEST_DLY(src_sig, des_sig,clk,dly_num)                      \
begin\
    static logic [`CONNECT_MAX_LEN - 1 :0] test_data = $urandom_range(0,{`CONNECT_MAX_LEN{1'b1}});\
    force src_sig = test_data;\
    repeat(dly_num) @(posedge clk);\
    if(src_sig != des_sig) begin\
        `uvm_error("CONNECT_TEST",$sformatf("Error, src_sig(%b) != des_sig(%b)", src_sig, des_sig));\
    end\
    else begin\
        `uvm_info("CONNECT_TEST",$sformatf("PASSED, src_sig(%b) == des_sig(%b)", src_sig, des_sig),UVM_NONE);\
    end\
    release src_sig;\
end\

`endif
