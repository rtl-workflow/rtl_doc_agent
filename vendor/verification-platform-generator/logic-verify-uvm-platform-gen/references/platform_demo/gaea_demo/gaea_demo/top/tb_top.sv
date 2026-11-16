//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:27
//Abstract        : top
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-03 22:26:57 , by c00800326);
//Revision 1.1  ( 2025-11-03 22:27:28 , by c00800326);
//Revision 1.2  ( 2025-11-04 11:41:27 , by c00800326);

//##################################################################
//    Index of content;
//      I.   Clock generating;
//      II.  Reset at Power on;
//      III. Wave dumpping;
//      IV.  Block instantiation;
//        a. interface
//        b. program(testcase)
//        c. duv/dut
//###################################################################

`ifndef _TB_TOP__SV
`define _TB_TOP__SV

module tb_top();

    // -----------------------------------------------------
    // I   Clock generating;
    // -----------------------------------------------------
    //               clk_name, frequency, rand seed
    //!GAEA_BLOCK_BEGIN_CLK_INSTANTIATION
    `gen_clk_by_freq(clk,    100,    100);
    //!GAEA_BLOCK_END_CLK_INSTANTIATION
    // -----------------------------------------------------
    // II  Reset at Power on;
    // -----------------------------------------------------
    //!GAEA_BLOCK_BEGIN_RST_INSTANTIATION
    `gen_rst(rst_n,    100,    100);
    //!GAEA_BLOCK_END_RST_INSTANTIATION
    // -----------------------------------------------------
    // III Wave dumpping;
    // -----------------------------------------------------

    // -----------------------------------------------------
    // IV  Block instantiation;
    // -----------------------------------------------------
    // a. interface
    // -----------------------------------------------------
    // Manual editing:
    //     You may need to change the clock connected to the bfm interaces.
    // -----------------------------------------------------
    //!GAEA_BLOCK_BEGIN_INTERFACE_INSTANTIATION
        bfm_temp_intf #(.DAT_WIDTH(32)) u_bfm_temp_intf(clk, rst_n);
        bfm_cbus_intf #(.AWIDTH(22), .DWIDTH(32)) u_bfm_cbus_intf(clk);
    //!GAEA_BLOCK_END_INTERFACE_INSTANTIATION
    // -----------------------------------------------------
    // b. testcase
    // -----------------------------------------------------
    initial begin
    	//!GAEA_BLOCK_BEGIN_SET_INTERFACE_INSTANTIATION
          uvm_config_db#(virtual bfm_temp_intf#(.DAT_WIDTH(32)))::set(null, "*.u_env.u_bfm_temp", "bus", u_bfm_temp_intf);
          uvm_config_db#(virtual bfm_cbus_intf#(.AWIDTH(22), .DWIDTH(32)))::set(null, "*.u_env.u_bfm_cbus", "bus", u_bfm_cbus_intf);
	    //!GAEA_BLOCK_END_SET_INTERFACE_INSTANTIATION
        run_test();
    end

    // -----------------------------------------------------
    // c. dut
    // -----------------------------------------------------
    //Manual editing:
    //    Instantiate your dut top below and connect it properly.
    // -----------------------------------------------------
    `ifdef ASSERT_ON
    `endif
    `ifdef ENV_DEBUG
        //!GAEA_BLOCK_BEGIN_SELF_TEST_INTERFACE
       //!GAEA_BLOCK_END_SELF_TEST_INTERFACE
    `else
        //!GAEA_BLOCK_BEGIN_DUT_TOP_INSTANTIATION
        `include "../../top/dut_top_para.sv"
        `include "../../top/dut_top_inst.sv"
        `include "../../top/simmodel_top_inst.sv"
        //!GAEA_BLOCK_END_DUT_TOP_INSTANTIATION
    `endif

endmodule

`endif
