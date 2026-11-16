//*********************************************************************
//
//                  OTN Verification Project
//                  ==============================
// File	        :   com_method.sv
// Author		:   FanJianJun <fanjianjun@huawei.com>
// Created		:	Thu Oct 12 10:34:45 2017
//
// Copyright (c)2017 by Hisilicon
//
//---------------------------------------------------------------------
// Description	:
//
//
//---------------------------------------------------------------------
// Function hierarchy:
//
//
//
//
//*********************************************************************

`ifndef COM_METHOD__SV
`define COM_METHOD__SV

class com_method #(int LENGTH = 16);

// **************************************************************************
// function(task)   :   cvt_mbit_to_byte
// purpose          :   Function for calculate m-bit array to bytes array
// author           :   fanjianjun 191340
// **************************************************************************
extern static function void cvt_mbit_to_byte(bit [LENGTH -1:0]     vr_mbit_in[],
                                         ref bit                   vr_bit_remain[$],
                                         ref bit [7:0]             vr_byte_out[],
                                       input bit                   vr_mbit_order = 0,
                                       input bit                   vr_byte_order = 1);

// **************************************************************************
// function(task)   :   cvt_byte_to_mbit
// purpose          :   Function for calculate byte array to m-bit array
// author           :   fanjianjun 191340
// **************************************************************************
extern static function void cvt_byte_to_mbit(bit [7:0]             vr_byte_in[],
                                         ref bit                   vr_bit_remain[$],
                                         ref bit [LENGTH -1:0]     vr_mbit_out[],
                                       input bit                   vr_byte_order = 1,
                                       input bit                   vr_mbit_order = 0);


// **************************************************************************
// function(task)   :   bit order adjust
// purpose          :   Function for change mbit data's bit&byte order
// author           :   fanjianjun 191340
// **************************************************************************
extern static function void data_order_adjust(ref   bit [LENGTH -1:0]  vr_data,
                                              input bit                vr_byte_order = 0,
                                              input bit                vr_bit_order  = 0);


endclass

function void com_method::cvt_mbit_to_byte(bit [LENGTH -1:0]     vr_mbit_in[],
                                       ref bit                   vr_bit_remain[$],
                                       ref bit [7:0]             vr_byte_out[],
                                     input bit                   vr_mbit_order = 0, /* 0=lsb first; 1=msb first*/
                                     input bit                   vr_byte_order = 1);/* 0=lsb first; 1=msb first*/

    int tmp_byte_size;

    for(int i=0;i<vr_mbit_in.size;i++) begin
        for(int j=0;j<LENGTH;j++) begin
            if(vr_mbit_order == 0)begin
                vr_bit_remain.push_back(vr_mbit_in[i][j]);
            end
            else begin
                vr_bit_remain.push_back(vr_mbit_in[i][LENGTH - 1 - j]);
            end   
        end
    end

    tmp_byte_size = vr_bit_remain.size/8;
    vr_byte_out   = new[tmp_byte_size];
    for(int i=0;i<tmp_byte_size;i++) begin
        for(int j=0;j<8;j++) begin
            if(vr_byte_order == 0)begin
                vr_byte_out[i][j] = vr_bit_remain.pop_front();
            end 
            else begin
                vr_byte_out[i][7 - j] = vr_bit_remain.pop_front();
            end   
        end
    end

endfunction:cvt_mbit_to_byte


function void com_method::cvt_byte_to_mbit(bit [7:0]             vr_byte_in[],
                                       ref bit                   vr_bit_remain[$],
                                       ref bit [LENGTH -1:0]     vr_mbit_out[],
                                     input bit                   vr_byte_order = 1, /* 0=lsb first; 1=msb first*/
                                     input bit                   vr_mbit_order = 0);/* 0=lsb first; 1=msb first*/

    int tmp_mbit_size;

    for(int i=0;i<vr_byte_in.size;i++) begin
        for(int j=0;j<8;j++) begin
            if(vr_byte_order == 0)begin
                vr_bit_remain.push_back(vr_byte_in[i][j]);
            end
            else begin
                vr_bit_remain.push_back(vr_byte_in[i][7 - j]);
            end   
        end
    end

    tmp_mbit_size = vr_bit_remain.size/LENGTH;
    vr_mbit_out   = new[tmp_mbit_size];
    for(int i=0;i<tmp_mbit_size;i++) begin
        for(int j=0;j<LENGTH;j++) begin
            if(vr_mbit_order == 0)begin
                vr_mbit_out[i][j] = vr_bit_remain.pop_front();
            end 
            else begin
                vr_mbit_out[i][LENGTH - 1 - j] = vr_bit_remain.pop_front();
            end   
        end
    end

endfunction:cvt_byte_to_mbit

function void com_method::data_order_adjust(ref   bit [LENGTH -1:0]  vr_data,
                                            input bit                vr_byte_order = 0,
                                            input bit                vr_bit_order  = 0);

    bit [LENGTH - 1:0]    tmp_data;
    int                   tmp_byte_size;
    int                   tmp_bit_size;

    tmp_byte_size = LENGTH/8;
    tmp_bit_size  = LENGTH%8;

    if(vr_bit_order)begin
        for(int i=0;i<tmp_byte_size;i++) begin
            for(int j=0;j<8;j++) begin
                tmp_data[8*i+7-j] = vr_data[8*i+j];
            end
        end
        if(tmp_bit_size)begin
            for(int j=0;j<tmp_bit_size;j++) begin
                tmp_data[LENGTH - 1 - j] = vr_data[8*tmp_byte_size + j];
            end
        end 
        vr_data = tmp_data;
    end 

    if(vr_byte_order)begin
        for(int i=0;i<LENGTH;i++) begin
            tmp_data[LENGTH - 1 - i] = vr_data[i];
        end
        vr_data = tmp_data;
        for(int i=0;i<tmp_byte_size;i++) begin
            for(int j=0;j<8;j++) begin
                tmp_data[8*i+7-j] = vr_data[8*i+j];
            end
        end
        if(tmp_bit_size)begin
            for(int j=0;j<tmp_bit_size;j++) begin
                tmp_data[LENGTH - 1 - j] = vr_data[8*tmp_byte_size + j];
            end
        end 
        vr_data = tmp_data;
    end 
    
endfunction:data_order_adjust

`endif


