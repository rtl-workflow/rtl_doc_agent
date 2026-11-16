//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          :
//Initial-Date    :
//Abstract        : rm_broadcast_for_gen_cfg
//##################################################################

`ifndef rm_broadcast_for_gen_CFG_SV
`define rm_broadcast_for_gen_CFG_SV

class rm_broadcast_for_gen_cfg     // GAEA_PLATFORM::CLASSNAME
extends uvm_object;                 // GAEA_PLATFORM::TYPE
    // BEGIN: EDITABLE SECTION
    // Declare your variables here
   int outport_num;    // 输出端口数量，默认2

    // END: EDITABLE SECTION

    `uvm_object_utils_begin(rm_broadcast_for_gen_cfg)
    // BEGIN: EDITABLE SECTION
    `uvm_field_int(outport_num, UVM_ALL_ON)
    // END: EDITABLE SECTION        
    `uvm_object_utils_end

    function new(string name="rm_broadcast_for_gen_cfg");
        super.new(name);
        // BEGIN: EDITABLE SECTION
        outport_num = 2;  // 默认2个输出端口

        // END: EDITABLE SECTION
    endfunction
endclass

`endif
