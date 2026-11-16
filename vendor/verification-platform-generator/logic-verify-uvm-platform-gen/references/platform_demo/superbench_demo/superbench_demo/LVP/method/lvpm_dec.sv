// ---------------------------------------------------------------------
//                  Logic Verification Latest
//                  =================================
// File			    : lvpm_dec.sv
// Author		    : WangAoXiang w00574459
// Email            :   
// Created TIME		: Sept 25 2024
// VERSION          : 1.0
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef LVPM_DEC__SV
`define LVPM_DEC__SV

package lvpm_dec;
    typedef enum int { NORMAL=0, NORMAL_WITH_MONITOR=1, DRIVER=2, DRIVER_WITH_MONITOR=3, RECEIVER=4,MONITOR=5} if_vip_work_mode;
    typedef enum int { IN_ORDER=0, WITH_LOSSES=1, OUT_OF_ORDER=2} sb_vip_comp_mode;
    typedef enum int { NON_LATENCY=0, LATENCY=1} sb_vip_latency_mode;
    typedef enum int { DEC=0, BIN=1, HEX=2} data_type_enum;
    typedef enum bit [15:0] {CRC16_CCITT = 16'h1021, CRC16_DEFAULT = 16'h8005, CRC16_SPB67 = 16'h941F} crc16_e;
    typedef enum bit [31:0] {CRC32_DEFAULT = 32'h04C11DB7} crc32_e;
    typedef enum bit [11:0] {CRC12_DEFAULT = 12'h80F} crc12_e; 
    //this type used to indicate the prbs type
	typedef enum {
		PRBS15 = 0,
		PRBS20 = 1,
		PRBS23 = 2,
		PRBS31 = 3
	} prbs_type_e;
endpackage: lvpm_dec

`endif
import lvpm_dec::*;

