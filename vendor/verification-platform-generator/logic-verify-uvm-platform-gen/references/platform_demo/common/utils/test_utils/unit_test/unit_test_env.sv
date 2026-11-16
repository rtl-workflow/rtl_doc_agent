//*****************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : unit_test_env.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : utils verification environment
//
//*****************************************************************************

`ifndef UNIT_TEST_ENV__SV
`define UNIT_TEST_ENV__SV

/** \brief utils verification environment
    This unit_test_env extension implements the test utils verification environment as 
    described in the test utils verification environment specification.
*/
class unit_test_env extends uvm_env;

    stb_dec::interface_agent_work_mode_e          test_if_agent_work_mode[2];             ///< The work mode for test_if_agent
    test_interface_agent                          test_if_agent[2];                       ///< Define the test interface agent
    test_interface_agent_cfg                      test_if_agent_cfg[2];                   ///< Define the test interface agent cfg
    unit_test_checker                             unit_test_chk;                          ///< Define the unit_test_chk to simulate read option
    uvm_tlm_analysis_fifo #(uvm_sequence_item)    test_if_agent_out_port_fifo[2];

    `uvm_component_utils(unit_test_env)

    extern function new(string         name,
                        uvm_component  parent
                        );    
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);                          

endclass: unit_test_env

function unit_test_env::new(string         name,
                            uvm_component  parent
                           );

    super.new(name, parent);

endfunction: new

function void unit_test_env::build_phase(uvm_phase phase);

    super.build_phase(phase);

    this.test_if_agent_work_mode[0] = stb_dec::MASTER_NO_MONITOR;
    this.test_if_agent_work_mode[1] = stb_dec::ONLY_MONITOR;

    foreach(test_if_agent_out_port_fifo[i]) begin
        this.test_if_agent_out_port_fifo[i] = new($sformatf("test_if_agent_out_port_fifo[%0d]", i), this);
    end

    foreach(test_if_agent[i]) begin
        this.test_if_agent[i] = test_interface_agent::type_id::create($sformatf("test_if_agent[%0d]", i), this);
        if(this.test_if_agent_cfg[i] == null) begin
            this.test_if_agent_cfg[i] = test_interface_agent_cfg::type_id::create($sformatf("test_if_agent_cfg[%0d]", i), this);
        end
        if (!this.test_if_agent_cfg[i].randomize()) begin
            `uvm_fatal(get_type_name(), $sformatf("build_phase(): Unabled to randomize test_if_agent_cfg[%0d] in env", i));
        end       
        this.test_if_agent[i].cfg = this.test_if_agent_cfg[i];
        this.test_if_agent[i].work_mode = this.test_if_agent_work_mode[i];
    end

    this.unit_test_chk = unit_test_checker::type_id::create("unit_test_chk", this);

endfunction: build_phase

function void unit_test_env::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    this.test_if_agent[0].mon_port.connect(this.test_if_agent_out_port_fifo[0].analysis_export);
    this.unit_test_chk.in_port[0].connect(this.test_if_agent_out_port_fifo[0].blocking_get_export);

    this.test_if_agent[1].mon_port.connect(this.test_if_agent_out_port_fifo[1].analysis_export);
    this.unit_test_chk.in_port[1].connect(this.test_if_agent_out_port_fifo[1].blocking_get_export);
    
endfunction: connect_phase

`endif

