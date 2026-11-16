//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_monitor_cov.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Monitor coverage model 
//
//******************************************************************************

`ifndef TEST_MONITOR_COV__SV
`define TEST_MONITOR_COV__SV


/** \brief DUT monitor
    The DUT monitor extracts the transaction from the DUT interface
    and transfer it through the packet port 
*/
class test_monitor_cov extends uvm_subscriber #(uvm_sequence_item);

    test_xaction               mon_cov_tr;    ///< The sequence item from monitor

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//   

    `uvm_component_utils_begin(test_monitor_cov)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//        
    `uvm_component_utils_end

    //------------------------------------------------------------------------//
    // This below coverge group definiton is implemented as an example,       //
    // user can add coverge group base on project requirement                 //
    //------------------------------------------------------------------------//  
    //-----------------------------Coding begin-------------------------------//
    // covergroup in_pkt_cg;        
    //     option.per_instance = 1;
    //     pkt_len: coverpoint this.rm_tr2cov.pkt_len {
    //         bins short_boudary[] = {[1:4],[15:16]};       // Cover each boundary value
    //         bins short           = {[5:14]};              // Cover short packet range
    //         bins normal_boud[]   = {[17:19],[1516:1518]}; // Cover normal boundary
    //         bins normal[5]       = {[20:1515]};           // Cover five segment splitted from 20 to 1515
    //         bins long_boud[]     = {[1519:1520]};         // Cover long boundary
    //         bins long            = {[1521:$]};            // Cover any value greater than 1521        
    //     }
    // endgroup: in_pkt_cg
    //-----------------------------Coding end---------------------------------//

    /** \brief new() 
     Constructor
    */  
    extern function new(string            name,
                        uvm_component     parent
                       );

    extern virtual function void write(uvm_sequence_item t);

    //------------------------------------------------------------------------//
    // Define the member task/function base on project requirement            //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: test_monitor_cov

function test_monitor_cov::new(string        name,
                              uvm_component  parent
                              );

    super.new(name, parent);

    //------------------------------------------------------------------------//
    // Add coverage group object base on project requirement                  //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // in_pkt_cg = new();       // Create the coverage object
    // in_pkt_cg.set_inst_name("in_pkt_cg");
    //-----------------------------Coding end---------------------------------//

endfunction: new

function void test_monitor_cov::write(uvm_sequence_item t);

    if(!$cast(this.mon_cov_tr, t.clone())) begin
        `uvm_fatal(get_type_name(), "write(): item is not a test_xactions type or its extension");
    end

    //------------------------------------------------------------------------//
    // Add coverage group sample base on project requirement                  //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // in_pkt_cg.sample();      // Sample coverage group
    //-----------------------------Coding end---------------------------------//

endfunction: write

`endif

