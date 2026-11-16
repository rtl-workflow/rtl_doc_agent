//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-11-16 11:53
//Abstract        : svf_sanity
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-11-16 11:53 , by gaea_platform)
//  ... version info ...
//
//##################################################################
`ifndef _svf_sanity_CLASS_
`define _svf_sanity_CLASS_

`define TC svf_sanity

class `superbench_demo_env_cfg(`TC) extends superbench_demo_env_cfg;

    `uvm_object_utils_begin(`superbench_demo_env_cfg(`TC))
    `uvm_object_utils_end
    function new(string name = `"`superbench_demo_env_cfg(`TC)`");
        super.new(name);
    endfunction

    function void post_randomize();
        super.post_randomize();
    endfunction

    constraint tc_cons{
        //vlanid == 20;
    }
endclass

class `superbench_demo_dut_cfg(`TC) extends superbench_demo_dut_cfg;

    `uvm_object_utils_begin(`superbench_demo_dut_cfg(`TC))
    `uvm_object_utils_end
    function new(string name = `"`superbench_demo_dut_cfg(`TC)`");
        super.new(name);
    endfunction

    function void post_randomize();
        super.post_randomize();
    endfunction

    constraint tc_cons{
        //vlanid == 20;
    }
endclass

class `gen_temp_sequence(`TC) extends gen_temp_sequence #(.DATA_TYPE(uvm_sequence_item));
    `uvm_object_utils(`gen_temp_sequence(`TC))
    function new(string name = "gen_temp_sequence");
        super.new(name);
        item_cnt = 2;//pkt number control;
    endfunction
    virtual task body();
        repeat(this.item_cnt) begin
            `uvm_do_with(m_trans,{
            //m_trans.data_id == obj_cnt;
            });
            this.obj_cnt ++;
        end
        //#5us;
    endtask
endclass

class `TC extends basic_tc;

    `uvm_component_utils(`TC)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction:new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        set_report_max_quit_count(5000);
        this.u_env.u_superbench_demo_env_cfg = `superbench_demo_env_cfg(`TC)::type_id::create({this.u_env.get_full_name,".u_superbench_demo_env_cfg"}, this);
        this.u_env.u_superbench_demo_env_cfg.u_superbench_demo_dut_cfg = `superbench_demo_dut_cfg(`TC)::type_id::create({this.u_env.u_superbench_demo_env_cfg.get_full_name,".u_superbench_demo_dut_cfg"}, this);
        set_type_override_by_type(gen_temp_sequence#(.DATA_TYPE(uvm_sequence_item))::get_type(),`gen_temp_sequence(`TC)::get_type());
    endfunction

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);
        //#1us;
        phase.drop_objection(this);
        endtask:reset_phase

    virtual task configure_phase(uvm_phase phase);
        super.configure_phase(phase);
        phase.raise_objection(this);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        // add you global configure here
        u_env.u_superbench_demo_env_cfg.u_superbench_demo_dut_cfg.cfg_dut();
        // -----------
        phase.drop_objection(this);
        endtask:configure_phase

    virtual task main_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.phase_done.set_drain_time(this,50us);
        phase.raise_objection(this);
        super.main_phase(phase);

        // add you glb test step here;

        begin
            //#1us;
            /* `ifdef UVM_1P2
				u_env.u_gen_temp.seq.set_starting_phase(phase);
			`else
				u_env.u_gen_temp.seq.starting_phase = phase;
			`endif
			u_env.u_gen_temp.seq.start(u_env.u_gen_temp.sqr); */
        end
        phase.drop_objection(this);
    endtask:main_phase

    virtual task post_main_phase(uvm_phase phase);
        super.post_main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);

        phase.drop_objection(this);
    endtask:post_main_phase

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if($test$plusargs("UVM_VERBOSITY=UVM_DEBUG"))begin
            check_config_usage();
        end
        `uvm_info(get_type_name(),"check_phase():check_phase() finished",UVM_HIGH);
        phase.phase_done.display_objections();

    endfunction:check_phase
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction:report_phase
endclass
`undef TC
`endif // svf_sanity_CLASS_