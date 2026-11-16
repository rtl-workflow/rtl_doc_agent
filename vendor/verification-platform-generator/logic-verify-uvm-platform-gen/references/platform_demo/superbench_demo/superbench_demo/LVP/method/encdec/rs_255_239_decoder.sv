// ---------------------------------------------------------------------
//                  OTN  Verification Project
//======================================================================
// File			:	rs_255_239_decoder.sv
// Author		:	liutianzhu 48758  
// Email       :  liutianzhu@huawei.com
// Created		:	Fri Jun 05 13:50:12 2009
// Copyright (c)2009 by Huawei. 
// ---------------------------------------------------------------------
// Description	: This file implement a decoder for RS(255,239) code
// 
// ---------------------------------------------------------------------


`ifndef RS_255_239_DECODER__SV
`define RS_255_239_DECODER__SV



class rs_255_239_decoder;


      // the count for the "0"-correction error, it means a received "1" be corrected to "0"  
      int    err_0_cnt       ;
      // the count for the "1"-correction error, it means a received "0" be corrected to "1"  
      int    err_1_cnt       ;
      // the count for the error bytes 
      int    err_byte_cnt    ;
      // the count for the can-not-correction code block
      int    cannot_cor_cnt  ; 

      // the otu fec need to calculate the err before data be scrambled, 
      // so here need know the scramble data
      bit[7:0] scr_data [] = new[255]; 



      // The calculator of GF(256)
      gf2n_calculator #(.GF_SIZE(8), .PRM_PL('h11d))  calculator = new; 

      // calculate the syndrome polynomial of RS(255,239)code
      extern         function void  cal_sdr (ref   bit[7:0] vr_din [], 
                                             ref   bit[7:0] vr_sdr [16] );   

      // calculate the value of polynomial sigma(x) 
      // sigma(x)=sigma_0+sigma_1*x+...+sigma_(size-1)*x^(size-1)
      //         =(((sigma_(size-1)x+sigma_(size-2))x+sigma_(size-3))x+...)x+sigma_0
      extern         function bit[7:0]  cal_polynomial (ref bit[7:0] vr_x, 
                                                        ref bit[7:0] vr_sigma [16] );   

      // the main method,
      // vr_err_count_with_scr : whether the err counter is count the err condition before scramble
      // vr_din : input code need to decode
      extern         function void  decode  ( input bit vr_err_count_with_scr,
                                              ref bit[7:0] vr_din [] );  

endclass:rs_255_239_decoder


function void  rs_255_239_decoder::cal_sdr (ref   bit[7:0] vr_din [], 
                                            ref   bit[7:0] vr_sdr [16] );   

    foreach (vr_sdr[index]) begin
        vr_sdr[index] = vr_din[0];
    end 
    for (int i=1; i<255 ; i++) begin
        vr_sdr[1]  = calculator.mul_with_a1(vr_sdr[1]);
        vr_sdr[2]  = calculator.mul_general(vr_sdr[2],  'h04);
        vr_sdr[3]  = calculator.mul_general(vr_sdr[3],  'h08);
        vr_sdr[4]  = calculator.mul_general(vr_sdr[4],  'h10);
        vr_sdr[5]  = calculator.mul_general(vr_sdr[5],  'h20);
        vr_sdr[6]  = calculator.mul_general(vr_sdr[6],  'h40);
        vr_sdr[7]  = calculator.mul_general(vr_sdr[7],  'h80);
        vr_sdr[8]  = calculator.mul_general(vr_sdr[8],  'h1d);
        vr_sdr[9]  = calculator.mul_general(vr_sdr[9],  'h3a);
        vr_sdr[10] = calculator.mul_general(vr_sdr[10], 'h74);
        vr_sdr[11] = calculator.mul_general(vr_sdr[11], 'he8);
        vr_sdr[12] = calculator.mul_general(vr_sdr[12], 'hcd);
        vr_sdr[13] = calculator.mul_general(vr_sdr[13], 'h87);
        vr_sdr[14] = calculator.mul_general(vr_sdr[14], 'h13);
        vr_sdr[15] = calculator.mul_general(vr_sdr[15], 'h26);
        foreach (vr_sdr[index]) begin
            vr_sdr[index] = vr_sdr[index] ^ vr_din[i];
        end 
    end 
endfunction:cal_sdr


function bit[7:0]  rs_255_239_decoder::cal_polynomial (ref   bit[7:0] vr_x, 
                                                       ref   bit[7:0] vr_sigma [16] );   
    bit[7:0] vr_dout = vr_sigma[15];

    for (int i= 15; i>0 ; i--) begin
        vr_dout = calculator.mul_general(vr_dout, vr_x);
        vr_dout = vr_dout ^ vr_sigma[i-1];
    end 
    return vr_dout;
endfunction:cal_polynomial

function void  rs_255_239_decoder::decode  ( input bit vr_err_count_with_scr, 
                                             ref bit[7:0] vr_din [] );  
    // the syndrome polymonial for RS(255,239) code 
    bit[7:0] vr_sdr[16]; 
    // the sigma polymonial(error location polynomial) for BM algorithm  
    bit[7:0] vr_sigma[16];
    // the the sigma(x) of the i th  iteration
    bit[7:0] vr_sigma_i[16]; 
    // the omiga polymonial(error value polynomial) for BM algorithm  
    bit[7:0] vr_omiga[16]; 
    // the the omiga(x) of the i th  iteration
    bit[7:0] vr_omiga_i[16]; 

    bit[7:0] vr_dj     = 'h00;
    bit[7:0] vr_di     = 'h01;
    bit[7:0] vr_di_inv = 'h01;
    
    int      vr_sdr_cnt = 0;

    err_0_cnt       = 0; 
    err_1_cnt       = 0; 
    err_byte_cnt    = 0; 
    cannot_cor_cnt  = 0;     

    cal_sdr(vr_din, vr_sdr);
    
    foreach (vr_sdr[i]) begin
       //$display ("s[%d] : %x", i , vr_sdr[i]);
       vr_sdr_cnt = vr_sdr_cnt + vr_sdr[i];
    end 
    // if all of syndromer equal 0, there is no error
    if (vr_sdr_cnt == 0) begin
        return;
    end
    else begin
        int vr_deg_next [$];// the deg of the sigma(j+1)x
        int vr_deg_j    = 0;
        int vr_deg_i    = 0;
        int vr_num_i    = -1;
        // BM iteration begining
        vr_dj            =  vr_sdr[0];
        // acturally, sigma(x)=1+sigma_1x+...+sigma_(size-1)x^(size-1)
        // that is sigma_0=1
        vr_sigma[0]      = 'h01;
        vr_sigma_i[0]    = 'h01; 
        vr_omiga[0]      = 'h01;
        vr_omiga_i[0]    = 0;         
        for (int j=0; j<16 ; j++) begin
            //$display (" Iteration %x, dj = %x, di = %x, di_inv = %x ", j, vr_dj, vr_di, vr_di_inv); 
            if (vr_dj != 'h0) begin
                // sigma_l_temp,omiga_l_temp is used to save the temp result
                bit[7:0] vr_sigma_temp [16] = vr_sigma;
                bit[7:0] vr_omiga_temp [16] = vr_omiga;
                bit[7:0] vr_djxdi_inv       = calculator.mul_general(vr_dj, vr_di_inv);
                // sigma(j+1)(x)=sigma(j)(x)-djdi^(-1)x^(j-i)simga(i)(x)
                // omiga(j+1)(x)=omiga(j)(x)-djdi^(-1)x^(j-i)omiga(i)(x)
                // sigma(j+1)(x): the (j+1)th iteration sigma(x)
                // omiga(j+1)(x): the (j+1)th iteration omiga(x)
                // sigma(j)(x)=1+sigma_1(j)x+...+sigma_Degj(j)x^Degj(Here Degj=1)
                for (int k= (15 - (j - vr_num_i)); k >= 0  ; k--) begin
                    vr_sigma_temp[k + (j - vr_num_i)] = vr_sigma_temp[k + (j - vr_num_i)] ^
                                                        calculator.mul_general(vr_djxdi_inv,vr_sigma_i[k]);
                    vr_omiga_temp[k + (j - vr_num_i)] = vr_omiga_temp[k + (j - vr_num_i)] ^
                                                        calculator.mul_general(vr_djxdi_inv,vr_omiga_i[k]);
                end 
                vr_deg_next = vr_sigma_temp.find_last_index with (item != 0);  

                // if  (deg_next >= deg_j)  
                 if  ((j - vr_deg_j +1) >= (vr_num_i - vr_deg_i+1)) begin 
                    //$display ("Iteration %x,  numi = %x, deg_i = %x, deg_j = %x ", 
                    //           j, vr_numi, vr_deg_i, vr_deg_j); 

                    vr_deg_i      = vr_deg_j;
                    vr_deg_j      = vr_deg_next[0];
                                            
                    vr_deg_j      = vr_deg_next[0];

                    vr_num_i      = j;
                    vr_di         = vr_dj;
                    vr_di_inv     = calculator.get_reverse(vr_dj);
                    vr_sigma_i    = vr_sigma;
                    vr_sigma      = vr_sigma_temp;
                    vr_omiga_i    = vr_omiga;
                    vr_omiga      = vr_omiga_temp;
                end
                else begin
                    vr_deg_j      = vr_deg_next[0];
                    vr_sigma      = vr_sigma_temp;
                    vr_omiga      = vr_omiga_temp;
                end
            end
            // if j = 15 , the iteration is over, else update the dj
            if  ( j < 15) begin
                vr_dj = 0;
                for (int k=0; k<j+2 ; k++) begin
                   bit[7:0] vr_d = vr_sdr[j+1-k] ;
                   //if (j==14) begin 
                   //      $display ("d = %x, sigma[k] = %x", vr_d, vr_sigma[k]); 
                   //end
                   vr_d = calculator.mul_general (vr_d,vr_sigma[k]);
                   vr_dj = vr_dj ^ vr_d ;
                   //if (j==14) begin 
                   //      $display ("d = %x, dj = %x", vr_d, vr_dj); 
                   //end
                end 
            end
        end // the iteration is over
        //foreach (vr_sigma[i]) begin
        //   $display (" sigma[%2d] : %x",i, vr_sigma[i] );
        //end        
        //foreach (vr_omiga[i]) begin
        //   $display (" omiga[%2d] : %x",i, vr_omiga[i] );
        //end        

        // vr_deg_i should not larger than 8 
        if  (vr_deg_j > 8) begin
            cannot_cor_cnt = 1;
            return;
        end
        else begin
            bit[7:0] vr_din_correct [255] = vr_din;
            bit[7:0] vr_sigma_odd [16];
            bit[7:0] vr_err_sit = 'h01;
            int vr_err_cnt = 0;
            vr_sigma_odd = vr_sigma;
            // vr_sigma_odd just contain the odd coefficient of sigma, so set the even coefficient to 0
            for (int i=0; i<8 ; i++) begin
                vr_sigma_odd[i*2] = 0; 
            end 
            for (int i=0; i<255 ; i++) begin
                bit[7:0] vr_err_value = 0;
                bit[7:0] vr_sigma_odd_x = 0;
                bit[7:0] vr_sigma_odd_x_inv = 0;
                vr_err_sit = calculator.mul_with_a1(vr_err_sit);
                if  (cal_polynomial(vr_err_sit,vr_sigma) == 0 ) begin
                    vr_err_value = cal_polynomial(vr_err_sit,vr_omiga); 
                    //$display("one of the sigma(x) 's root  is  %x",vr_err_sit);
                    //$display("the error sit is %d" ,254-i);
                    //$display("the value of omiga(x) is %x",vr_err_value);
                    vr_sigma_odd_x  = cal_polynomial(vr_err_sit,vr_sigma_odd);
                    vr_sigma_odd_x  = calculator.mul_general(vr_err_sit,vr_sigma_odd_x);
                    vr_sigma_odd_x  = calculator.get_reverse(vr_sigma_odd_x);
                    vr_err_value    = calculator.mul_general(vr_err_value, vr_sigma_odd_x );
                    //$display ("the final error value is %x",vr_err_value);
                    vr_din_correct[i] = vr_din_correct[i] ^ vr_err_value;
                    vr_err_cnt += 1;
                    err_byte_cnt += 1;
                    for (int k=0; k<8 ; k++) begin
                        if (vr_err_value[k] == 1'b1) begin
                            if (vr_err_count_with_scr == 1) begin
                                if ( (vr_din_correct[i][k] ^ scr_data[i][k]) == 1'b1) begin
                                     err_1_cnt += 1;
                                end
                                else begin
                                     err_0_cnt += 1;
                                end                          
                            end 
                            else begin
                                if ( vr_din_correct[i][k] == 1'b1 ) begin
                                     err_1_cnt += 1;
                                end
                                else begin
                                     err_0_cnt += 1;
                                end                          
                            end
                        end
                    end 
                end
            end 
            if (vr_err_cnt != vr_deg_j) begin 
                //$display ("$$$$ the error count : %d , not equal the deg_j :%d ", vr_err_cnt, vr_deg_j );  
                err_1_cnt      = 0;
                err_0_cnt      = 0;
                err_byte_cnt   = 0;
                cannot_cor_cnt = 1;
                return ; 
            end
            else begin
                vr_din = vr_din_correct;
                return ; 
            end
        end
    end
endfunction:decode

`endif


//================================================
// The following code used to debug!
//================================================

//`include "gf2n_calculator.sv"
//`include "rs_255_239_encoder.sv"
//
//module test_top;
//
//  bit[7:0] c [255];
//
//  bit[7:0] w [255];
//  
//
//  rs_255_239_encoder  rs_encoder = new;
//
//  rs_255_239_decoder  rs_decoder = new;
//
//  function void print_array(ref bit[7:0] vr_din [255] );  
//     for (byte i=0; i<32 ; i++) begin
//        string vr_temp;
//        for (int j=0; j<8 ; j++) begin
//           if ( (i != 31) || (j != 7) ) begin
//              vr_temp = $psprintf("%s  d[%3d] :%x",vr_temp, i*8 + j, vr_din[i*8 + j]);
//           end
//        end 
//        $display ("%s\n", vr_temp);
//        vr_temp = "";
//     end 
//  endfunction: print_array
//
//
//  function void compare_data ();  
//     foreach (c[i]) begin
//         if (c[i] != w[i] ) begin
//             $display("ERROR! c[%3d] : %x not equal to w[%3d] : %x]", i, c[i], i , w[i]);
//             return;
//         end
//     end
//     $display("OK! c equal to w" );
//  endfunction : compare_data
//
//
//  initial begin
//     
//     c[0] = 'h11;
//     c[1] = 'h2a;
//     rs_encoder.encode(c);
//     // the result parity for 11,2a,0,0 ... should be : 27 78 b4 e2  3d f5 a5 79  66 94 0d 64  95 ae 4d cb
//     print_array(c);
//     w = c;
//
//     for (int i=0; i<8 ; i++) begin
//        w[i] = 'hff;
//     end 
//     rs_decoder.decode(1,w);
//     compare_data;
//
//     w = c;
//     for (int i=0; i<8 ; i++) begin
//        w[i+238] = 'hff;
//     end 
//     rs_decoder.decode(1,w);
//     compare_data;
//
//     w = c;
//     for (int i=0; i<8 ; i++) begin
//        w[i+247] = 'hff;
//     end 
//     rs_decoder.decode(1,w);
//     compare_data;
//     
//  end
//  
//endmodule 



// ---------------------------------------------------------------------
// Modification History
//  $Log: rs_255_239_decoder.sv,v $
//  Revision 1.3  2009/07/08 06:19:35  l48758
//  modify according to the review result
//
//  Revision 1.2  2009/06/23 03:08:01  l48758
//  no message
//
//  Revision 1.1  2009/06/09 01:43:41  l48758
//  no message
//  
//
// ---------------------------------------------------------------------
