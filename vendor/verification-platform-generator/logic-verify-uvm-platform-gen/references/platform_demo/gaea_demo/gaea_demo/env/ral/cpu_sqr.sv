// ***********************************************************************
//
// Copyright(c) 2015, Huawei Technologies Co., Ltd, All right reserved
//
// Project Name : 
// Filename     : cpu_sqr.sv
// Author       : z00229218
// Date         : 20150601
// Version      : 1.00
// Company      : Huawei Technologies Co., Ltd
//
// Description  : CPU Sequencer to DUT
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2015/06/01 z00229218 1.00 Create for UT
//
// ***********************************************************************
// Module 		: cpu_sequencer
// Called by 	: 
// ***********************************************************************
`ifndef CPU_SQR_SV
`define CPU_SQR_SV

class cpu_sqr extends uvm_sequencer #(cpu_transaction);
    `uvm_component_utils(cpu_sqr);
    
    function new(string name = "cpu_sequencer",uvm_component parent = null);
        super.new(name);
    endfunction:new
endclass:cpu_sqr

`endif
