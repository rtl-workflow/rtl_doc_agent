// ***********************************************************************
//
// Copyright(c) 2014, Huawei Technologies Co., Ltd, All right reserved
//
// Project Name : 
// Filename     : cpu_adapter.sv
// Author       : z00229218
// Date         : 20141103
// Version      : 1.00
// Company      : Huawei Technologies Co., Ltd
//
// Description  : CBUS Interface to FIC DUT
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2014/11/03 z00229218 1.00 Create for IT
//
// ***********************************************************************
// Module 		: cpu_adapter
// Called by 	: 
// ***********************************************************************
// $Log: cpu_adapter.sv,v $
// Revision 1.1  2014/11/03 11:52:43 z00229218 
// initial cpu_transaction <<===>> uvm_reg_bus_op
//
// ***********************************************************************
`ifndef CPU_ADAPTER_SV
`define CPU_ADAPTER_SV

class cpu_adapter extends uvm_reg_adapter;
    `uvm_object_utils(cpu_adapter);

    extern function new(string name = "cpu_adapter");
    extern virtual  function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    extern virtual  function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
endclass:cpu_adapter

function cpu_adapter::new(string name = "cpu_adapter");
    super.new(name);
endfunction:new

//uvm_reg_bus_op -> uvm_sequence_item
function uvm_sequence_item cpu_adapter::reg2bus(const ref uvm_reg_bus_op rw);
    cpu_transaction tr  ;
    tr = new("cpu_transaction");
    
    case(rw.kind)
        UVM_READ :tr.cpu_op = cpu_transaction::READ;
        UVM_WRITE:tr.cpu_op = cpu_transaction::WRITE;
        default:begin
            `uvm_fatal("reg2bus","uvm_reg_bus_op.kind is unknown!");
        end
    endcase

    tr.addr = rw.addr;
    if(tr.cpu_op == cpu_transaction::WRITE)begin
        tr.wr_data = rw.data;
    end
    return tr;
endfunction:reg2bus

//uvm_sequence_item -> uvm_reg_bus_op
function void cpu_adapter::bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
    cpu_transaction tr;
    if(!$cast(tr,bus_item))begin
        `uvm_fatal("bus2reg","bus_item is not of the correct type!");
        return;
    end

    case(tr.cpu_op)
        cpu_transaction::READ :rw.kind = UVM_READ ;
        cpu_transaction::WRITE:rw.kind = UVM_WRITE;
        default:begin             
            `uvm_fatal("bus2reg","Receive unknown cpu_transaction.cpu_op");
        end
    endcase

    rw.addr    = tr.addr;
    rw.data    = (tr.cpu_op == cpu_transaction::READ) ? tr.rd_data : tr.wr_data;
    rw.byte_en = 'h2;
    rw.status  = UVM_IS_OK;
endfunction:bus2reg

`endif
