//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:33
//Abstract        : gen_temp_sqr_to_func
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 11:41:33, by c00800326)
//  ... version info ... 
//v1.0 new
//##################################################################
`ifndef _gen_temp_SQR_TO_FUNC_SV_
`define _gen_temp_SQR_TO_FUNC_SV_

class gen_temp_sqr_to_func extends uvm_component;
    uvm_seq_item_pull_port #(uvm_sequence_item) seq_item_port;
    uvm_blocking_put_port  #(uvm_sequence_item) out_port;
    uvm_sequence_item                           req;

    extern function new(string name = "gen_temp_sqr_to_func",uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);

    `uvm_component_utils(gen_temp_sqr_to_func);
endclass:gen_temp_sqr_to_func

function gen_temp_sqr_to_func::new(string name = "gen_temp_sqr_to_func",uvm_component parent = null);
    super.new(name,parent);
    seq_item_port = new("seq_item_port",this);
    out_port      = new("out_port",this);
endfunction:new

function void gen_temp_sqr_to_func::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction:build_phase

task gen_temp_sqr_to_func::run_phase(uvm_phase phase);
    forever begin
        `uvm_info(get_type_name(),"con_func begin get pkt",UVM_MEDIUM)
        seq_item_port.get_next_item(req);
        out_port.put(req);
        seq_item_port.item_done();
        `uvm_info(get_type_name(),"con_func end get pkt",UVM_MEDIUM)
    end
    `uvm_info(get_type_name(), "gen_temp_sqr_to_func run_phase end!!",UVM_MEDIUM);
endtask:run_phase
`endif
