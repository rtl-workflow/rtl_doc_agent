// ---------------------------------------------------------------------
//                 OTN  Verification Project
//======================================================================
// File			:	ovp_port_alyport.sv
// Author		:	xiexianchuan  00180017  
// Email        :   xiexianchuan@huawei.com
// Created		:	Tue Sep 19 09:34:23 2017
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
// ---------------------------------------------------------------------
// Description	:
//  get_port data change to analysis_port, adapter comps to scorboard.
// ---------------------------------------------------------------------
//function hierarchy:
//  run_phase-> |receive_item
//
//****************************************************************************

`ifndef OVP_PORT_ALYPORT__SV
`define OVP_PORT_ALYPORT__SV

class ovp_port_alyport#(type item=uvm_sequence_item)  extends uvm_monitor;

`uvm_component_param_utils(ovp_port_alyport#(item))

uvm_get_port #(uvm_sequence_item)          in_port;
uvm_analysis_port #(uvm_sequence_item)     sb_port;

extern function new(string        name="ovp_port_alyport",
                    uvm_component parent
                    );

extern virtual function void build_phase(uvm_phase phase);
extern virtual task          run_phase(uvm_phase phase);

extern virtual task          receive_item();

endclass:ovp_port_alyport

function ovp_port_alyport::new(string        name,
                               uvm_component  parent
                               );

    super.new(name, parent);

endfunction: new

function void ovp_port_alyport::build_phase(uvm_phase phase);

    super.build_phase(phase);
    `uvm_info(get_type_name(),"build_phase(): ovp_port_alyport build_phase is running", UVM_MEDIUM);
    
    this.sb_port = new("sb_port",this);
    this.in_port = new("in_port",this);

endfunction:build_phase

task ovp_port_alyport::run_phase(uvm_phase phase);

    super.run_phase(phase);

    `uvm_info(get_type_name(), "run_phase(): send_pkt  run_phase is running", UVM_LOW);
    receive_item();
    
endtask: run_phase

task ovp_port_alyport::receive_item();
    
    uvm_sequence_item   in_item;
    item                sb_item;
    int                 item_count=0;

    while(1) begin
        uvm_wait_for_nba_region(); 
        this.in_port.get(in_item);
        
        sb_item = new();
        if(!$cast(sb_item,in_item)) begin
            `uvm_fatal(get_type_name(),"ovp_port_alyport():in_item is not a expect type or its extension");
        end
        #2ns;  //NOTE: add only for subenv self-test without agent!!
        this.sb_port.write(sb_item);

        item_count ++;
        `uvm_info(get_type_name(),$psprintf("ovp_port_alyport(): send NO.%0d item to scorborad",item_count), UVM_LOW);
   end

endtask:receive_item

`endif
