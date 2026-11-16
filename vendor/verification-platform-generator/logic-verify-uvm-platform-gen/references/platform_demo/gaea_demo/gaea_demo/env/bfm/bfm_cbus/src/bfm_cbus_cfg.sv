// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : bfm_cbus_cfg.sv
// Author         : lidongbo/l00381975
// Date           : 2019/03/19
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2019/03/19 lidongbo  1.00 Create
// 
// ***********************************************************************
// DEFINE 
// ***********************************************************************
// Module 		: 
// Called by 	: 
// ***********************************************************************
// $Log: 
// 
// ***********************************************************************
`ifndef _bfm_cbus_cfg_CLASS_
`define _bfm_cbus_cfg_CLASS_

class bfm_cbus_cfg   // GAEA_PLATFORM::CLASSNAME
extends uvm_object;      // GAEA_PLATFORM::TYPE
    // BEGIN: EDITABLE SECTION
    // Declare your variables here
        //rand int unsigned    stop_after_n_insts;

    // END: EDITABLE SECTION
    rand glb_dec::if_vip_work_mode work_mode;

    `uvm_object_utils_begin(bfm_cbus_cfg)    // BEGIN: EDITABLE SECTION
        //`uvm_field_int(stop_after_n_insts, UVM_ALL_ON)

    // END: EDITABLE SECTION        
        `uvm_field_enum(glb_dec::if_vip_work_mode,work_mode,UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="bfm_cbus_cfg");
        super.new(name);
        this.randomize(); 
        // BEGIN: EDITABLE SECTION
        work_mode = glb_dec::NORMAL;

        // END: EDITABLE SECTION
    endfunction
endclass

`endif
