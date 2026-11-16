//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:32
//Abstract        : rm_temp_cfg
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 11:41:32, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _rm_temp_cfg_CLASS_
`define _rm_temp_cfg_CLASS_

class rm_temp_cfg     // GAEA_PLATFORM::CLASSNAME
extends uvm_object;                 // GAEA_PLATFORM::TYPE
    // BEGIN: EDITABLE SECTION
    // Declare your variables here
    //rand int unsigned    stop_after_n_insts;

    // END: EDITABLE SECTION

    `uvm_object_utils_begin(rm_temp_cfg)
    // BEGIN: EDITABLE SECTION
    //`uvm_field_int(stop_after_n_insts, UVM_ALL_ON)
    // END: EDITABLE SECTION        
    `uvm_object_utils_end

    function new(string name="rm_temp_cfg");
        super.new(name);
        this.randomize(); 
        // BEGIN: EDITABLE SECTION

        // END: EDITABLE SECTION
    endfunction
endclass

`endif
