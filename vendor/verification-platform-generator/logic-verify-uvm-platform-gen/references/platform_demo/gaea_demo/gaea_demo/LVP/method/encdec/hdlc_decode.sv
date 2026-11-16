/**********************************************************************************
    Copyright(c) 2018 Huawei Technologies Co., Ltd, All right reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   hdlc_decode.sv
    Author       :   shenyue/00159590
    ===============================================================================
    Description  :   this class implement hdlc decode function
    ===============================================================================
    Modification History:
    Date        By           Rev.    Prj.    Change Description
    -------------------------------------------------------------------------------
    2018-11-08  shenyue      1.0     OH   Create
**********************************************************************************/

`ifndef _HDLC_DECODE_SV_
`define _HDLC_DECODE_SV_

`define break_if_empty(exp) \
    if((exp) != 0) break;

class hdlc_decode_cfg ;
    bit crc16_en       = 1 ;
    bit align_en       = 0 ;
    bit l2_dec_m       = 0 ;

    bit bit_reverse_en    = 0 ;
    int sop_7e_cnt        = 3 ;
    int eop_7e_cnt        = 3 ;
    bit all_7e_m          = 0 ;
    bit sop_eop_check_en  = 1 ; // add by o00465947
    bit hdlc_8755_mode = 1; // add by o00465947
    static bit error_check_en    = 1;

endclass

class hdlc_decode ;
    hdlc_decode_cfg  cfg      ;

    enum {HUNT, MATCH, SOP, INSIDE, EOP, OUTSIDE} state;

    string    name;
    bit [7:0] match_byte   = 0;
    bit       in_queue  [$]   ;
    bit       frame_bits[$]   ;

    bit[7:0]  out_buf[$][$];

    int sop_cnt;
    int eop_cnt;
    int ff_cnt;
    extern function new(string name);

    virtual function string get_type_name();
        return this.name;
    endfunction
    extern virtual function int decode(ref bit [7:0]data[], output err_msg);
    extern virtual function int get_packet(ref bit [7:0]data[]);

    extern virtual function int get_bit();
    extern virtual function int get_byte();
    extern virtual function int del0_process();

endclass:hdlc_decode

function hdlc_decode::new(string name);

    this.name = name;
    if (cfg == null)      cfg      = new()                    ;

    state = HUNT;

endfunction:new

function int hdlc_decode::get_bit();
    if(in_queue.size == 0) begin
        return 1;
    end
    match_byte = {match_byte[6:0], in_queue.pop_front()};
    return 0;
endfunction

function int hdlc_decode::get_byte();
    if(in_queue.size < 8) begin
        return 1;
    end

    repeat(8) get_bit();
    return 0;
endfunction

function int hdlc_decode::decode(ref bit [7:0] data[], output err_msg);
    err_msg = "";
    // `uvm_info(get_type_name(),$psprintf("decode get one cycle = 'h%8h",data[0]),UVM_NONE);
    if(cfg.l2_dec_m ==1 && cfg.all_7e_m==1)begin//mid l2 7e mode
       state = HUNT;
       in_queue.delete();
       match_byte =0;
    end
    foreach(data[i]) begin
        for (int index = 7; index >= 0; index--)
        begin
            in_queue.push_back(data[i][index]);
        end
        `uvm_info(get_type_name(), $sformatf("hdlc decode get a data='h%0h", data[i]),UVM_DEBUG)
    end
    if(cfg.hdlc_8755_mode ==1)begin
        if(cfg.all_7e_m==0) begin//ins ff mode
            while(1) begin
                `uvm_info(get_type_name(), $sformatf("state = %p", state), UVM_DEBUG);
                case (state)
                    HUNT: begin
                        `break_if_empty(get_bit())
                        if(match_byte == 'h7e) begin
                            sop_cnt = 1;
                            state = MATCH;
                            match_byte = 0;
                        end
                    end
                    MATCH: begin
                        `break_if_empty(get_byte())
                        if (match_byte == 'h7e) begin
                            sop_cnt ++;
                        end
                        else if (match_byte == 'hff) begin
                            state = OUTSIDE;
                            sop_cnt = 0;
                            if(cfg.error_check_en == 1)begin
                                `uvm_error(get_type_name(), $sformatf("sop earch err "))
                            end
                        end
                        else begin
                            if(cfg.error_check_en == 1)begin
                                if(cfg.sop_eop_check_en ==1)begin
                                    if (sop_cnt != cfg.sop_7e_cnt)
                                        `uvm_error(get_type_name(), $sformatf("sop num of hdlc was expected to be %0d, but act was %0d", cfg.sop_7e_cnt, sop_cnt))
                                end
                            end
                            frame_bits.delete();
                            state = INSIDE;
                            for (int i = 7; i >= 0; i --) begin
                                frame_bits.push_back(match_byte[i]);
                            end
                            // `uvm_info(get_type_name(),$sformatf("aaaaaaaaaaaaaaaaaaaaaaaaaaaframe_bits_size:%0d",frame_bits.size() ),UVM_LOW);
                        end
                    end
                    SOP: begin
                        `break_if_empty(get_byte())
                        if (match_byte != 'h7e) begin
                            if(cfg.error_check_en == 1)begin
                                if(cfg.sop_eop_check_en ==1)begin
                                    if (sop_cnt != cfg.sop_7e_cnt)
                                        `uvm_error(get_type_name(), $sformatf("sop_7e num of hdlc was expected to be %0d, but act was %0d", cfg.sop_7e_cnt, sop_cnt))
                                end
                            end
                            frame_bits.delete();
                            state = INSIDE;
                            for (int i = 7; i >= 0; i --) begin
                                frame_bits.push_back(match_byte[i]);
                            end
                        end
                        sop_cnt ++;
                    end
                    INSIDE: begin
                        `break_if_empty(get_bit())
                        frame_bits.push_back(match_byte[0]);
                        // `uvm_info(get_type_name(),$sformatf("bbbbbbbbbbbbbbbbframe_bits_size:%0d",frame_bits.size() ),UVM_LOW);
                        if (match_byte == 'h7e) begin
                            eop_cnt = 1;
                            state = EOP;
                            // `uvm_info(get_type_name(),$sformatf("ccccccccccccccccframe_bits_size:%0d",frame_bits.size() ),UVM_LOW);
                            del0_process();
                        end
                    end
                    EOP: begin
                        `break_if_empty(get_byte())
                        if (match_byte != 'h7e) begin
                            ff_cnt = 8;
                            if(cfg.error_check_en == 1)begin
                                if(cfg.sop_eop_check_en ==1)begin
                                    if (eop_cnt != cfg.eop_7e_cnt)
                                        `uvm_error(get_type_name(), $sformatf("eop_7e num of hdlc was expected to be %0d, but act was %0d", cfg.eop_7e_cnt, eop_cnt))
                                end
                            end
                            state = OUTSIDE;
                            match_byte = 0;
                        end
                        eop_cnt ++;
                    end
                    OUTSIDE: begin
                        `break_if_empty(get_bit())
                        ff_cnt ++;
                        if (match_byte == 'h7e) begin
                            ff_cnt -= 8;
                            if(cfg.error_check_en == 1)begin
                                if (cfg.align_en == 0 && (ff_cnt % 8) != 0)
                                    `uvm_error(get_type_name(), $sformatf("1's between eop and sop was not 8 * N, act got %0d 1's", ff_cnt))
                            end
                            sop_cnt = 1;
                            state = SOP;
                        end
                    end
                    default: begin
                        `uvm_error(get_type_name(), $sformatf("default path should never reach"));
                        err_msg = "default path should never reach";
                    end
                endcase
            end
        end
        else begin // all 7e mode
            while(1) begin
                `uvm_info(get_type_name(), $sformatf("state = %p", state), UVM_DEBUG);
                case (state)
                    HUNT: begin
                        `break_if_empty(get_bit())
                        `uvm_info(get_type_name(), $sformatf("debug state hunt match_byte='h%0h", match_byte),UVM_DEBUG);
                        if(match_byte == 'h7e) begin
                            sop_cnt = 1;
                            state = MATCH;
                            match_byte = 0;
                        end
                    end
                    MATCH: begin
                        `break_if_empty(get_byte())
						`uvm_info(get_type_name(), $sformatf("debug state match match_byte='h%0h", match_byte),UVM_DEBUG)
                        if (match_byte == 'h7e) begin
                            sop_cnt ++;
                        end
                        else if (match_byte == 'hff) begin
                            //state = OUTSIDE;
                            //sop_cnt = 0;
                            if(cfg.error_check_en == 1)begin
                                `uvm_error(get_type_name(), $sformatf("sop search err "))
                            end
                        end
                        else begin
                            if(cfg.error_check_en == 1)begin
                                if(cfg.sop_eop_check_en ==1)begin
                                    if (sop_cnt < cfg.sop_7e_cnt)
                                        `uvm_error(get_type_name(), $sformatf("sop num of hdlc was expected to be %0d, but act was %0d", cfg.sop_7e_cnt, sop_cnt))
                                end
                            end
                            frame_bits.delete();
                            state = INSIDE;
                            for (int i = 7; i >= 0; i --) begin
                                frame_bits.push_back(match_byte[i]);
                            end
                        end
                    end
                    //SOP: begin
                    //    `break_if_empty(get_byte())
                    //    if (match_byte != 'h7e) begin

                    //        if (sop_cnt != cfg.sop_7e_cnt)
                    //            `uvm_error(get_type_name(), $sformatf("sop num of hdlc was expected to be %0d, but act was %0d", cfg.sop_7e_cnt, sop_cnt))

                    //        frame_bits.delete();
                    //        state = INSIDE;
                    //        for (int i = 7; i >= 0; i --) begin
                    //            frame_bits.push_back(match_byte[i]);
                    //        end
                    //    end
                    //    sop_cnt ++;
                    //end
                    INSIDE: begin
                        `break_if_empty(get_bit())
                        frame_bits.push_back(match_byte[0]);
                        `uvm_info(get_type_name(), $sformatf("debug state inside match_byte='h%0h", match_byte),UVM_DEBUG)
                        if (match_byte == 'h7e) begin
                            eop_cnt = 1;
                            state = EOP;
                            `uvm_info(get_type_name(), $sformatf("debug state inside 1 cfg.eop_7e_cnt=%0d,real=%0d", cfg.eop_7e_cnt, eop_cnt),UVM_DEBUG)
                            del0_process();
                        end
                    end
                    EOP: begin
                        `break_if_empty(get_byte())
                         `uvm_info(get_type_name(), $sformatf("debug state eop,real=%0d,match_byte='h%0h", eop_cnt,match_byte),UVM_DEBUG)
                        if(match_byte == 'h7e)begin
                            eop_cnt ++;
                            if(eop_cnt >= cfg.eop_7e_cnt) begin
                               state = MATCH;
                               match_byte = 0;
                           end
                        end
                        else  begin
                            if(cfg.error_check_en == 1)begin
                                `uvm_error(get_type_name(), $sformatf("eop num of hdlc was expected to be %0d, but act was %0d ,match_byte='h%0h", cfg.eop_7e_cnt, eop_cnt,match_byte))
                            end
                            state = HUNT;
                            match_byte = 0;
                        end
                    end
                    //OUTSIDE: begin
                    //    `break_if_empty(get_bit())
                    //    ff_cnt ++;
                    //    if (match_byte == 'h7e) begin
                    //        ff_cnt -= 8;
                    //        if (cfg.align_en == 0 && (ff_cnt % 8) != 0)
                    //            `uvm_error(get_type_name(), $sformatf("1's between eop and sop was not 8 * N, act got %0d 1's", ff_cnt))
                    //        sop_cnt = 1;
                    //        state = SOP;
                    //    end
                    //end
                    default: begin
                        if(cfg.error_check_en == 1)begin
                            `uvm_error(get_type_name(), $sformatf("default path should never reach"));
                        end
                        err_msg = "default path should never reach";
                    end
                endcase
            end
        end
    end
    else begin //new add
        while(1) begin
            `uvm_info(get_type_name(), $sformatf("state = %p", state), UVM_DEBUG);
            case (state)
                HUNT: begin
                    `break_if_empty(get_bit())
                    `uvm_info(get_type_name(), $sformatf("debug state hunt match_byte='h%0h", match_byte),UVM_DEBUG)
                    if(match_byte == 'h7e) begin
                        sop_cnt = 1;
                        state = MATCH;
                        match_byte = 0;
                    end
                end
                MATCH: begin
                    `break_if_empty(get_byte())
                    `uvm_info(get_type_name(), $sformatf("debug state match match_byte='h%0h", match_byte),UVM_DEBUG)
                    if (match_byte == 'h7e) begin
                        sop_cnt ++;
                    end
                    else if (match_byte == 'hff) begin
                        //state = OUTSIDE;
                        //sop_cnt = 0;
                        // `uvm_error(get_type_name(), $sformatf("sop search err "))
                    end
                    else begin
                        if(cfg.error_check_en == 1)begin
                            if(cfg.sop_eop_check_en ==1)begin
                                if (sop_cnt < cfg.sop_7e_cnt)
                                    `uvm_error(get_type_name(), $sformatf("sop num of hdlc was expected to be %0d, but act was %0d", cfg.sop_7e_cnt, sop_cnt))
                            end
                        end
                        frame_bits.delete();
                        state = INSIDE;
                        for (int i = 7; i >= 0; i --) begin
                            frame_bits.push_back(match_byte[i]);
                        end
                    end
                end
                INSIDE: begin
                    `break_if_empty(get_bit())
                    frame_bits.push_back(match_byte[0]);
                    `uvm_info(get_type_name(), $sformatf("debug state inside match_byte='h%0h", match_byte),UVM_DEBUG)
                    if (match_byte == 'h7e) begin
                        eop_cnt = 1;
                        state = EOP;
                        `uvm_info(get_type_name(), $sformatf("debug state inside 1 cfg.eop_7e_cnt=%0d,real=%0d", cfg.eop_7e_cnt, eop_cnt),UVM_DEBUG)
                        del0_process();
                    end
                end
                EOP: begin
                    `break_if_empty(get_byte())
                     `uvm_info(get_type_name(), $sformatf("debug state eop,real=%0d,match_byte='h%0h", eop_cnt,match_byte),UVM_DEBUG)
                    if( (match_byte == 'h7e) || ( match_byte == 'hff) )begin
                        eop_cnt ++;
                        // if(eop_cnt >= cfg.eop_7e_cnt) begin
                           state = MATCH;
                           match_byte = 0;
                       // end
                    end
                    else begin
                        //if(cfg.eop_7e_cnt == 0)begin
                            frame_bits.delete();
                            state = INSIDE;
                            for (int i = 7; i >= 0; i --) begin
                                frame_bits.push_back(match_byte[i]);
                            end
                        //end
                        //else begin
                        //    if(cfg.error_check_en == 1)begin
                        //        `uvm_error(get_type_name(), $sformatf("eop num of hdlc was expected to be %0d, but act was %0d ,match_byte='h%0h", cfg.eop_7e_cnt, eop_cnt,match_byte))
                        //    end
                        //    state = HUNT;
                        //    match_byte = 0;
                        //end
                    end
                end
                default: begin
                    if(cfg.error_check_en == 1)begin
                        `uvm_error(get_type_name(), $sformatf("default path should never reach"));
                    end
                    err_msg = "default path should never reach";
                end
            endcase
        end
    end

    return 0;

endfunction

function int hdlc_decode::del0_process();
    int        bit_size          = 0   ;
    int        cnt_1             = 0   ;
    bit        bit_after_del[$]        ;
    bit [7:0]  one_byte                ;
    bit [31:0] fcs_exp                 ;
    bit [31:0] fcs_act                 ;

    bit [7:0] data_out[$];
    bit       decode_err_flag          ;

    // delete 'hfe at end of frame
    // foreach(frame_bits[i])begin
    //     `uvm_info(get_type_name(),$sformatf("ddddddddddddddddddddddddddata[%0d]:%0b",i, frame_bits[i]),UVM_LOW);
    // end
    repeat(8) frame_bits.pop_back();

    decode_err_flag =0; // add by o00465947
    // del 0 after 5 1's
    foreach(frame_bits [i]) begin
        if (frame_bits [i] == 1) begin
            bit_after_del.push_back(frame_bits [i] );
            cnt_1 ++;
        end
        else begin
            if (cnt_1 > 5) begin
                if(cfg.error_check_en == 1)begin
                    `uvm_error(get_type_name(), $sformatf("found more than 5 1's in hdlc frame"));
                end
                decode_err_flag =1;
                bit_after_del.push_back(frame_bits [i] );
            end
            else if (cnt_1 < 5) begin
                bit_after_del.push_back(frame_bits [i] );
            end
            else begin
                if(frame_bits [i] != 0)begin
                    if(cfg.error_check_en == 1)begin
                        `uvm_error(get_type_name(), $sformatf("found an unexpected 1 after 5'b0" ));
                    end
                    decode_err_flag =1;
                end
            end
            cnt_1 = 0;
        end
    end

    bit_size = bit_after_del.size();
    if (bit_size % 8 != 0) begin
        // check frame size
        if(cfg.error_check_en == 1)begin
            `uvm_error(get_type_name(), $sformatf("hdlc after del 0 process size error, %d bits", bit_size));
        end
        decode_err_flag =1;
    end
    else begin
        // pack to byte stream
        data_out.delete();
        for(int i = 0; i < bit_size/8; i ++) begin
            for(int j = 7; j >= 0; j --) begin
                one_byte[j] = bit_after_del.pop_front();
            end
            data_out.push_back(one_byte);
        end
        // foreach(data_out[i])
        //      `uvm_info(get_type_name(),$sformatf("decode_data:%0h", data_out[i]),UVM_LOW);

        //`uvm_info(get_type_name(), data_out.sprint(), UVM_DEBUG);
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
            if (fcs_exp != fcs_act)begin
                `uvm_error(get_type_name(), $sformatf("crc 16 check error, fcs exp = %h, fcs act = %h", fcs_exp, fcs_act));
                decode_err_flag =1;
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
        // foreach(data_out[i])begin
        //     $display("mmmmmmmmmmmmmmmmmmmmmmmmm:%0h", data_out[i]);
        // end
        if(decode_err_flag ==1)begin
            foreach(data_out[i])begin
                `uvm_info(get_type_name(),$sformatf("hdlc decode drop pkt[%0d]:%0h",i, data_out[i]),UVM_LOW);
            end
        end
        else begin
            out_buf.push_back(data_out);
        end
    end
    return 1;
endfunction

function int hdlc_decode::get_packet(ref bit [7:0]data[]);
    if (out_buf.size() > 0) begin
        data = out_buf.pop_front();
        return 0;
    end
    return 1;
endfunction

`undef break_if_empty

`endif // _HDLC_DECODE_SV_
