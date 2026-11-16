// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : reg_test_dec.sv
// Author         : zengwenhua/z00472263
// Date           : 2020/06/11
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2020/06/11 zengwenhua  1.00 Create
// 
// ***********************************************************************
// DEFINE 
// ***********************************************************************
// Module 		: 
// Called by 	: 
// ***********************************************************************
// $Log: 
// 
// ***********************************************************************

`ifndef REG_TEST_DEC__SV
`define REG_TEST_DEC__SV

package reg_test_dec ;
    typedef enum {
        ACCESS_ORDER = 0,
        ACCESS_REVER = 1,
        ACCESS_RAND  = 2
    } access_order_e;

    typedef enum{
        W_DEFAULT = 0,
        W_RANDOM  = 1,
        W_REVER   = 2
    } wdata_type_e;

endpackage:reg_test_dec
import reg_test_dec::*;

`endif
