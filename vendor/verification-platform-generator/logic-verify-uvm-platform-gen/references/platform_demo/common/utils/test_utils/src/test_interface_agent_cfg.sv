//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_interface_agent_cfg.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0 
// ABSTRACT      : The configuration for the test interface agent 
//
//******************************************************************************

`ifndef TEST_INTERFACE_AGENT_CFG__SV
`define TEST_INTERFACE_AGENT_CFG__SV

/** \brief test interface agent driver configuration
    This class contains the configuration for the test interface agent, to manager conponents configure
*/
class test_interface_agent_cfg extends uvm_object;

    rand test_driver_cfg                test_drv_cfg;                 ///< The test_if_agent driver configure
    rand test_monitor_cfg               test_mon_cfg;                 ///< The test_if_agent monitor configure

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    
    //-----------------------------Coding end---------------------------------//
    
    //------------------------------------------------------------------------//
    // Declare the constraints of variables                                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

    `uvm_object_utils_begin(test_interface_agent_cfg)
        `uvm_field_object(test_drv_cfg, UVM_ALL_ON)
        `uvm_field_object(test_mon_cfg, UVM_ALL_ON)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//      
    `uvm_object_utils_end

    /** \brief new()
    Constructor
    */
    extern function new(string name = "test_interface_agent_cfg");

    /** \brief pre_randomize() 
    Handle random data information before randomize
    */
    extern function void   pre_randomize();

    /** \brief post_randomize() 
    Handle random data information after randomize
    */
    extern function void   post_randomize();

    //------------------------------------------------------------------------//
    // Define the function/task base on project requirement                   //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: test_interface_agent_cfg


//----------------------------------------------------------------------------//
// Define constraints of the variables base on project requirement            //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//

//-----------------------------Coding end-------------------------------------//

function test_interface_agent_cfg::new(string name = "test_interface_agent_cfg");

    super.new(name);
    this.test_drv_cfg = test_driver_cfg::type_id::create("test_drv_cfg");
    this.test_mon_cfg = test_monitor_cfg::type_id::create("test_mon_cfg");

    //------------------------------------------------------------------------//
    // Add the initial of variables base on project requirement               //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: new

function void test_interface_agent_cfg::pre_randomize();

    super.pre_randomize();

    //------------------------------------------------------------------------//
    // Extend pre_randomize() base on project requirement                     //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: pre_randomize

function void test_interface_agent_cfg::post_randomize();

    super.post_randomize();
    
    //------------------------------------------------------------------------//
    // Extend post_randomize() base on project requirement                    //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endfunction: post_randomize

`endif

