
//------------------------------------------------------------------------
//                 l45271 Verification Project
//                 =================================
//File			:	bytes_fifo.sv
//
//Author		:	LongZhen <longzhen@hisilicon.com>	
//
//Created		:	Tue Jun  9 13:54:31 CST 2009
//
//Copyright (c)2009 by Hisilicon
//
//------------------------------------------------------------------------
//Description	:this class is the basic logic verification property of bytes_fifo
//
//Function List	:
//
//------------------------------------------------------------------------

`ifndef BYTES_FIFO__SV
`define BYTES_FIFO__SV

typedef class bytes_fifo;

class bytes_fifo;
    
    // configuration
    int unsigned   put_lv;  // empty water line     
    
    // local status
    bit[7:0]       fifo[$]; // data buffer
    int unsigned   raddr;   // read address
    bit [7:0]      opu_res0;
    bit [7:0]      opu_res1;
    bit [7:0]      opu_res2;
    bit [7:0]      jc0;
    bit [7:0]      jc1;
    bit [7:0]      jc2;
    bit [7:0]      njo;
    
    extern         function           new(int unsigned vr_put_lv = 0);
    // functional methods
    extern         function void      put(ref bit[7:0] vr_bytes[], input int vr_ofst=0);
    extern         function void      putb(bit[7:0]    vr_byte);
    extern         function void      putq(int unsigned vr_num, ref bit[7:0] vr_bytes[$]);
    extern         function bit [7:0] geti(input int unsigned vr_ofst=0);
    extern         function bit [7:0] getb();
    extern         function void      cuti(input int unsigned vr_ofst=0);
    extern         function int       size();
    extern         function void      clear();
    extern         function bit       is_empty();
    extern         function bit [7:0] get();
    extern         function void      cut();
    extern virtual function string    psdisplay(string prefix = "");

endclass: bytes_fifo

function bytes_fifo::new(int unsigned vr_put_lv);
    this.put_lv = vr_put_lv;
    this.raddr  = 0;
endfunction: new

function void bytes_fifo::put(ref bit[7:0] vr_bytes[], input int vr_ofst);
    // local variable
    bit [7:0] vr_fill_bytes[$];
    bit [7:0] vr_in_bytes[$];
    // valid check
    if ((vr_ofst + vr_bytes.size()) < 0) begin
        //`uvm_fatal(get_type_name(),"The input negative offset more than input length!");
    end
    // change the vr_bytes[] to vr_in_bytes[$]
    vr_in_bytes = vr_bytes;
    // add the input bytes to buffer,based on the vr_ofst
    if (vr_ofst > 0) begin
        bit [7:0] vr_fill_array[] = new[vr_ofst];
        vr_fill_bytes = vr_fill_array;
        this.fifo = {this.fifo, vr_fill_bytes, vr_in_bytes};
    end       
    else if ((vr_ofst + vr_bytes.size()) > 0)begin
        this.fifo = {this.fifo, vr_in_bytes[-vr_ofst:$]};
    end 
    else;
endfunction: put

function void bytes_fifo::putb(bit[7:0] vr_byte);
    this.fifo.push_back(vr_byte);   
endfunction: putb

function void bytes_fifo::putq(int unsigned vr_num,ref bit[7:0] vr_bytes[$]);
    this.fifo = {this.fifo,vr_bytes[0:vr_num-1]};
    vr_bytes  = vr_bytes[vr_num:$];    
endfunction: putq

function bit[7:0] bytes_fifo::geti(int unsigned vr_ofst);
    geti = this.fifo[vr_ofst];
endfunction: geti

function bit[7:0] bytes_fifo::getb();
    getb = this.fifo[raddr++];
endfunction: getb

function bit[7:0] bytes_fifo::get();
    get = this.fifo[raddr++];
endfunction: get

function void bytes_fifo::cuti(int unsigned vr_ofst);
    this.fifo = this.fifo[vr_ofst:$];
endfunction: cuti

function void bytes_fifo::cut();
    if (fifo.size == raddr) begin
        fifo = {};
    end
    else begin
        this.fifo  = this.fifo[this.raddr:$];
    end
    this.raddr = 0;
endfunction: cut

function int bytes_fifo::size();
    size = this.fifo.size();
endfunction: size

function void bytes_fifo::clear();
    this.fifo  = {};
    this.raddr = 0;
endfunction: clear

function bit bytes_fifo::is_empty();
    is_empty = this.fifo.size() <= this.put_lv;
endfunction: is_empty

function string bytes_fifo::psdisplay(string prefix);
    $sformat(psdisplay,"%s :\n", prefix);
    $sformat(psdisplay,"%s %-20s : %0d\n", psdisplay, "put_lv", this.put_lv);
    $sformat(psdisplay,"%s %-20s : %0d\n", psdisplay, "raddr",  this.raddr);
    $sformat(psdisplay,"%s %-20s : %0d\n", psdisplay, "fifo.size()", this.fifo.size());
    psdisplay = ovpm#()::psarray_byte("fifo", this.fifo, psdisplay, this.fifo.size());
endfunction: psdisplay

`endif

//------------------------------------------------------------------------
// Modification History
//$Log: bytes_fifo.sv,v $
//
//
//------------------------------------------------------------------------

