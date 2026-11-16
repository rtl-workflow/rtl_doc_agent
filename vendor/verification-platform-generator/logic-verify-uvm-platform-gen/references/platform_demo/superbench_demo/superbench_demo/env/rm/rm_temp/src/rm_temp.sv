//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 16:09:15
//Abstract        : rm_temp
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 16:09:15, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _rm_temp_CLASS_
`define _rm_temp_CLASS_

class rm_temp #(                // GAEA_PLATFORM::CLASSNAME
    type IN_DATA_TYPE  = uvm_sequence_item, // GAEA_PLATFORM::PARAMETER
    type OUT_DATA_TYPE = uvm_sequence_item  // GAEA_PLATFORM::PARAMETER
    ) extends uvm_component;                  // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_put_port  outport;  // GAEA_PLATFORM::OUTPORT 
	base_put_port  outport1;  // GAEA_PLATFORM::OUTPORT
    base_peek_port  inport;  // GAEA_PLATFORM::INPORT 
    //!GAEA_BLOCK_END_CHANNELDECL

    rm_temp_cfg         cfg;    // NOTICE:configure instance is cfg

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual task run_phase(uvm_phase phase);

    `uvm_component_param_utils(rm_temp #(.IN_DATA_TYPE(IN_DATA_TYPE),.OUT_DATA_TYPE(OUT_DATA_TYPE)))

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here

    // END: EDITABLE SECTION
endclass:rm_temp

function rm_temp::new (string name, uvm_component parent);
    super.new(name, parent);

    //!GAEA_BLOCK_BEGIN_CHANNELINST
    outport = new("outport",this); 
	outport1 = new("outport1",this);
    inport = new("inport",this); 
    //!GAEA_BLOCK_END_CHANNELINST


    // BEGIN: EDITABLE SECTION

    // END: EDITABLE SECTION
endfunction:new

function void rm_temp::build_phase(uvm_phase phase) ;

    // BEGIN: EDITABLE SECTION

    // END: EDITABLE SECTION

endfunction

task rm_temp::run_phase(uvm_phase phase) ;
    IN_DATA_TYPE   pkt_in	;
    OUT_DATA_TYPE  pkt_out	;
    uvm_sequence_item req	; 
    super.run_phase(phase);

    //forever begin
    //// BEGIN: EDITABLE SECTION
    //// Write your codes here
    //	pkt_in  = new();
    //	pkt_out = new();
    //    inport.get(req);
    //    if(!$cast(pkt_in,req.clone()))
    //        `uvm_fatal(get_type_name(),"the data cast is failed,please check");
	//// func process by user adding;
	//    pkt_out.set_sequence_id(pkt_in.get_sequence_id());
    //    //  -----------
    //    outport.put(pkt_out);
    //// END: EDITABLE SECTION
    //end
endtask:run_phase

`endif
