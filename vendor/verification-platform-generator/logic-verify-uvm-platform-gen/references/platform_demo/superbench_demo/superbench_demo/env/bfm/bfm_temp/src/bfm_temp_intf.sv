/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _bfm_temp_INTF_CLASS_
`define _bfm_temp_INTF_CLASS_

interface bfm_temp_intf   #(// GAEA_PLATFORM::CLASSNAME
    int  DAT_WIDTH = 32                 // GAEA_PLATFORM::PARAMETER
    )(
    wire clk,                           // GAEA_PLATFORM::CLK
    wire rst_n                          // GAEA_PLATFORM::RST
    ); 

    // BEGIN: EDITABLE SECTION
    bfm_temp_driver_intf   #(.DAT_WIDTH(DAT_WIDTH)) drv_bus(clk,rst_n);
    bfm_temp_receiver_intf #(.DAT_WIDTH(DAT_WIDTH)) rcv_bus(clk,rst_n);
    bfm_temp_monitor_intf  #(.DAT_WIDTH(DAT_WIDTH)) mon_bus(clk,rst_n);
    // END: EDITABLE SECTION


endinterface

interface bfm_temp_driver_intf #(DAT_WIDTH = 32) (input bit clk, input bit rst_n);
    //logic                    fifo_val;
    //logic                    fifo_sop;
    //logic                    fifo_eop;
    //logic [MOD_WIDTH-1:0]    fifo_mod;
    //logic                    fifo_err;
    //logic [DAT_WIDTH-1:0]    fifo_dat;
    //logic [EX_DAT_WIDTH-1:0] fifo_ex_dat;
    //logic                    fifo_rdy;
endinterface

interface bfm_temp_receiver_intf #(DAT_WIDTH = 32) (input bit clk, input bit rst_n);
    //logic                    fifo_val;
    //logic                    fifo_sop;
    //logic                    fifo_eop;
    //logic [MOD_WIDTH-1:0]    fifo_mod;
    //logic                    fifo_err;
    //logic [DAT_WIDTH-1:0]    fifo_dat;
    //logic [EX_DAT_WIDTH-1:0] fifo_ex_dat;
    //logic                    fifo_rdy;
endinterface

interface bfm_temp_monitor_intf #(DAT_WIDTH = 32) (input bit clk, input bit rst_n);
    //logic                    fifo_val;
    //logic                    fifo_sop;
    //logic                    fifo_eop;
    //logic [MOD_WIDTH-1:0]    fifo_mod;
    //logic                    fifo_err;
    //logic [DAT_WIDTH-1:0]    fifo_dat;
    //logic [EX_DAT_WIDTH-1:0] fifo_ex_dat;
    //logic                    fifo_rdy;
endinterface

`endif
