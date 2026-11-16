//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_interface.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : CPU bus interface definition 
//
//******************************************************************************
 
`ifndef MPI_INTERFACE__SV
`define MPI_INTERFACE__SV

/** \brief CPU Bus Interface definition
    This interface declares the signals of cpu interface
*/
interface mpi_interface(input bit clk, input rst_n);

    // Define the default setup and hold time
    parameter SETUP_TIME       = 1ns;
    parameter HOLD_TIME        = 1ns;

    //------------------------------------------------------------------------//
    // Define signals base on project requirement                             //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // logic [`VMM_RAL_ADDR_WIDTH -1:0] i_addr;
    // logic [`VMM_RAL_DATA_WIDTH -1:0] i_wdata;
    // logic [`VMM_RAL_DATA_WIDTH -1:0] o_rdata;
    //-----------------------------Coding end---------------------------------//

    // Define one clocking block from master perspective
    clocking drv_cb @(posedge clk);

        default input #SETUP_TIME output #HOLD_TIME;

        //--------------------------------------------------------------------//
        // Define signals in drv_cb base on project requirement               //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // output                     i_wdata;
        // output                     i_addr;
        // input                      o_rdata;
        //---------------------------Coding end-------------------------------//

    endclocking: drv_cb

    clocking mon_cb @(posedge clk);

        default input #SETUP_TIME output #HOLD_TIME;
        //--------------------------------------------------------------------//
        // Define signals in mon_cb base on project requirement               //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // input                      i_wdata;
        // input                      i_addr;
        // input                      o_rdata;
        //---------------------------Coding end-------------------------------//

    endclocking: mon_cb

    clocking slv_drv_cb @(posedge clk);
        default input #SETUP_TIME output #HOLD_TIME;

        //--------------------------------------------------------------------//
        // Define signals in slv_drv_cb base on project requirement           //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // input                      i_wdata;
        // input                      i_addr;
        // output                     o_rdata;
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

endinterface: mpi_interface

`endif

