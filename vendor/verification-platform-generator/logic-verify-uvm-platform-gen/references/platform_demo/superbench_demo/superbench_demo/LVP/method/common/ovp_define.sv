// ---------------------------------------------------------------------
//                 OTN  Verification Project
//======================================================================
// File			:	ovp_define.sv
// Author		:	yangxiaofei 254860  
// Email        :   flyer.yang@huawei.com
// Created		:	Thu Oct 26 19:17:21 2017
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef OVP_DEFINE__SV
`define OVP_DEFINE__SV

`define E1_NOCRC_BITS 512
`define E1_CRC_BITS   4096
`define T1_SF_BITS    2316
`define T1_ESF_BITS   4632

`define C12_MAX_BITS  1032

`define MAX_PTR_VAL_TU12 139
`define MAX_PTR_VAL_TU3  764
`define MAX_PTR_VAL_STM1 782

`ifdef VCS
   `define ovp_str_match(str, regex) str.match(regex)
   `define ovp_str_prematch(str)     str.prematch()
   `define ovp_str_postmatch(str)    str.postmatch()
   `define ovp_str_backref(str, n)   str.backref(n)
`else
   `define ovp_str_match(str, regex) 0
   `define ovp_str_prematch(str)     `"`"
   `define ovp_str_postmatch(str)    `"`"
   `define ovp_str_backref(str, n)   `"`"
`endif

`define ovp_path2str(path) `"path`"

`define ovp_fatal(  str, id=get_type_name())  do `uvm_fatal(id, str)            while(0)
`define ovp_error(  str, id=get_type_name())  do `uvm_error(id, str)            while(0)
`define ovp_warning(str, id=get_type_name())  do `uvm_warning(id, str)          while(0)
`define ovp_note(   str, id=get_type_name())  do `uvm_info(id, str, UVM_NONE)   while(0)
`define ovp_play(   str, id=get_type_name())  do `uvm_info(id, str, UVM_LOW)    while(0)
`define ovp_trace(  str, id=get_type_name())  do `uvm_info(id, str, UVM_MEDIUM) while(0)
`define ovp_debug(  str, id=get_type_name())  do `uvm_info(id, str, UVM_HIGH)   while(0)
`define ovp_verbose(str, id=get_type_name())  do `uvm_info(id, str, UVM_FULL)   while(0)
`define ovp_report( str, id=get_type_name())  do `uvm_info(id, str, UVM_DEBUG)  while(0)

`define ovp_compare(a,b,radix,prefix="") do \
    if(a != b) `ovp_error($psprintf(`"%s a(%s) != b(%s)`", prefix, \
                          project_func::ovp_vector_to_string(a,radix), \
                          project_func::ovp_vector_to_string(b,radix))); \
while(0)

`define ovp_compare_int(a,b,prefix="") `ovp_compare(a,b,UVM_DEC,prefix)
`define ovp_compare_dec(a,b,prefix="") `ovp_compare(a,b,UVM_DEC,prefix)
`define ovp_compare_hex(a,b,prefix="") `ovp_compare(a,b,UVM_HEX,prefix)
`define ovp_do_compare(a,radix=UVM_DEC) do_compare &= comparer.compare_field(`"a`",this.a,vr_rhs.a,$bits(this.a),radix);
`define ovp_do_compare_queue(q,radix=UVM_HEX) \
    foreach(this.q[i]) do_compare &= comparer.compare_field($psprintf(`"q[%0d]`",i),this.q[i],vr_rhs.q[i],$bits(this.q[i]),radix);

`define ovp_cast(a,b) begin \
    if(!$cast(a, b)) `ovp_fatal($psprintf("The type of %s is not %s or its extensions!",$typename(b),$typename(a))); \
end

// Shorthand macro used in this file to flag X/Z values on a bus as errors
`define OVP_MONITOR_FLAGXZ(SIG,VAR,SZ) \
if(^(VAR) === 1'bx) begin \
    `uvm_error(get_type_name(),$psprintf("my_main():Observed x/z value on SIG (%0d'h%0x)",(SZ),(VAR))); \
end

//macro used in the file to check the correctness of signals
`ifndef OVP_ASSERT
    `define OVP_ASSERT(assert_name,prop_name,tID,message) \
    `ifdef ASSERT_ON \
        ASSERT_``assert_name: assert property (prop_name) \
        else begin  \
            `uvm_error(tID, message); \
            `ifdef ASSERTOFF_EN \
                $assertoff(0,ASSERT_``assert_name);\
            `endif\
        end \
    `endif 
`endif

//macro used in the file to cover some signals
`ifndef OVP_COVER
    `define OVP_COVER(cover_name,prop) \
    `ifdef COVER_ON \
    COVER_``cover_name: cover property(prop) \
        `ifdef ASSERTOFF_EN \
            $assertoff(0,COVER_``cover_name); \
        `else \
            ; \
        `endif \
    `endif 
`endif


`endif


