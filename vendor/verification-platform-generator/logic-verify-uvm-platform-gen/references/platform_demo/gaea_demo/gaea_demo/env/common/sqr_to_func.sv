//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 17:08
//Abstract        : sqr_to_func
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 17:08 ,)
//  ... version info ... 
//v1.0 new
//##################################################################
`ifndef SQR_TO_FUNC_SV
`define SQR_TO_FUNC_SV

class sqr_to_func extends uvm_component;
    uvm_seq_item_pull_port #(uvm_sequence_item) seq_item_port;
    uvm_blocking_put_port  #(uvm_sequence_item) out_port;

    uvm_sequence_item  req;

    extern function new(string name = "sqr_to_func",uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);

    `uvm_component_utils(sqr_to_func);
endclass:sqr_to_func

function sqr_to_func::new(string name = "sqr_to_func",uvm_component parent = null);
    super.new(name,parent);
    seq_item_port = new("seq_item_port",this);
    out_port = new("out_port",this);
endfunction:new

function void sqr_to_func::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction:build_phase

task sqr_to_func::main_phase(uvm_phase phase);
    forever begin
        `uvm_info(get_type_name(),"con_func begin get pkt",UVM_MEDIUM)
        seq_item_port.get_next_item(req);
        out_port.put(req);
        seq_item_port.item_done();
        `uvm_info(get_type_name(),"con_func end get pkt",UVM_MEDIUM)
    end
    `uvm_info(get_type_name(), "sqr_to_func main_phase end!!",UVM_MEDIUM);
endtask:main_phase

`endif
