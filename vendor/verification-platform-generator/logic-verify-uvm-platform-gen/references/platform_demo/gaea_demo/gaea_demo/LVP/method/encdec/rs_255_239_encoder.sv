// ---------------------------------------------------------------------
//                  OTN  Verification Project
//======================================================================
// File			:	rs_255_239_encoder.sv
// Author		:	liutianzhu 48758
// Email       :  liutianzhu@huawei.com
// Created		:	Fri Jun 05 09:37:40 2009
// Copyright (c)2009 by Huawei.
// ---------------------------------------------------------------------
// Description	: This file implement a encoder for RS(255,239) code
//
// ---------------------------------------------------------------------
// Modification History
//  $Log: rs_255_239_encoder.sv,v $
//  Revision 1.2  2009/06/23 03:08:01  l48758
//  no message
//
//  Revision 1.1  2009/06/09 01:43:41  l48758
//  no message
//
//
// ---------------------------------------------------------------------
`ifndef RS_255_239_ENCODER__SV
`define RS_255_239_ENCODER__SV


class rs_255_239_encoder;


    // The calculator of GF(256)
    gf2n_calculator #(.GF_SIZE(8), .PRM_PL('h11d))  calculator = new;

    // encode method, do RS(255,239) encode for the input data
    // g(x)=(x+alfha^0)(x+alfha^1)...(x+alfha^15)
    // p(x)=m(x)x^16 mod g(x)
    // the ith iteration: m(x)=m(x)x+mi; p(x)=p(x)x+(mix^16 mod g(x))
    extern         function void  encode (ref bit[7:0] vr_din [] );

endclass:rs_255_239_encoder


function void  rs_255_239_encoder::encode (ref bit[7:0] vr_din [] );
    // the 16 bytes parity data for  RS(255,239) code
    bit[7:0]  vr_parity [16] ;
    // following is the coeffiecient of the encode polynomial
    bit[7:0]  vr_g0   = 'h3b;
    bit[7:0]  vr_g1   = 'h24;
    bit[7:0]  vr_g2   = 'h32;
    bit[7:0]  vr_g3   = 'h62;
    bit[7:0]  vr_g4   = 'he5;
    bit[7:0]  vr_g5   = 'h29;
    bit[7:0]  vr_g6   = 'h41;
    bit[7:0]  vr_g7   = 'ha3;
    bit[7:0]  vr_g8   = 'h08;
    bit[7:0]  vr_g9   = 'h1e;
    bit[7:0]  vr_g10  = 'hd1;
    bit[7:0]  vr_g11  = 'h44;
    bit[7:0]  vr_g12  = 'hbd;
    bit[7:0]  vr_g13  = 'h68;
    bit[7:0]  vr_g14  = 'h0d;
    bit[7:0]  vr_g15  = 'h3b;
    bit[7:0]  vr_p16  = 0;
    for (int i=0; i<239 ; i++) begin
        vr_p16 =     vr_parity[15] ^ vr_din[i];
        vr_parity[15] = vr_parity[14] ^ calculator.mul_general(vr_p16,vr_g15);
        vr_parity[14] = vr_parity[13] ^ calculator.mul_general(vr_p16,vr_g14);
        vr_parity[13] = vr_parity[12] ^ calculator.mul_general(vr_p16,vr_g13);
        vr_parity[12] = vr_parity[11] ^ calculator.mul_general(vr_p16,vr_g12);
        vr_parity[11] = vr_parity[10] ^ calculator.mul_general(vr_p16,vr_g11);
        vr_parity[10] = vr_parity[9]  ^ calculator.mul_general(vr_p16,vr_g10);
        vr_parity[9]  = vr_parity[8]  ^ calculator.mul_general(vr_p16,vr_g9);
        vr_parity[8]  = vr_parity[7]  ^ calculator.mul_general(vr_p16,vr_g8);
        vr_parity[7]  = vr_parity[6]  ^ calculator.mul_general(vr_p16,vr_g7);
        vr_parity[6]  = vr_parity[5]  ^ calculator.mul_general(vr_p16,vr_g6);
        vr_parity[5]  = vr_parity[4]  ^ calculator.mul_general(vr_p16,vr_g5);
        vr_parity[4]  = vr_parity[3]  ^ calculator.mul_general(vr_p16,vr_g4);
        vr_parity[3]  = vr_parity[2]  ^ calculator.mul_general(vr_p16,vr_g3);
        vr_parity[2]  = vr_parity[1]  ^ calculator.mul_general(vr_p16,vr_g2);
        vr_parity[1]  = vr_parity[0]  ^ calculator.mul_general(vr_p16,vr_g1);
        vr_parity[0]  = calculator.mul_general(vr_p16,vr_g0);
    end
    for (int i=0; i<16 ; i++) begin
        vr_din[i+239] = vr_parity[15-i];
    end
endfunction:encode

`endif

//================================================
// The following code used to debug!
//================================================
//`include "gf2n_calculator.sv"

//module test_top;
//
//  bit[7:0] a [255];
//
//  rs_255_239_encoder  rs_encoder = new;
//
//  initial begin
//     a[0] = 'h11;
//     a[1] = 'h2a;
//     foreach (a[i]) begin
//        $display (" a[%3d] : %x",i, a[i] );
//     end
//     rs_encoder.encode(a);
//     // the result parity for 11,2a,0,0 ... should be : 27 78 b4 e2  3d f5 a5 79  66 94 0d 64  95 ae 4d cb
//     foreach (a[i]) begin
//        $display (" a[%3d] : %x",i, a[i] );
//     end
//     a[238] = 'hff;
//     rs_encoder.encode(a);
//     // the result parity for 11,2a,0,0 ...,ff should be : 4d f7 b8 d2  d7 12 7d d2  8e 5a cf 85  d1 90 00 a1
//     foreach (a[i]) begin
//        $display (" a[%3d] : %x",i, a[i] );
//     end
//  end
//
//endmodule
