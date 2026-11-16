//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : tc_base.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : base decode test for environment test
//
//******************************************************************************

`ifndef TC_BASE__SV
`define TC_BASE__SV

/** \brief tc_base class 
    This class is the base tc class
*/
class tc_base extends uvm_test;

    `uvm_component_utils(tc_base)

    unit_test_env   env;

    extern function new(string name = "tc_base", uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);

    /** \brief report_phase()
    Report the testcase is pass or not
    */
    extern virtual function void report_phase(uvm_phase phase);

    /** \brief pre_abort()
    When the simulation errors nums is more than max errors you set or simulation is fatal, 
    UVM will call pre_abort automatic
    */
    extern virtual function void pre_abort();

endclass

function tc_base::new(string name = "tc_base", uvm_component parent);

    super.new(name,parent);

endfunction: new

function void tc_base::build_phase(uvm_phase phase);

    super.build_phase(phase);
    this.env = unit_test_env::type_id::create("env", this);

endfunction: build_phase

function void tc_base::report_phase(uvm_phase phase);

    uvm_report_server report_svr = uvm_report_server::get_server();
    int count_fatal = report_svr.get_severity_count(UVM_FATAL);
    int count_err = report_svr.get_severity_count(UVM_ERROR);
    int count_warning = report_svr.get_severity_count(UVM_WARNING);
    
    super.report_phase(phase);
    if(count_fatal == 0) begin
        if(count_err == 0) begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation PASSED at%15t  (%0d warnings) \n", 
                      $realtime, count_warning), UVM_NONE);
        end 
        else begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t  (%0d errors, %0d warnings) \n", 
                      $realtime, count_err, count_warning), UVM_NONE);
        end
    end
    else begin
        `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t  (%0d fatals, %0d errors, %0d warnings) \n", 
                                          $realtime, count_fatal, count_err, count_warning), UVM_NONE);
    end

endfunction: report_phase

function void tc_base::pre_abort();

    uvm_report_server report_svr = uvm_report_server::get_server();
    int count_fatal = report_svr.get_severity_count(UVM_FATAL);
    int count_err = report_svr.get_severity_count(UVM_ERROR);
    int count_warning = report_svr.get_severity_count(UVM_WARNING);
    `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t  (%0d fatals, %0d errors, %0d warnings) \n", 
                                          $realtime, count_fatal, count_err, count_warning), UVM_NONE);    

endfunction: pre_abort

`endif

