//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-11-16 11:53
//Abstract        : svf_reg_test_random
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-11-16 11:53 , by gaea_platform)
//  ... version info ...
//
//##################################################################
`ifndef _svf_reg_test_random_CLASS_
`define _svf_reg_test_random_CLASS_

`define TC svf_reg_test_random

class `mcc_env_cfg(`TC) extends mcc_env_cfg;

    `uvm_object_utils_begin(`mcc_env_cfg(`TC))
    `uvm_object_utils_end
    function new(string name = `"`mcc_env_cfg(`TC)`");
        super.new(name);
        u_func_bandwidth_control_cfg.bandwidth = 500;
    endfunction

    function void post_randomize();
        super.post_randomize();
    endfunction

    constraint tc_cons{

    }
endclass

class `mcc_dut_cfg(`TC) extends mcc_dut_cfg;
    `uvm_object_utils_begin(`mcc_dut_cfg(`TC))
    `uvm_object_utils_end
    function new(string name = `"`mcc_dut_cfg(`TC)`");
        super.new(name);
    endfunction

    function void post_randomize();
        super.post_randomize();
    endfunction

    constraint tc_cons{

    }
endclass

class `sequence_basic(`TC) extends sequence_basic #(.DATA_TYPE(pkt_icar_mcc));
    `uvm_object_utils(`sequence_basic(`TC))
    function new(string name = "sequence_basic");
        super.new(name);
        item_cnt = 1000;//pkt number control;
    endfunction
    virtual task body();
        int idx;
        repeat(this.item_cnt) begin
            `uvm_do_with(m_trans,{
                m_trans.data_id == obj_cnt;
            });
            this.obj_cnt ++;
        end
        //#5us;
    endtask
endclass

class `TC extends basic_tc;
    uvm_reg                 regs[$]                     ;
    uvm_status_e            vr_status                   ;
    bit [31:0]              first_addr = 32'h1c0_0000;
    bit [31:0]              last_addr  = 32'h1c2_0000;
    bit [31:0]              exclude_address[$]          ;
    bit [31:0]              value                       ;
    bit [31:0]              reg_test_no=16'hFFFF        ;
    `uvm_component_utils(`TC)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction:new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        set_report_max_quit_count(5000);
        this.u_env.u_mcc_env_cfg = `mcc_env_cfg(`TC)::type_id::create({this.u_env.get_full_name,".u_mcc_env_cfg"}, this);
        this.u_env.u_mcc_env_cfg.u_mcc_dut_cfg = `mcc_dut_cfg(`TC)::type_id::create({this.u_env.u_mcc_env_cfg.get_full_name,".u_mcc_dut_cfg"}, this);
        set_type_override_by_type(sequence_basic#(.DATA_TYPE(pkt_icar_mcc))::get_type(),`sequence_basic(`TC)::get_type());
    endfunction

    function void connect_phase(uvm_phase phase) ;
        super.connect_phase(phase) ;
        reg_model_mcc.get_registers(regs)           ;
        `SET_VLD_ADDR(first_addr,last_addr)
        `EXCLUDE_ACCESS_REG("interrupt_status_debug")
        `EXCLUDE_ACCESS_REG("init_tbl_cfg")
    endfunction    

    function void end_of_elaboration_phase(uvm_phase phase);    
        super.end_of_elaboration_phase(phase);
        
        `uvm_info(get_type_name(), "end_of_elaboration_phase(): end_of_elaboration_phase finished", UVM_HIGH);
    endfunction    

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);
        //#1us;
        phase.drop_objection(this);
        endtask:reset_phase

    virtual task configure_phase(uvm_phase phase);
        bit[31:0] wdata, rdata;
        super.configure_phase(phase);
        phase.raise_objection(this);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        // add you global configure here
        // -----------
        
        phase.drop_objection(this);
        endtask:configure_phase

    virtual task main_phase(uvm_phase phase);
        bit     [31:0]      data            ;
        bit     [511:0]     rdata[$]        ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;
        bit    [511:0]      data_tmp        ;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.phase_done.set_drain_time(this,50us);
        phase.raise_objection(this);
        super.main_phase(phase);

        // add you glb test step here;
        fork
        begin
            //#1us;
            `ifdef UVM_1P2
            u_env.u_gen_icar_mcc.seq.set_starting_phase(phase);
            `else
            u_env.u_gen_icar_mcc.seq.starting_phase = phase;
            `endif
            u_env.u_gen_icar_mcc.seq.start(u_env.u_gen_icar_mcc.sqr);
        end
        begin
            string check_property = "RW";
            #100us;
            @tb_top.u_mcc_top.clk_sys;
            #1ns;
            u_env.u_mcc_env_cfg.u_scb_mcc_epro_cfg.chk_en = 0;
            $display("debug: read begin %t", $time);
            //----1_stg
            foreach(regs[i]) begin
                `GET_REGS_RW_PROPERTY
                data_tmp = {16{data}};
                foreach (vr_domains[j]) begin
                    if(check_property inside reg_field_property) begin
                        regs[i].read(vr_status, data_tmp);
                        rdata.push_back(data_tmp);
                        `uvm_info("", $sformatf("data_tmp=%0h, rdata=%0h,i=%0h",data_tmp, rdata[i], i), UVM_LOW);
                    end
                end
            end
            $display("debug: read end %t", $time);
            $display("debug: write random begin %t", $time);
            foreach(regs[i]) begin
                `GET_REGS_RW_PROPERTY
                foreach (vr_domains[j]) begin
                    if(check_property inside reg_field_property) begin
                        regs[i].write(vr_status, {16{$urandom_range(0, 32'hffff_ffff)}}, UVM_FRONTDOOR);
                    end
                end
            end
            $display("debug: write random end %t", $time);
            #100us;
            @tb_top.u_mcc_top.clk_sys;
            #1ns;
            //----2_stg
            $display("debug: write old begin %t", $time);
            foreach(regs[i]) begin
                `GET_REGS_RW_PROPERTY
                foreach (vr_domains[j]) begin
                    if(check_property inside reg_field_property) begin
                        regs[i].write(vr_status, rdata.pop_front(), UVM_FRONTDOOR);
                    end
                end
            end
            $display("debug: write old end %t", $time);
            #20us;
            @tb_top.u_mcc_top.clk_sys;
            #1ns;
            u_env.u_mcc_env_cfg.u_scb_mcc_epro_cfg.chk_en = 1;
        end
        join
        phase.drop_objection(this);
    endtask:main_phase

    virtual task post_main_phase(uvm_phase phase);
        bit[31:0] read_data;
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
`endif // svf_reg_test_random_CLASS_
