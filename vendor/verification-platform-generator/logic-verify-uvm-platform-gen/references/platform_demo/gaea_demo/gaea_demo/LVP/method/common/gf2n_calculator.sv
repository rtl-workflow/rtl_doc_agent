// ---------------------------------------------------------------------
//                  OTN  Verification Project
// =====================================================================
// File			:	gf2n_calculator.sv
// Author		:	liutianzhu 48758  
// Email       :  liutianzhu@huawei.com
// Created		:	Thu Jun 04 10:25:15 2009
// Copyright (c)2009 by Huawei. 
// ---------------------------------------------------------------------
// Description	: This file implement a general calculator in GF(2^n) field
//               This calculator can do the mutiple and reverse operation in the GF(2^n) field
// ---------------------------------------------------------------------


`ifndef GF2N_CALCULATOR__SV
`define GF2N_CALCULATOR__SV


// GF_SIZE  is the factor n in GF(2^n)
// PRM_PL is the primitive polynomial of the GF(2^n) field, each bit meas a coefficient of the polynomial
// for example:  the primitive polymonimial of GF(256) is x^8 + x^4 + x^3 + x^2 + 1, 
// so the prm_pl should be 9'b1_0001_1101

class gf2n_calculator #( int GF_SIZE = 8, bit[GF_SIZE:0] PRM_PL = 9'b1_0001_1101) extends uvm_object;

   int num_in_gf; // the total numbers of the item in GF(2^n)
   
   bit [GF_SIZE -1 :0]  field_item[]; 
   bit [GF_SIZE -1 :0]  item_index[]; 
   bit [GF_SIZE -1 :0]  item_rev_list[]; 

   `uvm_object_param_utils(gf2n_calculator#(GF_SIZE,PRM_PL))
                                             
   extern         function                     new(string   name="gf2n_calculator");

   //  a function, the result is the product of vr_din * a1
   extern         function bit[gf2n_calculator::GF_SIZE -1:0]  mul_with_a1 (input bit[GF_SIZE -1: 0]  vr_din );

   // generate field_item according to the prm_pl
   extern         function void                gen_field_item();
   // generate item_index according to the prm_pl
   extern         function void                gen_item_index();
   // generate item_rev_list according to the prm_pl
   extern         function void                gen_item_rev_list();

   // checking the generated field_item, judge whether the input prm_pl is correct
   extern         function void                check_field_item();

   // the general multiplier in GF(2^n)
   extern         function bit[gf2n_calculator::GF_SIZE -1:0]  mul_general (input bit[GF_SIZE -1: 0]  vr_din1, 
                                                            input bit[GF_SIZE -1: 0]  vr_din2);

   // the general reversor in GF(2^n)
   extern         function bit[gf2n_calculator::GF_SIZE -1:0]  get_reverse (input bit[GF_SIZE -1: 0]  vr_din );

endclass:gf2n_calculator


function  gf2n_calculator::new(string   name="gf2n_calculator");
    super.new(name);

    num_in_gf = 1 << GF_SIZE;
    gen_field_item();
    check_field_item();
    gen_item_index();
    gen_item_rev_list();

endfunction: new

function bit[gf2n_calculator::GF_SIZE -1:0]  gf2n_calculator::mul_with_a1 (input bit[GF_SIZE -1: 0]  vr_din );
    bit[GF_SIZE -1: 0]  vr_temp;
    bit[GF_SIZE -1: 0]  vr_result;

    vr_temp = vr_din << 1;
    if (vr_din[GF_SIZE -1: GF_SIZE -1]  == 1'b1) begin
        vr_result = vr_temp ^ PRM_PL[GF_SIZE -1:0]; 
    end
    else begin
        vr_result = vr_temp;
    end
    return vr_result;

endfunction:mul_with_a1

function void   gf2n_calculator::gen_field_item();
    bit[GF_SIZE -1: 0]  vr_a = 1;

    field_item = new[num_in_gf];
    for (int i=0; i<num_in_gf; i++) begin
       field_item[i] = vr_a;
       vr_a = mul_with_a1(vr_a);
    end    

endfunction:gen_field_item


function void   gf2n_calculator::gen_item_index();
    bit[GF_SIZE -1: 0]  vr_a = 1;

    item_index = new[num_in_gf];
    for (int i=0; i<num_in_gf - 1; i++) begin
        item_index[ field_item[i] ] = i;
    end   

endfunction:gen_item_index

function void   gf2n_calculator::gen_item_rev_list();
    bit[GF_SIZE -1: 0]  vr_a = 1;

    item_rev_list = new[num_in_gf];
    for (int i=0; i<num_in_gf - 1; i++) begin
        item_rev_list[vr_a] = field_item[num_in_gf - 1 - i]; 
        vr_a = mul_with_a1(vr_a);
    end    

endfunction:gen_item_rev_list

function void    gf2n_calculator::check_field_item();
   // not implement yet
endfunction:check_field_item

function bit[gf2n_calculator::GF_SIZE -1:0]  gf2n_calculator::mul_general ( input bit[GF_SIZE -1: 0]  vr_din1, 
                                                            input bit[GF_SIZE -1: 0]  vr_din2);
    bit[GF_SIZE -1: 0]  vr_index1 = item_index[vr_din1];
    bit[GF_SIZE -1: 0]  vr_index2 = item_index[vr_din2];

    bit[GF_SIZE -1: 0]  vr_result;
    bit[GF_SIZE -1: 0]  vr_result_index;

    // the product of 0 must be 0
    if ((vr_din1 == 0) || (vr_din2 == 0)) begin
        return 0;
    end 
    else begin 
        vr_result_index = (vr_index1 + vr_index2)%(num_in_gf -1); 
        vr_result = field_item[vr_result_index];
        return vr_result;
    end
endfunction:mul_general



function bit[gf2n_calculator::GF_SIZE -1:0]  gf2n_calculator::get_reverse ( input bit[GF_SIZE -1: 0]  vr_din);

    //// There is no reverse for 0, so the input must not be 0
    //if (vr_din == 0) begin
    //    `vmm_fatal(this.log, "There is no reverse for 0, please check the program ! -_- ... "); 
    //end 
    get_reverse = item_rev_list[vr_din];
endfunction:get_reverse


`endif

//================================================
// The following code used to debug!
//================================================


//module test_top;
//
//  bit[7:0] a;
//  bit[7:0] b;
//  bit[7:0] c;
//
//  gf2n_calculator #(.GF_SIZE(8), .PRM_PL('h11d))  calculator = new;
//
//  initial begin
//     a = 'h1d;
//     b = 'h3a;
//     c = calculator.mul_general(a,b);
//     $display (" a : %x , b = %x , result of a*b = %x", a,b,c );
//     a = c;
//     c = calculator.mul_general(a,b);
//     $display (" a : %x , b = %x , result of a*b = %x", a,b,c );
//     c = calculator.get_reverse(b);
//     $display (" b : %x, the reserve of b = %x", b,c );
//  end
//  
//endmodule  

//module test_top;
//
//  bit[10:0] a;
//  bit[10:0] b;
//  bit[10:0] c;
//
//  gf2n_calculator #(.GF_SIZE(11), .PRM_PL('h805))  calculator = new;
//
//  initial begin
//     a = 'h14;
//     b = 'h28;
//     c = calculator.mul_general(a,b);
//     $display (" a : %x , b = %x , result of a*b = %x", a,b,c );
//     a = c;
//     c = calculator.mul_general(a,b);
//     $display (" a : %x , b = %x , result of a*b = %x", a,b,c );
//     c = calculator.get_reverse(b);
//     $display (" b : %x, the reserve of b = %x", b,c );
//  end
//  
//endmodule  




// Modification History
//  $Log: gf2n_calculator.sv,v $
//  Revision 1.1  2010/08/18 01:27:39  l54766
//  no message
//
//  Revision 1.3  2009/07/08 02:02:06  l48758
//  delete the assertion in reverse function
//
//  Revision 1.2  2009/06/05 05:43:38  l48758
//  modified some comment
//
//  Revision 1.1  2009/06/05 01:31:32  l48758
//  no message
//  
//
// ---------------------------------------------------------------------



