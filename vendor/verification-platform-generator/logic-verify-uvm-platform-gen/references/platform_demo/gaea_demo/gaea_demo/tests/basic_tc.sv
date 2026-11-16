/**********************************************************************************
Copyright(c) 2014 Huawei Technologies Co., Ltd, All rights reserved
Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
Filename     :   basic_tc.sv.tplt
Author       :   GaeaPlatform
===============================================================================
Description  :   1, modify for public UVP testbench
Modification History:
Date        By                      Rev.    Prj.            Change Description
-------------------------------------------------------------------------------
2018-07-03   l00431352              1.0     GaeaPlatform    Create
**********************************************************************************/
`ifndef __BASIC_TC__
`define __BASIC_TC__

class basic_tc extends uvm_test;

    gaea_demo_env              u_env           ;
    top_cib_model       reg_model       ;
    uvm_status_e        status          ;
    gaea_demo_env_cfg             u_gaea_demo_env_cfg       ;
    base_report_server report_server;

    `uvm_component_utils(basic_tc)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_NONE)
    endfunction:new
    function void set_report_max_quit_count(int max_count);
        uvm_report_server l_rs = uvm_report_server::get_server();
        l_rs.set_max_quit_count(max_count);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //uvm_report_server  srvr = uvm_report_server::get_server();
        u_env = gaea_demo_env#()::type_id::create("u_env", this);
        u_gaea_demo_env_cfg = gaea_demo_env_cfg::type_id::create("u_gaea_demo_env_cfg");
        u_env.u_gaea_demo_env_cfg=u_gaea_demo_env_cfg;

        //set the max UVM error number when exit simulations.
        //set_report_max_quit_count(10);

        // configure report_server
        $timeformat(-9, 0, "ns", 1);
        report_server = new();
        uvm_report_server::set_server(report_server);
        report_server.set_max_quit_count(9999);
    endfunction:build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        uvm_top.set_timeout(5ms,1);
        reg_model = u_env.reg_model;
    endfunction:connect_phase

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_NONE)
        phase.raise_objection(this);
        #1us;
        phase.drop_objection(this);
    endtask:reset_phase

    virtual task configure_phase(uvm_phase phase);
        super.configure_phase(phase);

        phase.raise_objection(this);
        `uvm_info("TRACE", $sformatf("%m"), UVM_NONE)
        // add you global configure here
        u_env.u_gaea_demo_env_cfg.u_gaea_demo_dut_cfg.cfg_dut();
        // -----------
        phase.drop_objection(this);

    endtask:configure_phase

    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_NONE)
        phase.raise_objection(this);

        // add you glb test step here;
        phase.drop_objection(this);
    endtask:main_phase

    virtual task post_main_phase(uvm_phase phase);
        super.post_main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_NONE)
        phase.raise_objection(this);
       
        phase.drop_objection(this);
    endtask:post_main_phase

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if($test$plusargs("UVM_VERBOSITY=UVM_DEBUG"))begin
            check_config_usage();
        end
        `uvm_info(get_type_name(),"check_phase():check_phase() finished",UVM_NONE)
        //phase.phase_done.display_objections();
    endfunction:check_phase

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction:report_phase

endclass:basic_tc
`endif // __BASIC_TC__
