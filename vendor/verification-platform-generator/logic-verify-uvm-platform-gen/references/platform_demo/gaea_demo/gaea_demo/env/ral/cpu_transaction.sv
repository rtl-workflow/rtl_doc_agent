// ***********************************************************************
//
// Copyright(c) 2015, Huawei Technologies Co., Ltd, All right reserved
//
// Project Name : 
// Filename     : cpu_transaction.sv
// Author       : z00229218
// Date         : 20150531
// Version      : 1.00
// Company      : Huawei Technologies Co., Ltd
//
// Description  :CPU to DUT
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2015/05/31 z00229218 1.00 Create for UT
//
// ***********************************************************************
// Module 		: cpu_transaction
// Called by 	: 
// ***********************************************************************
`ifndef CPU_TRANSACTION_SV
`define CPU_TRANSACTION_SV

class cpu_transaction extends uvm_sequence_item;
    parameter   CPU_AWIDTH = 128 ;
    parameter   CPU_DWIDTH = 128 ;
    
    typedef enum {READ,WRITE} cpu_op_e ;

    rand bit    [CPU_AWIDTH - 1:0]  addr    ;
    rand bit    [CPU_DWIDTH - 1:0]  wr_data ;
    rand bit    [CPU_DWIDTH - 1:0]  rd_data ;
    rand cpu_op_e                   cpu_op  ;

    `uvm_object_utils_begin(cpu_transaction)
        `uvm_field_int(rd_data  ,UVM_ALL_ON)
        `uvm_field_int(wr_data  ,UVM_ALL_ON)
        `uvm_field_int(addr     ,UVM_ALL_ON)
        `uvm_field_enum(cpu_op_e,cpu_op,UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cpu_transaction");
        super.new(name);
    endfunction:new
endclass:cpu_transaction

`endif

