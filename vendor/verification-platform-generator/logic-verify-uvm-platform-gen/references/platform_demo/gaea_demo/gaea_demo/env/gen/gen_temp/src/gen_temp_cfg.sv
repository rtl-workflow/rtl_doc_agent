//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:33
//Abstract        : gen_temp_cfg
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 11:41:33, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _gen_temp_CFG_CLASS_
`define _gen_temp_CFG_CLASS_

`define gen_temp_cfg(tc) tc``_gen_temp_cfg

class gen_temp_cfg    // GAEA_PLATFORM::CLASSNAME
extends uvm_object;                // GAEA_PLATFORM::TYPE
    // BEGIN: EDITABLE SECTION
    // Declare your variables here
    //rand int unsigned    stop_after_n_insts;

    // END: EDITABLE SECTION

    `uvm_object_utils_begin(gen_temp_cfg)
    // BEGIN: EDITABLE SECTION
    //`uvm_field_int(stop_after_n_insts, UVM_ALL_ON)
    // END: EDITABLE SECTION        
    `uvm_object_utils_end

    function new(string name="gen_temp_cfg");
        super.new(name);
        this.randomize(); 
    	// BEGIN: EDITABLE SECTION

    	// END: EDITABLE SECTION
    endfunction
endclass

`endif
