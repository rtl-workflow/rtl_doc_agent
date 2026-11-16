
////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2001 - 2007 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Rick Kelly    Aug. 7, 2001
//
// VERSION:   Verilog Simulation Model for DW_ecc
//
// DesignWare_version: 12a4160b
// DesignWare_release: Z-2007.03-DWBB_0708
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Error Detection & Correction
//
//      Parameters:
//           width       - data size (8 <= "width" <= 502)
//           chkbits     - number of checkbits (5 <= "chkbits" <= 10)
//           synd_sel    - controls checkbit correction vs syndrome
//                           emission selection when gen input is not
//                           active (0 => correct check bits
//                           1 => pass syndrome to chkout)
//
//      Ports:
//           gen         - generate versus check mode control input
//                           (1 => generate check bits from datain
//                           0 => check validity of check bits on chkin
//                           with respect to data on datain and indicate
//                           the presence of errors on err_detect & err_multpl)
//           correct_n   - control signal indicating whether or not to correct
//           datain      - input data
//           chkin       - input check bits
//           err_detect  - flag indicating occurance of error
//           err_multpl  - flag indicating multibit (i.e. uncorrectable) error
//           dataout     - output data
//           chkout      - output check bits
//
//-----------------------------------------------------------------------------

class ecc_t 
    #(
        parameter   ptr_data_width = 247,
        parameter   ptr_ecc_width  = 9
    );
	int llIIIIO1, lIOII0I1;
	int O1O1Illl, Il011IIl, OO0IIllI;
	int OOIO00II, Il11Il01, O1OOOIll, O11lIO0I;
	int IlI0lOl1, OOOIlOOl, I0O0I100;
	int O11Il0l1,  IlI1lOI1, Ol1IO1l1;
	int IOOlO11O, II1010lI, OlIlOlI0;
	int O01ll0II, lOOOlIl1, OlII0l0O, llI0I0l1, IIIl0lI0;
	int I1OIOlI0 [0:(1<<ptr_ecc_width)-1];
	int l00II0I1 [0:(1<<(ptr_ecc_width -1))-1];
	int lll0Il1O, lI0l1OlO;

	bit[ptr_data_width -1:0]   OIlI11II [0:ptr_ecc_width -1];
	bit[ptr_ecc_width -1:0] IlOIl0II;
	bit[ptr_ecc_width -1:0] II111ll0;
	bit[ptr_data_width -1 :0]   I1Ol0l01;
	bit[ptr_data_width -1 :0] ll101O0O;
	bit[ptr_ecc_width -1:0] I00ll0II;
	bit Il11O1lO, O1I1OOOO;
	
	extern function new();
	extern task gen_ecc(bit[ptr_data_width -1 :0] datain, ref bit[ptr_ecc_width -1:0] ecc_bits);
	extern task check_ecc(ref bit[ptr_ecc_width -1:0] ecc_bits, bit[ptr_data_width -1 :0] datain, bit[1:0] ecc_err);
	extern task init_ecc();
	extern function bit[30:0] I1Ol11ll(bit [30:0] II1l10lI, bit [30:0] lIOII0I1);
	extern function bit[30:0] l1I1lI1O(bit [30:0] llI01l01);
endclass

function ecc_t :: new();
endfunction


task ecc_t :: gen_ecc(bit[ptr_data_width -1 :0] datain, ref bit[ptr_ecc_width -1:0] ecc_bits);
	for (lIOII0I1 = 0 ; lIOII0I1 < ptr_ecc_width ; lIOII0I1 = lIOII0I1+1) begin
		IlOIl0II[lIOII0I1] = ^(datain & OIlI11II[lIOII0I1]) ^
                ((lIOII0I1<2)||(lIOII0I1>3))? 0 : 1;
	end
    ecc_bits =  IlOIl0II;
endtask

task ecc_t :: check_ecc(ref bit[ptr_ecc_width -1:0] ecc_bits, bit[ptr_data_width -1 :0] datain, bit[1:0] ecc_err);
    for (lIOII0I1 = 0 ; lIOII0I1 < ptr_ecc_width ; lIOII0I1 = lIOII0I1 + 1) begin
      IlOIl0II[lIOII0I1] = ^(datain & OIlI11II[lIOII0I1]) ^
				((lIOII0I1 < 2) || (lIOII0I1 > 3))? 0 : 1;
    end
  
    II111ll0 = IlOIl0II ^ ecc_bits;
  
  
    ecc_bits =  II111ll0 ;
  

    if ((^(II111ll0 ^ II111ll0) !== 1'b0)) begin
        I00ll0II = {ptr_ecc_width{1'bx}};
        ll101O0O = {ptr_data_width{1'bx}};
        Il11O1lO = 1'bx;
        O1I1OOOO = 1'bx;
    end else begin
        I00ll0II = {ptr_ecc_width{1'b0}};
        ll101O0O = {ptr_data_width{1'b0}};
        if (II111ll0 === {ptr_ecc_width{1'b0}}) begin
            Il11O1lO = 1'b0;
            O1I1OOOO = 1'b0;
        end else if (I1OIOlI0[II111ll0] == IIIl0lI0) begin
            Il11O1lO = 1'b1;
            O1I1OOOO = 1'b1;
        end else begin
            Il11O1lO = 1'b1;
            O1I1OOOO = 1'b0;
            if (I1OIOlI0[II111ll0] < ptr_data_width)
                ll101O0O[I1OIOlI0[II111ll0]] = 1'b1;
            else
                I00ll0II[I1OIOlI0[II111ll0]-ptr_data_width] = 1'b1;
            end
        end

        datain =  datain ^ ll101O0O ;
        ecc_err[0]= Il11O1lO;
        ecc_err[1]= O1I1OOOO;
        //ecc_err = 0;
endtask


function bit[30:0] ecc_t :: I1Ol11ll(bit [30:0] II1l10lI, bit [30:0] lIOII0I1);
  
    if (II1l10lI) begin
        if (lIOII0I1 < 1) I1Ol11ll = 1;
        else if (lIOII0I1 > 5) I1Ol11ll = 1;
        else I1Ol11ll = 0;
    end else begin
        if (lIOII0I1 < 1) I1Ol11ll = 5;
        else if (lIOII0I1 < 3) I1Ol11ll = 1;
        else I1Ol11ll = 0;
    end

endfunction

function bit[30:0] ecc_t :: l1I1lI1O(bit [30:0] llI01l01);
  
    begin
        lI0l1OlO = llI01l01;
        lll0Il1O = 0;
   
        while (lI0l1OlO != 0) begin
            if (lI0l1OlO & 1)
                lll0Il1O = lll0Il1O + 1;
     
            lI0l1OlO = lI0l1OlO >> 1;
        end
        l1I1lI1O = lll0Il1O;
    end
endfunction

task ecc_t :: init_ecc();
    II1010lI = 5;
    llIIIIO1 = 1;
    O01ll0II = llIIIIO1 << ptr_ecc_width;
    O1OOOIll = 2;
    OlII0l0O = O01ll0II >> II1010lI;
    OOOIlOOl = O1OOOIll << 4;
    
    for (OlIlOlI0 = 0 ; OlIlOlI0 < O01ll0II ; OlIlOlI0 = OlIlOlI0 + 1) begin
        I1OIOlI0[OlIlOlI0]=-1;
    end
    
    llI0I0l1 = OlII0l0O * O1OOOIll;
    OOIO00II = 0;
    lOOOlIl1 = II1010lI + I1OIOlI0[0];
    IlI0lOl1 = OOOIlOOl + I1OIOlI0[1];
    
    for (Ol1IO1l1=0 ; (Ol1IO1l1 < llI0I0l1) && (OOIO00II < ptr_data_width) ; Ol1IO1l1=Ol1IO1l1+1) begin
        O1O1Illl = Ol1IO1l1 / O1OOOIll;
      
        if ((Ol1IO1l1 < 4) || ((Ol1IO1l1 > 8) && (Ol1IO1l1 >= (llI0I0l1-4))))
            O1O1Illl = O1O1Illl ^ 1;
      
        if (^Ol1IO1l1 ^ 1)
            O1O1Illl = OlII0l0O-llIIIIO1-O1O1Illl;
      
        if (OlII0l0O == llIIIIO1)
            O1O1Illl = 0;
      
        Il11Il01 = 0;
        IOOlO11O = O1O1Illl << II1010lI;
      
        if (Ol1IO1l1 < OlII0l0O) begin
            O11Il0l1 = 0;
            if (OlII0l0O > llIIIIO1)
                O11Il0l1 = Ol1IO1l1 % 2;
        
            O11lIO0I = I1Ol11ll(O11Il0l1,0);
        
            for (OlIlOlI0=IOOlO11O ; (OlIlOlI0 < (IOOlO11O+OOOIlOOl)) && (OOIO00II < ptr_data_width) ; OlIlOlI0=OlIlOlI0+1) begin
                IlI1lOI1 = l1I1lI1O(OlIlOlI0);
                if (IlI1lOI1 % 2) begin
                    if (O11lIO0I <= 0) begin
                        if (IlI1lOI1 > 1) begin
                            I1OIOlI0[OlIlOlI0] = ((Il11Il01 < 2) && (O11Il0l1 == 0))? OOIO00II ^ 1 : OOIO00II;
							l00II0I1[ ((Il11Il01 < 2) && (O11Il0l1 == 0))? OOIO00II ^ 1 : OOIO00II ] = OlIlOlI0;
		                    OOIO00II = OOIO00II + 1;
                        end // if
              
                        Il11Il01 = Il11Il01 + 1;
              
                        if (Il11Il01 < 8) begin
                            O11lIO0I = I1Ol11ll(O11Il0l1,Il11Il01);
              
                    end else begin
                        OlIlOlI0 = IOOlO11O+OOOIlOOl;
                    end
                end else begin
            
                    O11lIO0I = O11lIO0I - 1;
                end
            end
        end
        
        end else begin
            for (OlIlOlI0=IOOlO11O+IlI0lOl1 ; OlIlOlI0 >= IOOlO11O ; OlIlOlI0=OlIlOlI0-1) begin
                IlI1lOI1 = l1I1lI1O(OlIlOlI0);
                
                if (IlI1lOI1 %2) begin
                    if ((IlI1lOI1>1) && (I1OIOlI0[OlIlOlI0] < 0)) begin
                        I1OIOlI0[OlIlOlI0] = OOIO00II;
                        l00II0I1[OOIO00II] = OlIlOlI0;
                        OOIO00II = OOIO00II + 1;
                    end
                end
            end
        end
    end
    
    I0O0I100 = llIIIIO1 - 1;
    
    for (OlIlOlI0 = 0 ; OlIlOlI0 < ptr_ecc_width ; OlIlOlI0 = OlIlOlI0 + 1) begin
        I1Ol0l01 = {ptr_data_width{1'b0}};
        for (OOIO00II = 0 ; OOIO00II < ptr_data_width ; OOIO00II = OOIO00II + 1) begin
            if (l00II0I1[OOIO00II] & (1 << OlIlOlI0)) begin
                I1Ol0l01[OOIO00II] = 1'b1;
            end
        end
        OIlI11II[OlIlOlI0] = I1Ol0l01;
    end
    
    IIIl0lI0 = I0O0I100 - 1;
    
    for (OlIlOlI0=0 ; OlIlOlI0 < ptr_ecc_width ; OlIlOlI0 = OlIlOlI0 + 1) begin
        I1OIOlI0[llIIIIO1<<OlIlOlI0] = ptr_data_width + OlIlOlI0;
    end
    
endtask

