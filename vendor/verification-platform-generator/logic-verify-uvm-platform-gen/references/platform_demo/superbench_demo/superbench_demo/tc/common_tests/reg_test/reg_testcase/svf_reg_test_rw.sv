// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : svf_reg_test_rw.sv
// Author         : zengwenhua/z00472263
// Date           : 2020/11/09
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2020/11/09 zengwenhua  1.00 Create
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

`ifndef _svf_reg_test_rw_CLASS_
`define _svf_reg_test_rw_CLASS_

`define TC svf_reg_test_rw 

class `TC extends tc_reg_test;

    `uvm_component_utils(`TC)

    extern function new(string name="`TC", uvm_component parent)                ;
    extern virtual task rw_rst_cmd()                                            ;
    extern virtual function void build_phase(uvm_phase phase)                   ;
    extern virtual function void connect_phase(uvm_phase phase)                 ;
    extern virtual task run_phase(uvm_phase phase)                              ;
endclass:`TC
//========================================================================================================
//
//========================================================================================================
function `TC::new(string name="`TC", uvm_component parent);
    super.new(name, parent);

    this.reg_test_no = 1;   //0-init 1-rw 2-property 3-data_glue 4-addr_glue 5-all_addr
endfunction:new
//========================================================================================================
//
//========================================================================================================
function void `TC::build_phase(uvm_phase phase);
    super.build_phase(phase);
    u_env.u_ol_it_env_cfg.u_bfm_otnpro_cfg.otnpro_mon_en = 0;
    u_env.u_ol_it_env_cfg.u_otnpro2tu_cfg.otnpro_mon_en = 0;
    u_env.u_ol_it_env_cfg.u_bfm_tu12_cfg.tu12_mon_en = 0;
endfunction:build_phase
//========================================================================================================
//
//========================================================================================================
function void `TC::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //`EXCLUDE_ACCESS_REG("test_reg_n")

endfunction:connect_phase
//========================================================================================================
//
//========================================================================================================
task `TC::rw_rst_cmd();
    
endtask:rw_rst_cmd
//========================================================================================================
//
//========================================================================================================
task `TC::run_phase(uvm_phase phase);
    super.run_phase(phase);
endtask:run_phase

`endif
