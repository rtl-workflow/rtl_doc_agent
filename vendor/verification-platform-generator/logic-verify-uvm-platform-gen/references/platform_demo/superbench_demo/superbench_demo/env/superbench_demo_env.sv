//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:15
//Abstract        : 
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 16:09:15 , by c00800326);

//##################################################################
`ifndef SUPERBENCH_DEMO_ENV_SV
`define SUPERBENCH_DEMO_ENV_SV
class superbench_demo_env //GAEA_PLATFORM::CLASSNAME
      extends uvm_env;  //GAEA_PLATFORM::TYPE
    superbench_demo_env_cfg         u_superbench_demo_env_cfg;//NOTICE:DONT CHANGE
    //CPU component
    cpu_sqr         u_cpu_sqr    ;//NOTICE:DONT CHANGE
    // reg_model
    `TOP_MODEL      reg_model    ;
    cpu_adapter     u_cpu_adapter;
    // mpi_path
    uvm_path_e      mpi_path     ;

    //!GAEA_BLOCK_BEGIN_DECLARE
    bfm_cbus #(.AWIDTH(glb_dec::U_BFM_CBUS_AWIDTH),.DWIDTH(glb_dec::U_BFM_CBUS_DWIDTH)) u_bfm_cbus;
    func_single_scoreboard u_func_single_scoreboard;
    rm_temp #(.IN_DATA_TYPE(uvm_sequence_item),.OUT_DATA_TYPE(uvm_sequence_item)) u_rm_temp;
    gen_temp #(.DATA_TYPE(uvm_sequence_item)) u_gen_temp;
    bfm_temp #(.DATA_TYPE(uvm_sequence_item),.DAT_WIDTH(glb_dec::U_BFM_TEMP_DAT_WIDTH)) u_bfm_temp;
    base_tlm_fifo u_gen_temp_outport_to_u_bfm_temp_inport;
	base_tlm_fifo u_bfm_temp_outport_to_u_rm_temp_inport;
	base_tlm_fifo u_rm_temp_outport_to_u_func_single_scoreboard_real_port;
	base_tlm_fifo u_rm_temp_outport1_to_u_func_single_scoreboard_exp_port;
    //!GAEA_BLOCK_END_DECLARE

    `uvm_component_utils(superbench_demo_env)

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);

endclass: superbench_demo_env

function superbench_demo_env::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction:new

function void superbench_demo_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // configure reg_model
    u_cpu_adapter   = new("reg_sqr_adapter");
    reg_model       = `TOP_MODEL::type_id::create("reg_model", this);
    reg_model.configure(null,);
	uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
    reg_model.build();
    reg_model.lock_model();
    reg_model.reset();
    void'(reg_model.set_coverage(UVM_CVR_ALL));

    // CPU component
    u_cpu_sqr = cpu_sqr::type_id::create("u_cpu_sqr",this);//NOTICE:DONT CHANGE
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if(u_superbench_demo_env_cfg == null)
        `uvm_fatal(get_type_name(),"u_superbench_demo_env_cfg get null,please check it!")
    else if(!u_superbench_demo_env_cfg.randomize())
        `uvm_fatal(get_type_name(),"u_superbench_demo_env_cfg randomize err,please check it!")
    else
        `uvm_info(get_type_name(),$psprintf("create superbench_demo_env_cfg\n%0s",u_superbench_demo_env_cfg.sprint()),UVM_MEDIUM)

    u_superbench_demo_env_cfg.model = reg_model;
    u_superbench_demo_env_cfg.build();

    //!GAEA_BLOCK_BEGIN_GEN_INSTANTIATION  //generator
    u_gen_temp = gen_temp #(.DATA_TYPE(uvm_sequence_item))::type_id::create("u_gen_temp", this);
    u_gen_temp.cfg = u_superbench_demo_env_cfg.u_gen_temp_cfg;
    //!GAEA_BLOCK_END_GEN_INSTANTIATION

    //!GAEA_BLOCK_BEGIN_BFM_INSTANTIATION  //interface
    u_bfm_cbus = bfm_cbus #(.AWIDTH(glb_dec::U_BFM_CBUS_AWIDTH),.DWIDTH(glb_dec::U_BFM_CBUS_DWIDTH))::type_id::create("u_bfm_cbus", this);
    u_bfm_cbus.cfg = u_superbench_demo_env_cfg.u_bfm_cbus_cfg;
    u_bfm_temp = bfm_temp #(.DATA_TYPE(uvm_sequence_item),.DAT_WIDTH(glb_dec::U_BFM_TEMP_DAT_WIDTH))::type_id::create("u_bfm_temp", this);
    u_bfm_temp.cfg = u_superbench_demo_env_cfg.u_bfm_temp_cfg;
    //!GAEA_BLOCK_END_BFM_INSTANTIATION
    //!GAEA_BLOCK_END_BFM_INSTANTIATION

    //!GAEA_BLOCK_BEGIN_FUNC_INSTANTIATION  //reference module, checker, scoreboard
    u_func_single_scoreboard = func_single_scoreboard::type_id::create("u_func_single_scoreboard", this);
    u_func_single_scoreboard.cfg = u_superbench_demo_env_cfg.u_func_single_scoreboard_cfg;
    u_rm_temp = rm_temp #(.IN_DATA_TYPE(uvm_sequence_item),.OUT_DATA_TYPE(uvm_sequence_item))::type_id::create("u_rm_temp", this);
    u_rm_temp.cfg = u_superbench_demo_env_cfg.u_rm_temp_cfg;
    //!GAEA_BLOCK_END_FUNC_INSTANTIATION

    //!GAEA_BLOCK_BEGIN_CHANNEL_INSTANTIATION
    u_gen_temp_outport_to_u_bfm_temp_inport = new("u_gen_temp_outport_to_u_bfm_temp_inport", this);
	u_bfm_temp_outport_to_u_rm_temp_inport = new("u_bfm_temp_outport_to_u_rm_temp_inport",this);
	u_rm_temp_outport_to_u_func_single_scoreboard_real_port = new("u_rm_temp_outport_to_u_func_single_scoreboard_real_port",this);
	u_rm_temp_outport1_to_u_func_single_scoreboard_exp_port = new("u_rm_temp_outport1_to_u_func_single_scoreboard_exp_port",this);
    //!GAEA_BLOCK_END_CHANNEL_INSTANTIATION

    //!GAEA_BLOCK_BEGIN_SUBENV_INSTANTIATION
    //!GAEA_BLOCK_END_SUBENV_INSTANTIATION

    uvm_top.set_timeout(1ms, 1);

    // calling rand_cfg/build_cfg/print_cfg functions in env_cfg
    u_superbench_demo_env_cfg.rand_cfg();
    u_superbench_demo_env_cfg.build_cfg();
    u_superbench_demo_env_cfg.print_cfg();
    // USER: Start transactors needed to configure the DUT
endfunction:build_phase

function void superbench_demo_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    // configure reg_model
    `uvm_info(get_type_name(),"base_test start of connect_phase",UVM_MEDIUM)
    reg_model.default_map.set_sequencer(u_cpu_sqr,u_cpu_adapter);
    reg_model.default_map.set_auto_predict(1);
    `uvm_info(get_type_name(),"base_test end of connect_phase",UVM_MEDIUM)

    //!GAEA_BLOCK_BEGIN_CONNECTION
    u_bfm_cbus.seq_item_port.connect(u_cpu_sqr.seq_item_export);
    
    u_gen_temp.outport.connect(u_gen_temp_outport_to_u_bfm_temp_inport.blocking_put_export);
    u_bfm_temp.inport.connect(u_gen_temp_outport_to_u_bfm_temp_inport.blocking_get_export);

    // Connect bfm_temp outport to rm_temp inport
    u_bfm_temp.outport.connect(u_bfm_temp_outport_to_u_rm_temp_inport.blocking_put_export);
    u_rm_temp.inport.connect(u_bfm_temp_outport_to_u_rm_temp_inport.blocking_get_export);

    // Connect rm_temp outport to scoreboard real_port
    u_rm_temp.outport.connect(u_rm_temp_outport_to_u_func_single_scoreboard_real_port.blocking_put_export);
    u_func_single_scoreboard.real_port.connect(u_rm_temp_outport_to_u_func_single_scoreboard_real_port.blocking_get_export);
	u_rm_temp.outport1.connect(u_rm_temp_outport1_to_u_func_single_scoreboard_exp_port.blocking_put_export);
    u_func_single_scoreboard.exp_port.connect(u_rm_temp_outport1_to_u_func_single_scoreboard_exp_port.blocking_get_export);
    //!GAEA_BLOCK_END_CONNECTION
endfunction:connect_phase

task superbench_demo_env::main_phase(uvm_phase phase);
    super.main_phase(phase);
    `uvm_info("TRACE", $sformatf("%m env main phase"), UVM_HIGH);

    //Add your custom codes here:
    //!GAEA_BLOCK_BEGIN_XACTOR_START

    //!GAEA_BLOCK_END_XACTOR_START

endtask:main_phase

`endif // C_ENV_SV
