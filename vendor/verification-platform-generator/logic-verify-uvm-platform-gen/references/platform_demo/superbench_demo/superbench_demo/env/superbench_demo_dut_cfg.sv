//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:13
//Abstract        : dut_cfg
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 16:09:13 , by c00800326);

//##################################################################
`ifndef SUPERBENCH_DEMO_DUT_CFG_SV 
`define SUPERBENCH_DEMO_DUT_CFG_SV

`define superbench_demo_dut_cfg(tc) tc``_superbench_demo_dut_cfg
class superbench_demo_dut_cfg // GAEA_PLATFORM::CLASSNAME
        extends lvp_dut_cfg_base; // GAEA_PLATFORM::TYPE
    uvm_status_e    status                  ;
    uvm_path_e      path = UVM_FRONTDOOR    ;
    static uvm_reg  test_reg[$]             ;
    `TOP_MODEL model;

    //!GAEA_BLOCK_BEGIN_DECLARE
    //!GAEA_BLOCK_END_DECLARE

    `uvm_object_utils_begin(superbench_demo_dut_cfg)
         //!GAEA_BLOCK_BEGIN_UTILS
        //!GAEA_BLOCK_END_UTILS
    `uvm_object_utils_end

    extern         function         new(string name = "superbench_demo_dut_cfg") ;
    extern virtual function   void  build()                               ;
    extern virtual task             cfg_dut()                             ;
    extern virtual task             cfg_ram_init()                        ;
    extern virtual task             ncfg_ram_init()                       ;
    extern virtual task             check_alm(bit chk_en = 1)             ;
    extern virtual function void    load_test_reg()                       ;

    //the tasks called by cfg_dut
    extern virtual task             set_cfg()                             ;
    extern virtual task             cfg_reg()                             ;
    extern virtual task             cfg_mem()                             ;
    extern virtual task             cfg_clk()                             ;

    //the tasks called by check_alm
    extern virtual task             chk_int(bit chk_en = 1)               ; //to check interrupt regs
    extern virtual task             chk_cnt(bit chk_en = 1)               ; //to check counter regs
    extern virtual task             chk_sta(bit chk_en = 1)               ; //to check status regs

endclass : superbench_demo_dut_cfg

function superbench_demo_dut_cfg::new(string name = "superbench_demo_dut_cfg");
    super.new(name);
    //!GAEA_BLOCK_BEGIN_CONFIGURE_INSTANTIATION
    //!GAEA_BLOCK_END_CONFIGURE_INSTANTIATION
endfunction

function void superbench_demo_dut_cfg::build();
    `uvm_info(get_type_name(), "build begin", UVM_NONE);
    // USER: please complete reg_model information for subenv in this function.
    // u_otn_dut_cfg.model = this.model.CIB_LD83X4_B;
    `uvm_info(get_type_name(), "build end", UVM_NONE);
endfunction

//BT should override cfg_dut only if the call-task-flow not match BT's requirements!
task superbench_demo_dut_cfg::cfg_dut();
    `uvm_info(get_type_name(), "cfg_dut begin", UVM_NONE);
    this.set_cfg();
    this.cfg_reg();
    this.cfg_mem();
    this.cfg_clk();
    `uvm_info(get_type_name(), "cfg_dut end", UVM_NONE);
endtask

//BT should override check_alm only if the call-task-flow not match BT's requirements!
task superbench_demo_dut_cfg::check_alm(bit chk_en = 1);
    `uvm_info(get_type_name(), $psprintf("check_alm(%0d) begin",chk_en), UVM_NONE);
    this.chk_int(chk_en);
    this.chk_cnt(chk_en);
    this.chk_sta(chk_en);
    `uvm_info(get_type_name(), $psprintf("check_alm(%0d) end",chk_en), UVM_NONE);
endtask

task superbench_demo_dut_cfg::cfg_ram_init();
endtask

task superbench_demo_dut_cfg::ncfg_ram_init();
endtask

//BT should override load_test_reg to push selected test rw res for IT/subST/ST into this.test_reg[$]
function void superbench_demo_dut_cfg::load_test_reg();
    //`uvm_error(get_type_name(), "load_test_reg function not implemented !");
endfunction

task superbench_demo_dut_cfg::set_cfg();
endtask

task superbench_demo_dut_cfg::cfg_reg();
endtask

task superbench_demo_dut_cfg::cfg_mem();
endtask

task superbench_demo_dut_cfg::cfg_clk();
endtask

task superbench_demo_dut_cfg::chk_int(bit chk_en = 1);
endtask

task superbench_demo_dut_cfg::chk_cnt(bit chk_en = 1);
endtask

task superbench_demo_dut_cfg::chk_sta(bit chk_en = 1);
endtask

`endif
