//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          :
//Initial-Date    :
//Abstract        : rm_broadcast_for_gen
//##################################################################

`ifndef rm_broadcast_for_gen_SV
`define rm_broadcast_for_gen_SV

class rm_broadcast_for_gen #(                // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE  = uvm_sequence_item
    ) extends uvm_component;                  // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_put_port  outport[];  // GAEA_PLATFORM::OUTPORT (dynamic array)
    base_peek_port  inport;  // GAEA_PLATFORM::INPORT 
    //!GAEA_BLOCK_END_CHANNELDECL

    rm_broadcast_for_gen_cfg         cfg;    // NOTICE:configure instance is cfg

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual task run_phase(uvm_phase phase);

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here
	`uvm_component_param_utils(rm_broadcast_for_gen #(.DATA_TYPE(DATA_TYPE)))
    // END: EDITABLE SECTION
endclass:rm_broadcast_for_gen

function rm_broadcast_for_gen::new (string name, uvm_component parent);
    super.new(name, parent);

    //!GAEA_BLOCK_BEGIN_CHANNELINST
    inport = new("inport",this); 
    //!GAEA_BLOCK_END_CHANNELINST


    // BEGIN: EDITABLE SECTION

    // END: EDITABLE SECTION
endfunction:new

function void rm_broadcast_for_gen::build_phase(uvm_phase phase) ;
    super.build_phase(phase);
    // BEGIN: EDITABLE SECTION
    // Dynamically create outport array based on cfg.outport_num
    outport = new[cfg.outport_num];
    foreach (outport[i]) begin
        outport[i] = new($sformatf("outport[%0d]", i), this);
    end
    // END: EDITABLE SECTION

endfunction

task rm_broadcast_for_gen::run_phase(uvm_phase phase) ;
    DATA_TYPE   pkt_in	;
    uvm_sequence_item req	; 
    super.run_phase(phase);

    forever begin
    //// BEGIN: EDITABLE SECTION
    //// Write your codes here
    	pkt_in  = new();
        inport.get(req);
        if(!$cast(pkt_in,req.clone()))
            `uvm_fatal(get_type_name(),"the data cast is failed,please check");
        //  -----------
        // 广播到所有输出端口（同一个数据对象，并行发送，互不阻塞）
        fork
            foreach (outport[i]) begin
                outport[i].put(pkt_in);
            end
        join_none
    //// END: EDITABLE SECTION
    end
endtask:run_phase

`endif
