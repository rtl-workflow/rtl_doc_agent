//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:33
//Abstract        : gen_temp
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

`ifndef _gen_temp_CLASS_
`define _gen_temp_CLASS_

class gen_temp #(           // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE = uvm_sequence_item  // GAEA_PLATFORM::PARAMETER
    ) extends uvm_component;             // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_put_port      outport;          // GAEA_PLATFORM::OUTPORT
    //!GAEA_BLOCK_END_CHANNELDECL

    gen_temp_cfg             cfg;                          // NOTICE:configure instance is cfg
	gen_temp_sequence     #(.DATA_TYPE(DATA_TYPE)) seq; // NOTICE:sequence is needed
	uvm_sequencer         sqr;                         // NOTICE:sequencer is needed
	gen_temp_sqr_to_func  s2f;

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual function void connect_phase(uvm_phase phase);

    `uvm_component_utils(gen_temp #(.DATA_TYPE(DATA_TYPE)))

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here

    // END: EDITABLE SECTION
endclass:gen_temp

function gen_temp::new (string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "new(): gen_temp has been constructed", UVM_HIGH);
    // BEGIN: EDITABLE SECTION
    

    // END: EDITABLE SECTION
endfunction:new

function void gen_temp::build_phase(uvm_phase phase) ;
    super.build_phase(phase);
    //!GAEA_BLOCK_BEGIN_CHANNELINST
    seq = gen_temp_sequence#(.DATA_TYPE(DATA_TYPE))::type_id::create("seq",this);
	sqr = uvm_sequencer#()::type_id::create("sqr",this);
	s2f = gen_temp_sqr_to_func::type_id::create("s2f",this);
	seq.cfg = cfg;                                                 
    //!GAEA_BLOCK_END_CHANNELINST

    `uvm_info(get_type_name(), "build_phase(): gen_temp build_phase is starting", UVM_HIGH);
    `uvm_info(get_type_name(), "build_phase(): gen_temp build_phase is done", UVM_HIGH);

endfunction: build_phase

function void gen_temp::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
	s2f.seq_item_port.connect(sqr.seq_item_export);
	this.outport=s2f.out_port;
    `uvm_info(get_type_name(), "connect_phase(): gen_temp build_phase is starting", UVM_HIGH);
    `uvm_info(get_type_name(), "connect_phase(): gen_temp build_phase is done", UVM_HIGH);
endfunction:connect_phase

`endif
