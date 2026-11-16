//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:33
//Abstract        : gen_temp_sequence
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 11:41:33, by c00800326)
//  ... version info ... 
//v1.0 new
//##################################################################
`ifndef _gen_temp_SEQUENCE_
`define _gen_temp_SEQUENCE_

`define gen_temp_sequence(tc) tc``_gen_temp_sequence

class gen_temp_sequence #(   // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE = uvm_sequence_item  // GAEA_PLATFORM::PARAMETER
) extends uvm_sequence;                   // GAEA_PLATFORM::TYPE
    bit                           print_en;
    gen_temp_cfg     cfg;

    int unsigned    		  obj_cnt;
    int unsigned    		  item_cnt;
    DATA_TYPE       		  m_trans;

    extern function new(string name = "gen_temp_sequence");
    extern virtual  task pre_body();
    extern virtual  task post_body();
    extern virtual  task body();  

    `uvm_object_param_utils(gen_temp_sequence#(.DATA_TYPE(DATA_TYPE)))
    //if you want to use some args in sqr, must declare this
    `uvm_declare_p_sequencer(uvm_sequencer);
endclass

function gen_temp_sequence::new(string name = "gen_temp_sequence");
     super.new(name);
     print_en   = 0;
     obj_cnt    = 0;
     item_cnt   = 1;
endfunction:new

task gen_temp_sequence::pre_body();
    `ifdef UVM_1P2
    uvm_phase phase = get_starting_phase();
    if(get_starting_phase() == null)
        `uvm_fatal(get_type_name(),"staring_phase is null!");
    phase.raise_objection(this);        
    `else
    if(starting_phase == null)
        `uvm_fatal(get_type_name(),"staring_phase is null!");
    starting_phase.raise_objection(this);        
    `endif
endtask:pre_body

task gen_temp_sequence::post_body();
    `ifdef UVM_1P2
    uvm_phase phase = get_starting_phase();
    `uvm_info(get_type_name(),"stimulus finish!",UVM_MEDIUM);
    phase.drop_objection(this);
    `else
    `uvm_info(get_type_name(),"stimulus finish!",UVM_MEDIUM);
    starting_phase.drop_objection(this);
    `endif
endtask:post_body

task gen_temp_sequence::body();
    repeat(this.item_cnt) begin
        `uvm_do_with(m_trans,{
        //m_trans.id == obj_cnt;
        //m_trans.stream_id == cfg.stream_id;
        //m_trans.scenario_id == cfg.scenario_id;
        });
        m_trans.set_sequence_id(obj_cnt);
        this.obj_cnt ++;
        `uvm_info(get_type_name(), $psprintf("generate a packet(%0d)\n%0s",m_trans.get_sequence_id(),m_trans.sprint()), UVM_MEDIUM);
        //`uvm_send(m_trans);
    end
endtask:body

`endif

