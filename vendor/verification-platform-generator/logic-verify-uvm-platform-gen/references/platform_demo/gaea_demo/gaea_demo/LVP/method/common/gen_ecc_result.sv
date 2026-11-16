// ---------------------------------------------------------------------
//                 OTN  Verification Project
//======================================================================
// File			:	gen_ecc_result.sv
// Author		:	yangxiaofei 254860  
// Email        :   flyer.yang@huawei.com
// Created		:	Sat Dec 12 14:06:47 2020
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef GEN_ECC_RESULT__SV
`define GEN_ECC_RESULT__SV

typedef class cpu_ecc_t; 
typedef class cpu_ecc_t_np;

class gen_ecc_result;
    //static int     ecc_mode = 0;
    static cpu_ecc_t    #(11,5)    opecc5=new();
    static cpu_ecc_t    #(26,6)    opecc6=new();
    static cpu_ecc_t    #(57,7)    opecc7=new();
    static cpu_ecc_t    #(120,8)   opecc8=new();
    static cpu_ecc_t    #(247,9)   opecc9=new();
    static cpu_ecc_t    #(502,10)  opecc10=new();
    static cpu_ecc_t    #(1013,11) opecc11=new();
    static cpu_ecc_t    #(2036,12) opecc12=new();
    static cpu_ecc_t    #(4083,13) opecc13=new();
    static cpu_ecc_t    #(8178,14) opecc14=new();
    
    static cpu_ecc_t_np #(4, 4)    opecc4_np=new();
    static cpu_ecc_t_np #(11,5)    opecc5_np=new();
    static cpu_ecc_t_np #(26,6)    opecc6_np=new();
    static cpu_ecc_t_np #(57,7)    opecc7_np=new();
    static cpu_ecc_t_np #(120,8)   opecc8_np=new();
    static cpu_ecc_t_np #(247,9)   opecc9_np=new();
    static cpu_ecc_t_np #(502,10)  opecc10_np=new();
    static cpu_ecc_t_np #(1013,11) opecc11_np=new();
    static cpu_ecc_t_np #(2036,12) opecc12_np=new();
    static cpu_ecc_t_np #(4083,13) opecc13_np=new();
    static cpu_ecc_t_np #(8178,14) opecc14_np=new();

    static task gen_ecc(input bit ecc_mode, input bit [2035:0] datain, integer bits, output bit[2047:0] eccdata);
        bit [3:0]    tm4;
        bit [4:0]    tm5;
        bit [5:0]    tm6;
        bit [6:0]    tm7;
        bit [7:0]    tm8;
        bit [8:0]    tm9;
        bit [9:0]    tm10;
        bit [10:0]   tm11;
        bit [11:0]   tm12;
        bit [12:0]   tm13;
        bit [13:0]   tm14;
        bit [2047:0] tmpdata;
        
        eccdata = 0;
        tmpdata = {12'b0,datain};
       
        if (bits > 2036) begin
           $display("ERROR! ram_gen_ecc(): input data_width must <= 2035! data_width=%d",bits);
        end    

        if (ecc_mode == 0) begin
            if (bits<=11) begin
                opecc5.gen_ecc(datain[10:0],tm5);
                eccdata[4:0]=tm5;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=26) begin
                opecc6.gen_ecc(datain[25:0],tm6);
                eccdata[5:0]=tm6;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=57) begin
                opecc7.gen_ecc(datain[56:0],tm7);
                eccdata[6:0]=tm7;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=120) begin
                opecc8.gen_ecc(datain[119:0],tm8);
                eccdata[7:0]=tm8;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=247) begin
                opecc9.gen_ecc(datain[246:0],tm9);
                eccdata[8:0]=tm9;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=502) begin
                opecc10.gen_ecc(datain[501:0],tm10);
                eccdata[9:0]=tm10;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=1013) begin
                opecc11.gen_ecc(datain[1012:0],tm11);
                eccdata[10:0] =tm11;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=2036) begin
                opecc12.gen_ecc(datain[2035:0],tm12);
                eccdata[11:0] =tm12;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            //else if (bits<=4083) begin
            //    opecc13.gen_ecc(datain[4082:0],tm13);
            //    eccdata[12:0] =tm13;
            //    eccdata = (eccdata<<bits);
            //    eccdata = (eccdata | tmpdata);
            //end
            //else if (bits<=8178) begin
            //    opecc14.gen_ecc(datain[8177:0],tm14);
            //    eccdata[13:0] =tm14;
            //    eccdata = (eccdata<<bits);
            //    eccdata = (eccdata | tmpdata);
            //end
        end
        else if (ecc_mode == 1) begin
            if (bits<=4) begin
                opecc4_np.gen_ecc(datain[3:0],tm4);
                eccdata[3:0]=tm4;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=11) begin
                opecc5_np.gen_ecc(datain[10:0],tm5);
                eccdata[4:0]=tm5;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=26) begin
                opecc6_np.gen_ecc(datain[25:0],tm6);
                eccdata[5:0]=tm6;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=57) begin
                opecc7_np.gen_ecc(datain[56:0],tm7);
                eccdata[6:0]=tm7;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata| tmpdata);
            end
            else if (bits<=120) begin
                opecc8_np.gen_ecc(datain[119:0],tm8);
                eccdata[7:0]=tm8;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=247) begin
                opecc9_np.gen_ecc(datain[246:0],tm9);
                eccdata[8:0]=tm9;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=502) begin
                opecc10_np.gen_ecc(datain[501:0],tm10);
                eccdata[9:0]=tm10;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=1013) begin
                opecc11_np.gen_ecc(datain[1012:0],tm11);
                eccdata[10:0] =tm11;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            else if (bits<=2036) begin
                opecc12_np.gen_ecc(datain[2035:0],tm12);
                eccdata[11:0] =tm12;
                eccdata = (eccdata<<bits);
                eccdata = (eccdata | tmpdata);
            end
            //else if (bits<=4083) begin
            //    opecc13_np.gen_ecc(datain[4082:0],tm13);
            //    eccdata[12:0] =tm13;
            //    eccdata = (eccdata<<bits);
            //    eccdata = (eccdata | tmpdata);
            //end
            //else if (bits<=8178) begin
            //    opecc14_np.gen_ecc(datain[8177:0],tm14);
            //    eccdata[13:0] =tm14;
            //    eccdata = (eccdata<<bits);
            //    eccdata = (eccdata | tmpdata);
            //end
        end
        $display("gen_ecc(): ecc_mode=%0d, datain=0x%0h(width=%0d) ==> eccdata=0x%0h",ecc_mode,datain,bits,eccdata);
    endtask
endclass



`endif


// ---------------------------------------------------------------------
// Modification History
//  $Log:$  
//
// ---------------------------------------------------------------------

 


