//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : tc_sanity.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : tc_sanity for demo environment test
//
//******************************************************************************
`ifndef TC_SANITY__SV
`define TC_SANITY__SV
//----------------------------------------------------------------------------//
// Define tc_name base on project requirement                                 //
// The tc name must be file name without ext                                  //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//
`define tc_name tc_sanity
//-----------------------------Coding end-------------------------------------//

//----------------------------------------------------------------------------//
// Define the testcase class name base on project requirement                 //
//----------------------------------------------------------------------------//
//-----------------------------Coding begin-----------------------------------//

//-----------------------------Coding end-------------------------------------//
`define test_interface_agent_cfg0(tc) tc``_test_interface_agent_cfg0
`define test_interface_agent_cfg1(tc) tc``_test_interface_agent_cfg1

// Define the extension to add some expected constraint for this test scenario
class `test_interface_agent_cfg0(`tc_name) extends test_interface_agent_cfg;

    `uvm_object_utils(`test_interface_agent_cfg0(`tc_name))
    function new(string name = "name");
        super.new(name);
    endfunction

endclass: `test_interface_agent_cfg0(`tc_name)

class `test_interface_agent_cfg1(`tc_name) extends test_interface_agent_cfg;

    `uvm_object_utils(`test_interface_agent_cfg1(`tc_name))
    function new(string name = "name");
        super.new(name);
    endfunction

endclass: `test_interface_agent_cfg1(`tc_name)

class `tc_name extends tc_base;

    `uvm_component_utils(`tc_name)

    `test_interface_agent_cfg0(`tc_name)  test_if_agent_cfg0;
    `test_interface_agent_cfg1(`tc_name)  test_if_agent_cfg1;
  
    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);
    extern virtual task configure_phase(uvm_phase phase);
    extern task main_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);

endclass: `tc_name

function `tc_name::new(string name ,
                       uvm_component parent
                      );

    super.new(name,parent);

endfunction

function void `tc_name::build_phase(uvm_phase phase);

    super.build_phase(phase);

    this.test_if_agent_cfg0  = `test_interface_agent_cfg0(`tc_name)::type_id::create("test_if_agent_cfg0", this); 
    this.test_if_agent_cfg1  = `test_interface_agent_cfg1(`tc_name)::type_id::create("test_if_agent_cfg1", this); 
    this.env.test_if_agent_cfg[0] = this.test_if_agent_cfg0;
    this.env.test_if_agent_cfg[1] = this.test_if_agent_cfg1;

    uvm_config_db #(int)::set(null, "*test_default_sequence*", "seq_item_max_num", 10);
    uvm_config_db #(uvm_object_wrapper)::set(this, "*test_if_agent[0].test_sqr.main_phase", "default_sequence", test_default_sequence::type_id::get());

endfunction

function void `tc_name::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    `uvm_info(get_type_name(), $sformatf("end_of_elaboration_phase(): end_of_elaboration_phase() finished"), UVM_HIGH);

endfunction

task `tc_name::reset_phase(uvm_phase phase);

    super.reset_phase(phase);

    `uvm_info(get_type_name(), $sformatf("reset_phase(): reset_phase() finished"), UVM_HIGH);

endtask: reset_phase

task `tc_name::configure_phase(uvm_phase phase);

    super.configure_phase(phase);

    `uvm_info(get_type_name(), $sformatf("configure_phase(): configure_phase() finished"), UVM_HIGH);

endtask: configure_phase

task `tc_name::main_phase(uvm_phase phase);

endtask: main_phase

function void `tc_name::report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info(get_type_name(), $sformatf("report_phase(): report_phase() finished"), UVM_HIGH);

endfunction: report_phase

`undef test_interface_agent_cfg0
`undef test_interface_agent_cfg1
`undef tc_name

`endif
