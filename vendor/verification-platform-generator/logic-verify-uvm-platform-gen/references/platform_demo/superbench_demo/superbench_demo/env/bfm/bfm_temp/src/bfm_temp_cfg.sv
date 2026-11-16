//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:15
//Abstract        : bfm_temp_cfg
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 16:09:15, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _bfm_temp_cfg_CLASS_
`define _bfm_temp_cfg_CLASS_

class bfm_temp_cfg   // GAEA_PLATFORM::CLASSNAME
extends uvm_object;               // GAEA_PLATFORM::TYPE
    // BEGIN: EDITABLE SECTION
    // Declare your variables here
    //rand int unsigned    stop_after_n_insts;

    // END: EDITABLE SECTION

    rand glb_dec::if_vip_work_mode work_mode;

    `uvm_object_utils_begin(bfm_temp_cfg)
    	// BEGIN: EDITABLE SECTION
        //`uvm_field_int(stop_after_n_insts, UVM_ALL_ON)

    	// END: EDITABLE SECTION        
        `uvm_field_enum(glb_dec::if_vip_work_mode,work_mode,UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="bfm_temp_cfg");
        super.new(name);

        this.randomize(); 
        // BEGIN: EDITABLE SECTION
        work_mode = glb_dec::NORMAL;

        // END: EDITABLE SECTION
    endfunction
endclass

`endif
