// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : randcrange.sv
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

`ifndef RANDCRANGE__SV
`define RANDCRANGE__SV

class randcrange ;

    randc int unsigned value ;
    int max_value           ;

    function new(int max_value);
        this.max_value =max_value;
    endfunction:new

    constraint c_max_value {value < max_value;};

endclass:randcrange

`endif
