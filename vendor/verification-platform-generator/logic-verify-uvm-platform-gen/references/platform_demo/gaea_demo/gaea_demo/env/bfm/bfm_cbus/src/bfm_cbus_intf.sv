//*********************************************************************
//
// Copyright(c) 2009-2010, Huawei Technologies Co, Ltd
// All rights reserved.
//
// Author       :  liudingjie/00127937
// Email        :  liudingjie@huawei.com
//
//---------------------------------------------------------------------
//
// File Name    :  cbus_if.sv
// Abstract     :
//
//----------------------Modification history---------------------------
//Date        By               Rev.    Prj.         Change Description
//---------------------------------------------------------------------
//2010-04-01  liudingjie       1.00    TD232/TD234  create
//2010-04-13  shenyue/00159590 1.01   TD232/TD234  pramerterized address and data bus
//
//*********************************************************************

`timescale 1ns/1ps

interface bfm_cbus_intf #(  // GAEA_PLATFORM::CLASSNAME
 int    AWIDTH = 22,    // GAEA_PLATFORM::PARAMETER
 int    DWIDTH = 16) ( // GAEA_PLATFORM::PARAMETER
input logic cbus_clk); // GAEA_PLATFORM::CLK
//interface CPU_IF #(AWIDTH = 22,DWIDTH = 32) ();
    bit                cbus_req    ;
    bit                cbus_rw     ;
    bit  [AWIDTH-1:0]  cbus_addr   ;
    bit  [DWIDTH-1:0]  cbus_rdata  ;
    bit  [DWIDTH-1:0]  cbus_wdata  ;
    bit                cbus_ack    ;

    //initial
    //begin
    //    cbus_req   = 1'b0;
    //    cbus_rw    = 1'b1;
    //    cbus_addr  = 1'b0;
    //    cbus_wdata = 1'b0;
    //end

endinterface
