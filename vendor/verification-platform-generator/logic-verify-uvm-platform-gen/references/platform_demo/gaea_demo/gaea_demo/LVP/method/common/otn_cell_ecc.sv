////////////////////////////////////////////////////////////////////////////////
//                  SM_FIC Verification Project
//                  ===========================
//
// File	        :   otn_cell_ecc.sv
// 
// Author		:   HuangLin <hkf51746>
// 
// Created		:	Fri May 11 13:40:58 2012
// 
// Copyright (c)2007 by Hisilicon
// 
////////////////////////////////////////////////////////////////////////////////
// Description	: ecc code generate function changed from DW_ecc.v IP
//         
//      Parameters:
//      width       - data size (8 <= "width" <= 8178)
//      chkbits     - number of checkbits (5 <= "chkbits" <= 10)                    
// 
// Function List: 
//                using example
//                bit [7:0] data_in;   - input  data
//                bit [4:0] ecc_code;  - output ecc result 
//
//                otn_cell_ecc #()   ecc_gen;
//                ecc_gen = new();
//                ecc_code = otn_cell_ecc.chk_out(data_in); 
// 
////////////////////////////////////////////////////////////////////////////////


`ifndef OTN_CELL_ECC__SV 
`define OTN_CELL_ECC__SV

class otn_cell_ecc #(int width=10,int chkbits = 5) ;
    
    int OI11IO001, OO11O110l;
    int O1O00I001, IlOO01011, IIl1lll10;
    int lO0IlIOl1, O1I1IO0IO, l1O0O110I, O0l1O10l0;
    int OIOOl1I00, O0Olll0O0, l1IO10001;
    int II010O0O1,  lI1O010l1, IOI001111;
    int O0O1O11OO, O001O1Ol1, OO0O101O0;
    int OlOOIO10I, lOlIIl001, I11000011, lOO0lO1O0, II1Il0l1l;
    int l11O1O1II [0:(1<<chkbits)-1];
    int Ill11O01O [0:(1<<(chkbits-1))-1];
    int O1111l11O, O0O1O1101;
    
    bit  [width-1:0]   lO1lOOlI0 [0:chkbits-1];
    bit  [chkbits-1:0] OO011110l;
    bit  [chkbits-1:0] II0O00OIl;
    bit  [width-1:0]   IIO0O111I;
    bit  [width-1:0]   OO01OO00I;
    bit  [chkbits-1:0] O00ll11OO;
    bit  O000001OO, IOO11O1I0;

    extern function new();
    extern virtual function void               parameter_chk();
    extern virtual function void               ini_data();
    extern virtual function bit [30:0]         OI1l0OOOI(bit [30:0] O1OO110OI,bit [30:0] OO11O110l);
    extern virtual function bit [30:0]         OI100OI00(bit [30:0] O01I10010);

    virtual function bit [chkbits-1:0]  chk_out(bit [width:0] datain);
        this.parameter_chk();
        this.ini_data();
        for (OO11O110l=0 ; OO11O110l < chkbits; OO11O110l=OO11O110l+1) begin
          OO011110l[OO11O110l] = ^(datain & lO1lOOlI0[OO11O110l]) ^
	    			((OO11O110l<2)||(OO11O110l>3))? 0 : 1;
        end
        return OO011110l;
    endfunction: chk_out

endclass: otn_cell_ecc

function otn_cell_ecc::new();
endfunction: new

function void otn_cell_ecc::parameter_chk();
     
     int param_err_flg;
     param_err_flg = 0;

     if ( (width < 8) || (width > 8178) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter width (legal range: 8 to 8178)",
	width );
    end
    
    if ( (chkbits < 5) || (chkbits > 14) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter chkbits (legal range: 5 to 14)",
	chkbits );
    end
    
    if ( width > ((1<<(chkbits-1))-chkbits) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m : Invalid parameter combination (chkbits value too low for specified width)" );
    end
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

endfunction

function bit [30:0] otn_cell_ecc::OI1l0OOOI(bit [30:0] O1OO110OI,bit [30:0] OO11O110l);

    if (O1OO110OI) begin
      if (OO11O110l < 1) OI1l0OOOI = 1;
      else if (OO11O110l > 5) OI1l0OOOI = 1;
      else OI1l0OOOI = 0;
    end else begin
      if (OO11O110l < 1) OI1l0OOOI = 5;
      else if (OO11O110l < 3) OI1l0OOOI = 1;
      else OI1l0OOOI = 0;
    end
endfunction

function bit [30:0] otn_cell_ecc::OI100OI00(bit [30:0] O01I10010);

  begin
    O0O1O1101 = O01I10010;
    O1111l11O = 0;
  
    while (O0O1O1101 != 0) begin
      if (O0O1O1101 & 1)
        O1111l11O = O1111l11O + 1;
    
      O0O1O1101 = O0O1O1101 >> 1;
    end
    
    OI100OI00 = O1111l11O;
  end
endfunction

function void otn_cell_ecc::ini_data();


    O001O1Ol1 = 5;
    OI11IO001 = 1;
    OlOOIO10I = OI11IO001 << chkbits;
    l1O0O110I = 2;
    I11000011 = OlOOIO10I >> O001O1Ol1;
    O0Olll0O0 = l1O0O110I << 4;
    
    for (OO0O101O0=0 ; OO0O101O0 < OlOOIO10I ; OO0O101O0=OO0O101O0+1) begin
      l11O1O1II[OO0O101O0]=-1;
    end
    
    lOO0lO1O0 = I11000011 * l1O0O110I;
    lO0IlIOl1 = 0;
    lOlIIl001 = O001O1Ol1 + l11O1O1II[0];
    OIOOl1I00 = O0Olll0O0 + l11O1O1II[1];
    
    for (IOI001111=0 ; (IOI001111 < lOO0lO1O0) && (lO0IlIOl1 < width) ; IOI001111=IOI001111+1) begin
      O1O00I001 = IOI001111 / l1O0O110I;
      
      if ((IOI001111 < 4) || ((IOI001111 > 8) && (IOI001111 >= (lOO0lO1O0-4))))
        O1O00I001 = O1O00I001 ^ 1;
      
      if (^IOI001111 ^ 1)
        O1O00I001 = I11000011-OI11IO001-O1O00I001;
      
      if (I11000011 == OI11IO001)
        O1O00I001 = 0;
      
      O1I1IO0IO = 0;
      O0O1O11OO = O1O00I001 << O001O1Ol1;
      
      if (IOI001111 < I11000011) begin
        II010O0O1 = 0;
        if (I11000011 > OI11IO001)
          II010O0O1 = IOI001111 % 2;
        
        O0l1O10l0 = OI1l0OOOI(II010O0O1,0);
        
        for (OO0O101O0=O0O1O11OO ; (OO0O101O0 < (O0O1O11OO+O0Olll0O0)) && (lO0IlIOl1 < width) ; OO0O101O0=OO0O101O0+1) begin
          lI1O010l1 = OI100OI00(OO0O101O0);
          if (lI1O010l1 % 2) begin
            if (O0l1O10l0 <= 0) begin
              if (lI1O010l1 > 1) begin
                l11O1O1II[OO0O101O0] = ((O1I1IO0IO < 2) && (II010O0O1 == 0))?
					lO0IlIOl1 ^ 1 : lO0IlIOl1;
		Ill11O01O[ ((O1I1IO0IO < 2) && (II010O0O1 == 0))? lO0IlIOl1 ^ 1 : lO0IlIOl1 ] =
					OO0O101O0;
		lO0IlIOl1 = lO0IlIOl1 + 1;
              end // if
              
              O1I1IO0IO = O1I1IO0IO + 1;
              
              if (O1I1IO0IO < 8) begin
                O0l1O10l0 = OI1l0OOOI(II010O0O1,O1I1IO0IO);
              
              end else begin
                OO0O101O0 = O0O1O11OO+O0Olll0O0;
              end
            end else begin
            
              O0l1O10l0 = O0l1O10l0 - 1;
            end
          end
        end
        
      end else begin
        for (OO0O101O0=O0O1O11OO+OIOOl1I00 ; (OO0O101O0 >= O0O1O11OO) && (lO0IlIOl1 < width) ; OO0O101O0=OO0O101O0-1) begin
          lI1O010l1 = OI100OI00(OO0O101O0);
          
          if (lI1O010l1 %2) begin
            if ((lI1O010l1>1) && (l11O1O1II[OO0O101O0] < 0)) begin
              l11O1O1II[OO0O101O0] = lO0IlIOl1;
              Ill11O01O[lO0IlIOl1] = OO0O101O0;
              lO0IlIOl1 = lO0IlIOl1 + 1;
            end
          end
        end
      end
    end
    
    l1IO10001 = OI11IO001 - 1;
    
    for (OO0O101O0=0 ; OO0O101O0<chkbits; OO0O101O0=OO0O101O0+1) begin
      IIO0O111I = {width{1'b0}};
      for (lO0IlIOl1=0 ; lO0IlIOl1 < width; lO0IlIOl1=lO0IlIOl1+1) begin
        if (Ill11O01O[lO0IlIOl1] & (1 << OO0O101O0)) begin
          IIO0O111I[lO0IlIOl1] = 1'b1;
        end
      end
      lO1lOOlI0[OO0O101O0] = IIO0O111I;
    end
    
    II1Il0l1l = l1IO10001 - 1;
    
    for (OO0O101O0=0 ; OO0O101O0<chkbits; OO0O101O0=OO0O101O0+1) begin
      l11O1O1II[OI11IO001<<OO0O101O0] = width+OO0O101O0;
    end

endfunction: ini_data


`endif


////////////////////////////////////////////////////////////////////////////////
// Modification History
// 		
// $Log: otn_cell_ecc.sv,v $
// Revision 1.3  2012/11/17 07:18:07  z189208
// change chk_out() not extern function to make its return bit width match chkbits
//
// Revision 1.2  2012/10/29 06:09:16  w220078
// width changed from 8bit to 10bit
//
// Revision 1.1  2012/10/23 08:39:17  w143069
// no message
//
// Revision 1.1  2012/05/12 06:02:27  hkf51746
// use for calculate otn_cell pl_len's ecc code
//
//
//
////////////////////////////////////////////////////////////////////////////////

