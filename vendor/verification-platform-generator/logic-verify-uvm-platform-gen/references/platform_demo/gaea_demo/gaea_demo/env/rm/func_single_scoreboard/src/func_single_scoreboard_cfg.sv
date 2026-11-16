//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 21:38
//Abstract        : func_single_scoreboard_cfg.sv
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 21:38 , by gaea_platform)
//  ... version info ... 
//
//##################################################################
`ifndef FUNC_SINGLE_SCOREBOARD_CFG_SV 
`define FUNC_SINGLE_SCOREBOARD_CFG_SV

class func_single_scoreboard_cfg // GAEA_PLATFORM::CLASSNAME
    extends uvm_object; // GAEA_PLATFORM::TYPE
    glb_dec::sb_vip_comp_mode  comp_mode = glb_dec::IN_ORDER;
    bit   mode_switch_en;

    `uvm_object_utils_begin(func_single_scoreboard_cfg)
        `uvm_field_enum(glb_dec::sb_vip_comp_mode,comp_mode,UVM_ALL_ON)
        `uvm_field_int(mode_switch_en,UVM_ALL_ON)
    `uvm_object_utils_end
    extern function new(string name="func_single_scoreboard_cfg");
endclass

function func_single_scoreboard_cfg::new(string name="func_single_scoreboard_cfg");
    super.new(name);

    comp_mode = glb_dec::IN_ORDER;
    mode_switch_en = 1'b1;
endfunction

`endif
