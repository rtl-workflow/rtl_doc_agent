//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-11-16 11:53
//Abstract        : svf_l2_fwd
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-11-16 11:53 , by gaea_platform)
//  ... version info ...
//
//##################################################################
`ifndef _svf_int_ecc_iacl_CLASS_
`define _svf_int_ecc_iacl_CLASS_

`undef TC
`define TC svf_int_ecc_iacl

class `TC extends basic_tc;
    bit [31:0] rdata;
    bit [31:0] test_data;
    string root;
    string hdl_path;
    `uvm_component_utils(`TC)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction:new

//    extern virtual task rw_rst_cmd()                                            ;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //set_report_max_quit_count(5000);

    endfunction
//========================================================================================================
//
//========================================================================================================
function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    root="int_iacl";
    hdl_path="tb_top.u_iacl_top";
    int_tree::set_root($psprintf("%s",root));
    
    //root
    int_tree::def_int($psprintf("%s",root),
                      "tb_top.u_iacl_top.int_iacl[1:1]",
                      null,    //int_en
                      null,    //wc
                      null,
                      null);   //ro
    

    int_tree::def_int(  //bit0  rx fifo
        "int_iacl.int_status_ram_ecc",
        "tb_top.u_iacl_top.u_iacl_key_rddcd.o_painfo_ram_ecc_err",
        reg_model.cib_pp.cib_iacl.int_mask_cfg_ram_ecc.int_mask_cfg_ram_ecc,
        reg_model.cib_pp.cib_iacl.int_status_ram_ecc.int_status_ram_ecc,
        null,
        reg_model.cib_pp.cib_iacl.int_force_cfg.int_force_cfg_ram_ecc,
        -1,32'd0,null,-1);  


//==============================================================================================
    int_tree::print_int_tree(root);

    u_env.u_iacl_bt_env_cfg.u_rm_iacl_cfg.ecc_check_en=0;
    //==============================================================================================
endfunction:connect_phase
//========================
// extern virtual task run_phase(uvm_phase phase)                              ;
//========================================================================================================
function void report_test_result()                                                     ;
    uvm_report_server report_svr = uvm_report_server::get_server()                                  ;
    int count_fatal = report_svr.get_severity_count(UVM_FATAL)                                      ;
    int count_err = report_svr.get_severity_count(UVM_ERROR)                                        ;
    int count_warning = report_svr.get_severity_count(UVM_WARNING)                                  ;
    
    if(count_fatal == 0) begin
        if(count_err == 0) begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation PASSED at%15t  (%0d warnings) \n", 
                      $realtime, count_warning), UVM_NONE)
        end 
        else begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t  (%0d errors, %0d warnings) \n", 
                      $realtime, count_err, count_warning), UVM_NONE)
        end
    end
    else begin
        `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t  (%0d fatals, %0d errors, %0d warnings) \n", 
                                          $realtime, count_fatal, count_err, count_warning), UVM_NONE)
    end
endfunction:report_test_result

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);
        //#1us;
        phase.drop_objection(this);
        endtask:reset_phase

    virtual task configure_phase(uvm_phase phase);
        //super.configure_phase(phase);
        phase.raise_objection(this);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        // add you global configure here
//        u_env.u_stat_subenv.u_rm_stat_check.post_sim_check = 0;
//        u_env.u_ld2125_st_env_cfg.u_ld2125_st_dut_cfg.cfg_dut();
        // -----------
        phase.drop_objection(this);
        endtask:configure_phase

    virtual task post_configure_phase(uvm_phase phase);
        //super.post_configure_phase(phase);
        phase.raise_objection(this);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        // add you global configure here

        // -----------
        phase.drop_objection(this);
    endtask:post_configure_phase

    virtual task main_phase(uvm_phase phase);
        uvm_status_e        status  ;
        uvm_reg             vr_reg  ;

        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.phase_done.set_drain_time(this,50us);
        phase.raise_objection(this);
        super.main_phase(phase);
        // add you glb test step here;
        int_tree::clear_all_alarm();
        this.reg_model.reset();
        #20us;
        int_tree::check_tree();
        phase.drop_objection(this);
        this.report_test_result();
    endtask:main_phase

    virtual task post_main_phase(uvm_phase phase);
        //super.post_main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);

        phase.drop_objection(this);
    endtask:post_main_phase

    virtual task shutdown_phase(uvm_phase phase);
        //super.shutdown_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(),$sformatf("interrupt  display!!!!"),UVM_LOW)    
        phase.drop_objection(this);
    endtask:shutdown_phase

    virtual function void check_phase(uvm_phase phase);
        //super.check_phase(phase);
//        if($test$plusargs("UVM_VERBOSITY=UVM_DEBUG"))begin
//            check_config_usage();
//        end
//        `uvm_info(get_type_name(),"check_phase():check_phase() finished",UVM_HIGH);
        phase.phase_done.display_objections();

    endfunction:check_phase
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction:report_phase
endclass
`endif // svf_int_ecc_mac0_CLASS_


