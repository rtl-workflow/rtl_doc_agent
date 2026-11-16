//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 21:38
//Abstract        : multi_stream_scoreboard_cfg.sv
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 21:38 , by gaea_platform)
//  ... version info ... 
//##################################################################
`ifndef MULTI_STREAM_SB_CFG_SV 
`define MULTI_STREAM_SB_CFG_SV

class multi_stream_scoreboard_cfg extends uvm_object;
    glb_dec::sb_vip_comp_mode  comp_mode = glb_dec::IN_ORDER;
    glb_dec::sb_vip_latency_mode  latency_mode = glb_dec::NON_LATENCY;

    bit   scb_en;
    bit   mode_switch_en;
    bit   actual_zero_report_err_enable;

    int ignore_id = -1;
    int delay_cyc = 300;

    `uvm_object_utils_begin(multi_stream_scoreboard_cfg)
        `uvm_field_enum(glb_dec::sb_vip_comp_mode,comp_mode,UVM_ALL_ON)
        `uvm_field_enum(glb_dec::sb_vip_latency_mode,latency_mode,UVM_ALL_ON)
        `uvm_field_int(mode_switch_en,UVM_ALL_ON)
        `uvm_field_int(actual_zero_report_err_enable,UVM_ALL_ON)
    `uvm_object_utils_end
    extern function new(string name="multi_stream_scoreboard_cfg");
endclass

function multi_stream_scoreboard_cfg::new(string name="multi_stream_scoreboard_cfg");
    super.new(name);

    comp_mode = glb_dec::OUT_OF_ORDER;
    mode_switch_en = 1'b1;
    scb_en = 1'b1;
    actual_zero_report_err_enable=1;
endfunction

`endif
