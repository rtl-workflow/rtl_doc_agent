/**********************************************************************************
    Copyright(c) 2018 Huawei Technologies Co., Ltd, All right reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   half_hdlc_decode.sv
    Author       :   shenyue/00159590
    ===============================================================================
    Description  :   this class implement hdlc encode function
    ===============================================================================
    Modification History:
    Date        By           Rev.    Prj.    Change Description
    -------------------------------------------------------------------------------
    2018-11-08  shenyue      1.0     OH   Create
**********************************************************************************/

`ifndef _HALF_HDLC_DECODE_SV_
`define _HALF_HDLC_DECODE_SV_


class half_hdlc_decode_cfg;
    bit crc16_en       = 0 ;
    //bit align_en       = 0 ;

    bit bit_reverse_en = 1 ;
    //int sop_7e_cnt        = 3 ;
    //int eop_7e_cnt        = 3 ;
endclass

class half_hdlc_decode ;
    half_hdlc_decode_cfg cfg      ;


    string    name;
    bit [7:0] match_byte   = 0;
    bit       in_queue  [$]   ;
    bit       frame_bits[$]   ;

    //bit[7:0]  out_buf[$][$];
    bit [7:0] data_out[$];
    bit [2:0] err_type;//0:fcs_err;1:more 1err;2: not byte err;


    int sop_cnt;
    int eop_cnt;
    int ff_cnt;
    extern function new(string name);

    virtual function string get_type_name();
        return this.name;
    endfunction
    extern virtual function int decode(ref bit [7:0]data[],bit[2:0] sop_mod,bit [2:0] eop_mod);
   // extern virtual function int get_packet(ref bit [7:0]data[]);
  
    extern virtual function int del0_process();

endclass:half_hdlc_decode

function half_hdlc_decode::new(string name);

    this.name = name;
    if (cfg == null)      cfg      = new()                    ;
    err_type=0;


endfunction:new


function int half_hdlc_decode::decode(ref bit [7:0] data[],bit[2:0] sop_mod,bit [2:0] eop_mod);

    //`uvm_info(get_type_name(),$psprintf("decode get one cycle = 'h%8h",data[0]),UVM_NONE);
    err_type=0;
    frame_bits.delete();
    foreach(data[i]) begin
        for (int index = 7; index >= 0; index--)
        begin
            frame_bits.push_back(data[i][index]);
        end
    end
    repeat(sop_mod) frame_bits.pop_front(); 
    repeat(eop_mod) frame_bits.pop_back(); 

//   for(int i=0;i<20;i++)`uvm_info(get_type_name(),$sformatf("decode debug step 41 bit[%0d]=%0h",i,frame_bits[i]),UVM_HIGH); 
    del0_process();
    data.delete();
    data=data_out;
    
    return 0;
endfunction

function int half_hdlc_decode::del0_process();
    int        bit_size          = 0   ;
    int        cnt_1             = 0   ;
    bit        bit_after_del[$]        ;
    bit [7:0]  one_byte                ;
    bit [31:0] fcs_exp                 ;
    bit [31:0] fcs_act                 ;

   // bit [7:0] data_out[$];

    // delete 'hfe at end of frame
    //repeat(8) frame_bits.pop_back();

    // del 0 after 5 1's
    foreach(frame_bits [i]) begin
        if (frame_bits [i] == 1) begin
            bit_after_del.push_back(frame_bits [i] );
            cnt_1 ++;
        end
        else begin
            if (cnt_1 > 5) begin
                //`uvm_error(get_type_name(), $sformatf("found more than 5 1's in hdlc frame when i=%0d",i));
                bit_after_del.push_back(frame_bits [i] );
                err_type[1] =1;
            end
            else if (cnt_1 < 5) begin
                bit_after_del.push_back(frame_bits [i] );
            end
            else begin
                if(frame_bits [i] != 0)
                `uvm_error(get_type_name(), $sformatf("found an unexpected 1 after 5'b0" ))
            end

            cnt_1 = 0;
        end
    end

    bit_size = bit_after_del.size();
    if (bit_size % 8 != 0) begin
        // check frame size
        //`uvm_error(get_type_name(), $sformatf("hdlc after del 0 process size error, %d bits", bit_size));
         err_type[2] =1;
    end
   // else
    begin
        // pack to byte stream
        data_out.delete();
        for(int i = 0; i < bit_size/8; i ++) begin
            for(int j = 7; j >= 0; j --) begin
                one_byte[j] = bit_after_del.pop_front();
            end
            data_out.push_back(one_byte);
        end
        //`uvm_info(get_type_name(), data_out.sprint(), UVM_LOW);
        if(cfg.crc16_en == 1)
        begin
            //check crc16
            bit[7:0] data_temp[$];

            bit[7:0] data_reverse;

            fcs_act = {data_out[$-1], data_out[$-0]};
            repeat(2) data_out.pop_back();

            fcs_exp = 'h0;
            get_eth_crc16(data_out, fcs_exp);
            fcs_exp = (~fcs_exp) & 'hffff;
            if (fcs_exp != fcs_act) begin
                //`uvm_error(get_type_name(), $sformatf("crc 16 check error, fcs exp = %h, fcs act = %h", fcs_exp, fcs_act));
                 err_type[0] =1;
            end
        end

        if(cfg.bit_reverse_en == 1) begin
            bit[7:0] data_reverse;
            foreach(data_out[i])
            begin
                for (int index = 0; index < 8; index++)
                begin
                    data_reverse[7-index] = data_out[i][index];
                end
                data_out[i] = data_reverse;
            end
        end

     //   out_buf.push_back(data_out);
    end
    return 1;
endfunction

//function int hdlc_decode::get_packet(ref bit [7:0]data[]);
//    if (out_buf.size() > 0) begin
//        data = out_buf.pop_front();
//        return 0;
//    end
//    return 1;
//endfunction


`endif // _half_hdlc_decode_SV_
