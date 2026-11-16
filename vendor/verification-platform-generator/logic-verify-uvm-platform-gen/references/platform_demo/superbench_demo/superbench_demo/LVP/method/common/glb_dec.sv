//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2017-06-19 17:08
//Abstract        :  glb_dec
//Description   :   this class is the basic logic verification property of global declaration
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2017-06-19 17:08 ,)
//  ... version info ...
//v1.0 new
//##################################################################

`ifndef GLOBALS_SV
`define GLOBALS_SV
package glb_dec;
    typedef enum int { NORMAL=0, NORMAL_WITH_MONITOR=1, DRIVER=2, DRIVER_WITH_MONITOR=3, RECEIVER=4, MONITOR=5} if_vip_work_mode;
    typedef enum int { IN_ORDER=0, WITH_LOSSES=1, OUT_OF_ORDER=2} sb_vip_comp_mode;
    typedef enum int { NON_LATENCY=0, LATENCY=1} sb_vip_latency_mode;
endpackage:glb_dec
typedef uvm_get_peek_port#(uvm_sequence_item)     base_peek_port;
typedef uvm_blocking_put_port#(uvm_sequence_item) base_put_port;
typedef uvm_tlm_fifo#(uvm_sequence_item)          base_tlm_fifo;
typedef uvm_analysis_port#(uvm_sequence_item)     base_analysis_port;
typedef uvm_tlm_analysis_fifo#(uvm_sequence_item) base_tlm_analysis_fifo;
`endif
