//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_monitor_cfg.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0 
// ABSTRACT      : Configuration for test interface agent monitor 
//
//******************************************************************************

`ifndef TEST_MONITOR_CFG__SV
`define TEST_MONITOR_CFG__SV

/** \brief test_monitor_cfg
    Configuration for test interface agent monitor
*/
class test_monitor_cfg extends uvm_object;

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // rand int pkt_len;           ///< Define the packet length
    //-----------------------------Coding end---------------------------------//
    
    //------------------------------------------------------------------------//
    // Declare the constraints of variables                                   //
    // Constrain name tailer need add _cons                                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // constraint pkt_len_cons;    ///< Constrain the packet length
    //-----------------------------Coding end---------------------------------//

    `uvm_object_utils_begin(test_monitor_cfg)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//      
    `uvm_object_utils_end

    /** \brief new()
    Constructor
    */
    extern function new(string name = "test_monitor_cfg");

    /** \brief pre_randomize() 
    Handle random data information before randomize
    */
    extern function void pre_randomize();

    /** \brief post_randomize() 
    Handle random data information after randomize
    */
    extern function void post_randomize();

    //------------------------------------------------------------------------//
    // Define the function/task base on project requirement                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: test_monitor_cfg

//----------------------------------------------------------------------------//
// Define constraints of the variables base on project requirement.           //
// Constrain name tailer need add _cons                                       //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//
// constraint test_monitor_cfg::pkt_len_cons {
//     pkt_len >= test_dec::MIN_LENGTH;
//     pkt_len <= test_dec::MAX_LENGTH;
// }
//-----------------------------Coding end-------------------------------------//

function test_monitor_cfg::new(string name = "test_monitor_cfg");

    super.new(name);

    //------------------------------------------------------------------------//
    // Add the initial of variables base on project requirement               //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: new

function void test_monitor_cfg::pre_randomize();

    super.pre_randomize();

    //------------------------------------------------------------------------//
    // Extend pre_randomize() base on project requirement                     //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: pre_randomize

function void test_monitor_cfg::post_randomize();

    super.post_randomize();

    //------------------------------------------------------------------------//
    // Extend post_randomize() base on project requirement                    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: post_randomize

`endif

