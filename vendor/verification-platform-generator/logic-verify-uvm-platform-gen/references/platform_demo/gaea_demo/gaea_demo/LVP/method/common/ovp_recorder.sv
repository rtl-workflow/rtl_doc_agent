// ---------------------------------------------------------------------
//                  OTN  Verification Project
//                  =================================
// File			:	ovp_recorder.sv
// Author		:	jiangyuanyuan 60611
// Email		:	jiangyy@hisilicon.com
// Created		:	Mon Jun  8 19:08:02 CST 2009
// Copyright (c)2008 by Huawei
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef OVP_RECORDER__SV
`define OVP_RECORDER__SV

class record_data;
    typedef enum {ADD, SET, GET, CHECK, CLEAR, START, STOP} act_e;
    act_e   act;
    int     data_id;
    int     value;
    time    t;
endclass: record_data

class ovp_recorder extends uvm_object;
    string              name;
    string              domain;

    bit                 report_en;
    int                 data_id;

    int                 value;
    record_data         record_q[$];
    
    `uvm_object_utils(ovp_recorder)

    //extern function new(string      vr_name = "",
    //                    string      vr_domain = "",
    //                    int         vr_value = 0,
    //                    bit         vr_report_en = 0);

    extern function                new(name ="ovp_recorder",string domain = "");
    extern virtual function void   display(string vr_prefix = "");
    extern virtual function string psdisplay(string vr_prefix = "");

    extern virtual function void add(input int vr_num = 0,
                                     input int vr_data_id = 0);
    extern virtual function void set(input int vr_num = 0,
                                     input int vr_data_id = 0);
    extern virtual function int get(input int vr_data_id = 0);

    extern virtual function bit check(input int vr_num = 0,
                                      input int vr_data_id = 0);
    
    extern virtual function void clear(input int vr_data_id = 0);
    //extern virtual function void start(input int vr_data_id = 0);
    //extern virtual function void stop(input int vr_data_id = 0);
    extern virtual function void record(record_data::act_e   vr_kind);

    extern virtual function void report(input int vr_from_id = 0,
                                        input int vr_to_id = 0);

endclass: ovp_recorder

//function ovp_recorder::new(string    vr_name,
//                       string    vr_domain,
//                       int       vr_value,
//                       bit       vr_report_en);
//
//    this.name      = vr_name;
//    this.domain    = vr_domain;
//    this.value     = vr_value;
//    this.report_en = vr_report_en;
//endfunction: new

function ovp_recorder::new(name ="ovp_recorder",string domain = "");
    super.new(name);
    //this.name    = name;
    this.domain  = domain;
endfunction: new

function void ovp_recorder::display(string vr_prefix);
    $display(this.psdisplay(vr_prefix));
endfunction: display

function string ovp_recorder::psdisplay(string vr_prefix);

    $sformat(psdisplay,"%s    %s ovp_recorder   %s = %5d,   report = %0d",
                       vr_prefix,domain,name,value,report_en);

endfunction: psdisplay

function void ovp_recorder::add(input int vr_num,
                            input int vr_data_id);
    value += vr_num;
    data_id = vr_data_id;
    record(record_data::ADD);
    return;
endfunction: add

function void ovp_recorder::set(input int vr_num,
                            input int vr_data_id);
    value = vr_num;
    data_id = vr_data_id;
    record(record_data::SET);
    return;
endfunction: set

function int ovp_recorder::get(input int vr_data_id);
    $write("    %s ovp_recorder    %s = %0d\n",domain,name,value);
    get = value;
    data_id = vr_data_id;
    record(record_data::GET);
    return get;
endfunction: get

function void ovp_recorder::clear(input int vr_data_id);
    //$write("    %s ovp_recorder    %s = %0d, set it value = 0\n",domain,name,value);
    value = 0;
    data_id = vr_data_id;
    record(record_data::CLEAR);
    return;
endfunction: clear

function bit ovp_recorder::check(input int vr_num,
                             input int vr_data_id);
    //$write("    %s ovp_recorder    %s = %0d, set it value = 0\n",domain,name,value);
    check = 0;
    if (value != vr_num) begin
        check = 1;
        $write("    %s ovp_recorder    %s = %0d is not equal to check value: %0d\n",domain,name,value,vr_num);
    end
    data_id = vr_data_id;
    record(record_data::CHECK);
    return check;
endfunction: check


function void ovp_recorder::record(record_data::act_e  vr_kind);
    record_data   vr_record;
    vr_record = new;

    vr_record.data_id = data_id;
    vr_record.act = vr_kind;
    vr_record.value = value;
    vr_record.t = $time;

    record_q.push_back(vr_record);

endfunction: record

function void ovp_recorder::report(input int vr_from_id,
                               input int vr_to_id);
    int     i;
    string  vr_str;
    string  vr_tmp;

    if (vr_to_id == 0) begin
        vr_to_id = record_q.size - 1;
    end
    $sformat(vr_str, "data_id     act      value     time\n");

    for (i=vr_from_id; i<=vr_to_id; i++) begin
        if (i>record_q.size) break;
        vr_tmp = record_q[i].act.name;
        $sformat(vr_str, "%s %5d     ", vr_str, record_q[i].data_id);
        $sformat(vr_str, "%s %s", vr_str, record_q[i].act.name);
        repeat (8 - vr_tmp.len) $sformat(vr_str,"%s ", vr_str);
        $sformat(vr_str, "%s %4d      ", vr_str, record_q[i].value);
        $sformat(vr_str, "%s %t\n", vr_str, record_q[i].t);
    end

    //`uvm_info(get_type_name(), $psprintf("%s", vr_str),UVM_NONE);

endfunction: report


`endif

// ---------------------------------------------------------------------
// Modification History
// $Log: ovp_recorder.sv,v $
// Revision 1.1  2010/08/18 01:27:39  l54766
// no message
//
// Revision 1.3  2009/07/15 00:31:56  j60611
// no message
//
// Revision 1.2  2009/06/24 07:55:07  j60611
// no message
//
// Revision 1.1  2009/06/16 07:59:04  j60611
// no message
//
// 
// ---------------------------------------------------------------------

