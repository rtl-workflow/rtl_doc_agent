//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:27
//Abstract        : GAEA_PROJ_NAME_ENV_CFG 
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-03 22:26:57 , by c00800326);
//Revision 1.1  ( 2025-11-03 22:27:28 , by c00800326);
//Revision 1.2  ( 2025-11-04 11:41:27 , by c00800326);

//##################################################################
`ifndef GAEA_DEMO_ENV_CFG_SV 
`define GAEA_DEMO_ENV_CFG_SV

`define gaea_demo_env_cfg(tc) tc``_gaea_demo_env_cfg
class gaea_demo_env_cfg //GAEA_PLATFORM::CLASSNAME
        extends uvm_object; //GAEA_PLATFORM::TYPE
    `TOP_MODEL model;

    //!GAEA_BLOCK_BEGIN_DECLARE
    func_single_scoreboard_cfg    u_func_single_scoreboard_cfg;
    bfm_temp_cfg    u_bfm_temp_cfg;
    rm_temp_cfg    u_rm_temp_cfg;
    bfm_cbus_cfg    u_bfm_cbus_cfg;
    gen_temp_cfg    u_gen_temp_cfg;
    rand gaea_demo_dut_cfg    u_gaea_demo_dut_cfg;
    //!GAEA_BLOCK_END_DECLARE

    `uvm_object_utils_begin(gaea_demo_env_cfg)
        //!GAEA_BLOCK_BEGIN_UTILS
        `uvm_field_object(u_func_single_scoreboard_cfg,UVM_ALL_ON);
        `uvm_field_object(u_bfm_temp_cfg,UVM_ALL_ON);
        `uvm_field_object(u_rm_temp_cfg,UVM_ALL_ON);
        `uvm_field_object(u_bfm_cbus_cfg,UVM_ALL_ON);
        `uvm_field_object(u_gen_temp_cfg,UVM_ALL_ON);
        `uvm_field_object(u_gaea_demo_dut_cfg, UVM_ALL_ON);
        //!GAEA_BLOCK_END_UTILS
    `uvm_object_utils_end

    extern function new(string name="gaea_demo_env_cfg");
    extern virtual function void pre_build();
    extern virtual function void build();
    extern virtual function void post_build();
    extern function rand_cfg();
    extern function build_cfg();
    extern function print_cfg();
endclass

function gaea_demo_env_cfg::new(string name="gaea_demo_env_cfg");
    super.new(name);
    //!GAEA_BLOCK_BEGIN_CONFIGURE_INSTANTIATION
    u_func_single_scoreboard_cfg  =  func_single_scoreboard_cfg::type_id::create("u_func_single_scoreboard_cfg");
    u_bfm_temp_cfg  =  bfm_temp_cfg::type_id::create("u_bfm_temp_cfg");
    u_rm_temp_cfg  =  rm_temp_cfg::type_id::create("u_rm_temp_cfg");
    u_bfm_cbus_cfg  =  bfm_cbus_cfg::type_id::create("u_bfm_cbus_cfg");
    u_gen_temp_cfg  =  gen_temp_cfg::type_id::create("u_gen_temp_cfg");
    u_gaea_demo_dut_cfg  =  gaea_demo_dut_cfg::type_id::create("u_gaea_demo_dut_cfg");
    u_bfm_temp_cfg.work_mode = glb_dec::NORMAL;

    u_bfm_cbus_cfg.work_mode = glb_dec::NORMAL;

    //!GAEA_BLOCK_END_CONFIGURE_INSTANTIATION

    // USER: Start configure the tb
endfunction

function void gaea_demo_env_cfg::pre_build();
    // USER: please complete the function
endfunction

function void gaea_demo_env_cfg::build();
    // USER: please complete the function
    this.pre_build();
    //!GAEA_BLOCK_BEGIN_BUILD
    u_gaea_demo_dut_cfg.model = model;
    //u_gaea_demo_dut_cfg.build();

    //!GAEA_BLOCK_END_BUILD
    this.post_build();
endfunction

function void gaea_demo_env_cfg::post_build();
    // USER: please complete the function
endfunction

function gaea_demo_env_cfg::rand_cfg();
    // USER: please complete the function
endfunction

function gaea_demo_env_cfg::build_cfg();
    // USER: please complete the function
endfunction

function gaea_demo_env_cfg::print_cfg();
    // USER: please complete the function
endfunction
`endif

