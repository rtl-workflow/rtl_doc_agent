/**********************************************************************************
    Copyright(c) 2018 Huawei Technologies Co., Ltd, All right reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   hdlc_encode.sv
    Author       :   shenyue/00159590
    ===============================================================================
    Description  :   this class implement hdlc encode function
    ===============================================================================
    Modification History:
    Date        By           Rev.    Prj.    Change Description
    -------------------------------------------------------------------------------
    2018-11-08  shenyue      1.0     OH   Create
**********************************************************************************/
`ifndef _HDLC_ENCODE_SV_
`define _HDLC_ENCODE_SV_


class hdlc_encode_cfg;

    int offset         = 0                                          ;
    int sop_7e_cnt     = 3                                          ;
    int eop_7e_cnt     = 3                                          ;
    int ff_cnt         = 3                                          ;
    bit cfg_otna_en    = 0                                          ; // add by o00465947 

    bit align_en       = 0                                          ;
    bit align_value    = 1                                          ;
    bit ins1_en        = 1                                          ;
    bit bit_reverse_en = 0                                          ;
    bit crc16_en       = 1                                          ;
    bit mix_size_en    = 0                                          ;
    int mix_size       = 16                                         ;
    //bit0: crc_err
    //bit1: insert more than 5bit1
    //bit2: not byte
    //bit3: add 1~25 bit before head
    //bit4: special crc_err
    //bit5: todo
    bit[5:0] ins_err   = 0                                          ;
    int err_w          = 20                                         ;

    bit sop_char[]     = '{1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0} ;
    bit eop_char[]     = '{1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0} ;
    bit ff_char[]      = '{1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1} ;

endclass

class hdlc_encode ;

    hdlc_encode_cfg     cfg      ;
    bit                 queue [$];
    bit[7:0]            err_type;

    extern function new(string name);
    extern virtual function void encode(ref bit[7:0]data_in[], output bit[7:0]data_out[]) ;

endclass:hdlc_encode

function hdlc_encode::new(string name);

    if (cfg == null)      cfg = new() ;
    err_type = 8'd0;
endfunction:new

function void hdlc_encode::encode(ref bit[7:0]data_in[], output bit[7:0]data_out[]) ;
    bit [7:0] data_tmp[$];
    bit [7:0] data_byte;
    bit [15:0] fcs;
    int        mod;
    int        queue_len;

    err_type  = 8'd0;
    repeat(cfg.offset)
    begin
        queue.push_front(1'b1);
    end
     `uvm_info("hdlc ",$psprintf("hdlc encode ins_err = 'h%0h",cfg.ins_err),UVM_MEDIUM);

    // bit reverse
    if(cfg.bit_reverse_en == 1) begin
        bit[7:0] data_reverse;

        foreach(data_in[i]) begin
            for (int index = 0; index < 8; index++) begin
                data_reverse[7-index] = data_in[i][index];
            end

            data_tmp.push_back(data_reverse);
        end
    end
    else begin
        data_tmp = data_in;
    end
    //foreach(data_tmp[i])`uvm_info("hdlc encode",$psprintf("debug step 1 data_tmp[%0d] ='h%2h",i,data_tmp[i]),UVM_MEDIUM); 

    // add crc
    if (cfg.crc16_en == 1) begin
        bit[7:0] data_fcs[$];

        get_eth_crc16(data_tmp, fcs);
        fcs[15:0] = ~fcs;
        data_tmp.push_back(fcs[15:8]);
        data_tmp.push_back(fcs[ 7:0]);
    end
     `uvm_info("hdlc ",$psprintf("hdlc encode debuf fcs = 'h%0h",fcs),UVM_MEDIUM);
     if(this.cfg.ins_err[0]==1)begin // one bit err // add by o00465947 
         randcase 
             this.cfg.err_w: begin
                 int err_data,err_bit;
                 err_data = $urandom_range(0,data_tmp.size -1);
                 err_bit  = $urandom_range(0,7);
                 data_tmp[err_data][err_bit] = ~data_tmp[err_data][err_bit];
                 err_type[0] = 1; 
             end
             100 -this.cfg.err_w:;
         endcase
     end

    // add sop
    repeat(cfg.sop_7e_cnt) begin
        foreach(cfg.sop_char[i]) begin
            queue.push_back(cfg.sop_char[i]);

        end
    end
    // add random bits between packets
    if(this.cfg.ins_err[3]==1)begin 
        randcase 
            this.cfg.err_w: begin
                int ins_num;
                ins_num  = $urandom_range(1,25);
                `uvm_info("hdlc ",$psprintf("hdlc encode ins bit_num = 'd%0d",ins_num),UVM_MEDIUM);
                repeat(ins_num)queue={$urandom%2,queue};
                err_type[3] = 1; 
            end
            100 -this.cfg.err_w:;
        endcase
    end

    // add payload and insert 1
    while (data_tmp.size() > 0) begin
        data_byte = data_tmp.pop_front();
        for (int i = 7; i >= 0; i--) begin
            queue.push_back(data_byte[i]);
            if (cfg.ins1_en == 1) begin
                if (queue.size() > 4) begin
                    if ({queue[$-4], queue[$-3], queue[$-2], queue[$-1], queue[$-0]} == 5'b11111)
                    begin
                        queue.push_back(1'b0);
                    end
                end
            end
        end
    end
    if(this.cfg.ins_err[1]==1)begin // pkt inside 6bit 1
        randcase 
            this.cfg.err_w: begin
                int err_bit;
                bit q_err[$]={1,1,1,1,1,1};
                err_bit  = $urandom_range(0,queue.size() -1);
                foreach(q_err[i])
                    queue.insert(err_bit,q_err[i]);
                err_type[1] = 1; 
            end
            100 -this.cfg.err_w:;
        endcase
    end
    else if(this.cfg.ins_err[2]==1)begin// pkt inside rand bit 0 // add by o00465947 
        randcase 
            this.cfg.err_w: begin
                int err_bit,err_num;
                err_num  = $urandom_range(3,7);
                err_bit  = $urandom_range(0,queue.size() -5);
                repeat(err_num) queue.insert(err_bit,0);
                err_type[2] = 1; 
            end
            100 -this.cfg.err_w:;
        endcase
    end
    else if(this.cfg.ins_err[4]==1)begin //last cycle inside one bit 0 // add by o00465947 
        randcase 
            this.cfg.err_w: begin
                int err_bit,err_num;
                err_num  = 1 ;
                err_bit  = queue.size() -1;
                repeat(err_num) queue.insert(err_bit,0);
                err_type[2] = 1; 
            end
            100 -this.cfg.err_w:;
        endcase
    end

    //for(int i= 0;i<100;i++)
    //    `uvm_info("hdlc encode",$psprintf("hdlc debug 1 queue[%0d] ='d%0d",i,queue[i]),UVM_HIGH);


    // add eop
    repeat(cfg.eop_7e_cnt) begin
        foreach(cfg.eop_char[i]) begin
            queue.push_back(cfg.eop_char[i]);
        end
    end

    // add ff
    repeat(cfg.ff_cnt) begin
        foreach(cfg.ff_char[i]) begin
            queue.push_back(cfg.ff_char[i]);
        end
    end
    if(cfg.mix_size_en==1) begin
        int tmp_b_size;
        tmp_b_size = queue.size()/8 +  (queue.size()%8==0?0:1);
        if(tmp_b_size<cfg.mix_size) begin
            repeat(cfg.mix_size - tmp_b_size) begin
                foreach(cfg.ff_char[i]) begin
                    queue.push_back(cfg.ff_char[i]);
                end
            end
        end
    end
    // byte align
    if (cfg.align_en == 1) begin
        mod = queue.size() % 8;
        repeat((8-mod) % 8) queue.push_back(cfg.align_value);
    end

    // convert to bytes stream
    data_tmp.delete();
    if(cfg.cfg_otna_en == 0)begin
        while (queue.size() >= 8)
        begin
            for (int i = 7; i >= 0; i--)
            begin
                data_byte[i] = queue.pop_front();
            end
            data_tmp.push_back(data_byte);
        end
        data_out = data_tmp;
    end
    else begin // add by o00465947 otna need 181byte data
        if(queue.size()%1448 == 0)begin // 181*8
            queue_len =  queue.size()/1448 +2;   
        end
        else begin
            queue_len = queue.size()/1448 +1 +2;
        end
        
        while(queue.size() < queue_len*1448 )begin
            foreach(cfg.ff_char[i]) begin
                queue.push_back(cfg.ff_char[i]);
            end
        end

        while(queue.size >= 1448)begin
            for(int j = 0; j<181; j++)begin 
                for(int i = 7; i >= 0; i--)begin
                    data_byte[i] = queue.pop_front();
                end
                data_tmp.push_back(data_byte);
            end
        end

        data_out = data_tmp;
    end

endfunction

`endif // _HDLC_ENCODE_SV_
