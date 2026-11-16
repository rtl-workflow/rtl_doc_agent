//*****************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : harness.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : define top module for input interface unit test 
//
//*****************************************************************************
`ifndef HARNESS__SV
`define HARNESS__SV

module harness;

    logic                       clk;
    logic                       rst_n;

    test_interface                u_test_if(clk, rst_n);
    
    realtime clk_period = 100;
    `stb_clk_gen(clk, 0, clk_period, 0.5, 0.1, CLK_NOR, 0)    
    `stb_rst_n_gen(rst_n, 100, 100)

    initial begin
        uvm_config_db#(virtual test_interface)::set(null, "*test_if_agent*", "bus", u_test_if);
        run_test();
    end

endmodule

`endif
