//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_interface.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Interface definition
//
//******************************************************************************
 
`ifndef TEST_INTERFACE__SV
`define TEST_INTERFACE__SV

/** \brief packet bus interface declaration
    This interface defines the signles of DUT interface
*/
interface test_interface(input bit clk, input rst_n);

    // Define the default setup & hold times
    parameter SETUP_TIME = 1ns;
    parameter HOLD_TIME  = 1ns;
    
    //------------------------------------------------------------------------//
    // Define signals base on project requirement                             //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // logic                                sop;
    // logic                                eop;
    // logic                                data_valid;
    // logic                                lbo;
    // logic [test_dec::PKT_DATA_WIDTH-1:0]   data;
    //-----------------------------Coding end---------------------------------//

    // Define one clocking block from master perspective
    clocking drv_cb @(posedge clk);
        default input #SETUP_TIME output #HOLD_TIME;

        //--------------------------------------------------------------------//
        // Define signals in drv_cb base on project requirement               //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // output                   sop;
        // output                   eop;
        // output                   data;
        // output                   data_valid;
        // output                   lbo;
        //---------------------------Coding end-------------------------------//

    endclocking: drv_cb
 
    // Define one clocking block from monitor perspective
    clocking mon_cb @(posedge clk);
        default input #SETUP_TIME output #HOLD_TIME;

        //--------------------------------------------------------------------//
        // Define signals in mon_cb base on project requirement               //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // input                    sop;
        // input                    eop;
        // input                    data;
        // input                    data_valid;
        // input                    lbo;
        //---------------------------Coding end-------------------------------//

    endclocking: mon_cb

    clocking slv_drv_cb @(posedge clk);                  // User can delete it when you don't need slave driver
        default input #SETUP_TIME output #HOLD_TIME;

        //--------------------------------------------------------------------//
        // Define signals in slv_drv_cb base on project requirement           //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        
        //---------------------------Coding end-------------------------------//
        
    endclocking: slv_drv_cb

    modport drv_mp (clocking drv_cb);          // Master modport for driver
    modport mon_mp (clocking mon_cb);          // Master modport for monitor
    modport slv_drv_mp (clocking slv_drv_cb);  // Slave modport for slave driver   

    `ifdef ASSERT_ON

        //--------------------------------------------------------------------//
        // Define assertion base on project requirement                       //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//

        //---------------------------Coding end-------------------------------//

    `endif // ASSERT_ON

endinterface: test_interface

`endif

