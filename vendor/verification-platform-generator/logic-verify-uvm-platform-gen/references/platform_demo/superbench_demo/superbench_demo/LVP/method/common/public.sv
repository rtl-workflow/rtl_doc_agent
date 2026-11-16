//*********************************************************************
//
// Copyright(c) 2006-2007, Hisilicon Technologies Co, Ltd
// All rights reserved.
//
// Author       :  liudingjie/00127937
// Email        :  liudingjie@huawei.com
//
//---------------------------------------------------------------------
//
// File Name    :  public.sv
// Abstract     :  global task
// Called by    :  *********
//
//----------------------Modification history---------------------------
//Date        By                      Rev.    Prj.    Change Description
//---------------------------------------------------------------------
//2010-03-17  liudingjie              1.00    TD232/TD234 create
//2019-01-13  shaokun                 1.10
//
//*********************************************************************

`ifndef _EXTERN_METHOD_
`define _EXTERN_METHOD_

typedef bit[7:0]  BYTE;

function void FCS16_TASK(input bit [7:0] data_in, input bit [15:0] crc_pre, output bit [15:0] crc_result);
bit       [ 7:0]         D;
bit       [15:0]         C;
bit       [15:0]         NewCRC;
    D = data_in;
    C = crc_pre;

    NewCRC[0]  = D[4] ^ D[0] ^ C[8] ^ C[12];
    NewCRC[1]  = D[5] ^ D[1] ^ C[9] ^ C[13];
    NewCRC[2]  = D[6] ^ D[2] ^ C[10] ^ C[14];
    NewCRC[3]  = D[7] ^ D[3] ^ C[11] ^ C[15];
    NewCRC[4]  = D[4] ^ C[12];
    NewCRC[5]  = D[5] ^ D[4] ^ D[0] ^ C[8] ^ C[12] ^ C[13];
    NewCRC[6]  = D[6] ^ D[5] ^ D[1] ^ C[9] ^ C[13] ^ C[14];
    NewCRC[7]  = D[7] ^ D[6] ^ D[2] ^ C[10] ^ C[14] ^ C[15];
    NewCRC[8]  = D[7] ^ D[3] ^ C[0] ^ C[11] ^ C[15];
    NewCRC[9]  = D[4] ^ C[1] ^ C[12];
    NewCRC[10] = D[5] ^ C[2] ^ C[13];
    NewCRC[11] = D[6] ^ C[3] ^ C[14];
    NewCRC[12] = D[7] ^ D[4] ^ D[0] ^ C[4] ^ C[8] ^ C[12] ^ C[15];
    NewCRC[13] = D[5] ^ D[1] ^ C[5] ^ C[9] ^ C[13];
    NewCRC[14] = D[6] ^ D[2] ^ C[6] ^ C[10] ^ C[14];
    NewCRC[15] = D[7] ^ D[3] ^ C[7] ^ C[11] ^ C[15];

    crc_result = NewCRC;
endfunction

function void get_eth_crc16 (ref bit [7:0] q [$], output bit [15:0] crc16);
    bit [7:0] data;
    bit [15:0] crc_temp ;
    crc_temp = 16'hffff;
    foreach (q[i])
    begin
        FCS16_TASK(q[i], crc_temp, crc16);
        crc_temp = crc16;
    end
endfunction

function void CRC32_TASK(bit [31:0] reg_ini,byte data_in,output bit [31:0] reg_out,input bit rev_en);
    bit [31:0] fcs_tmp  ;
    bit [31:0] POLY     ;
    bit [7 :0] d_tmp    ;
    int i   ;
    int k   ;
    bit temp;
    begin
        POLY = 32'h04c11db7;
        if(rev_en == 1'b1)
            begin
                for (i = 0;(i < 8);i++)
                    begin
                        d_tmp[i] = data_in[(7 - i)];
                    end
            end
        else
            begin
                d_tmp = data_in;
            end
        fcs_tmp = reg_ini;
        for (i = (8 - 1);(i >= 0);i = (i - 1))
            begin
                temp = (d_tmp[i] ^ fcs_tmp[(32 - 1)]);
                for (k = (32 - 1);(k >= 1);k = (k - 1))
                    begin
                        fcs_tmp[k] = (fcs_tmp[(k - 1)] ^ (temp & POLY[k]));
                    end
                fcs_tmp[0] = temp;
            end
        reg_out = fcs_tmp;
    end
endfunction



function void CRC16_TASK(bit [15:0] reg_ini,byte data_in,output bit [15:0] reg_out,input bit rev_en);
    bit [15:0] fcs_tmp  ;
    bit [15:0] POLY     ;
    bit [7 :0] d_tmp    ;
    int i   ;
    int k   ;
    bit temp;
    begin
        POLY = 16'h0121;
        if(rev_en == 1'b1)
            begin
                for (i = 0;(i < 8);i++)
                    begin
                        d_tmp[i] = data_in[(7 - i)];
                    end
            end
        else
            begin
                d_tmp = data_in;
            end
        fcs_tmp = reg_ini;
        for (i = (8 - 1);(i >= 0);i = (i - 1))
            begin
                temp = (d_tmp[i] ^ fcs_tmp[(16 - 1)]);
                for (k = (16 - 1);(k >= 1);k = (k - 1))
                    begin
                        fcs_tmp[k] = (fcs_tmp[(k - 1)] ^ (temp & POLY[k]));
                    end
                fcs_tmp[0] = temp;
            end
        reg_out = fcs_tmp;
    end
endfunction

function   automatic void get_eth_fcs(bit[7 :0] payload[],output bit [31 :0] fcs,input bit rev_en = 1'b1, input int offset = 0, input int len = -1);
    //
    int plen;
    bit [31:0] crc32_ini;
    bit [31:0] crc32_tmp;
    byte data_tmp;

    begin
        if (len == -1)
            plen = payload.size();
        else
            plen = len;

        crc32_ini = 32'hffffffff;
        begin
            int i;
            for (i = 0;(i < plen);i++)
                begin
                    data_tmp = payload[i + offset];
                    CRC32_TASK(crc32_ini, data_tmp, crc32_tmp,1'b1);
                    crc32_ini = crc32_tmp;
                    //$display("data_tmp = 0x%8h, crc32_ini = 0x%8h", data_tmp, crc32_ini);
                end
        end
        begin
            if (rev_en == 1'b1 ) begin
                int j;
                for (j = 0;(j < 8);j++)
                begin
                    fcs[(24 + j)] = (~(crc32_ini[(31 - j)]));
                    fcs[(16 + j)] = (~(crc32_ini[(23 - j)]));
                    fcs[(8 + j)] = (~(crc32_ini[(15 - j)]));
                    fcs[(0 + j)] = (~(crc32_ini[(7 - j)]));
                end
            end
            else  begin
                fcs = crc32_ini ;
            end
            //$display("fcs = 0x%0h", fcs);
        end
    end
endfunction


function   automatic void get_eth_fcs16(ref bit[7 :0] payload[$],output bit [15 :0] fcs,input bit rev_en = 1'b1);
    //
    int plen;
    bit [15:0] crc32_ini;
    bit [15:0] crc32_tmp;
    bit [ 7:0] data_tmp;

    begin
        plen = payload.size();
        crc32_ini = 16'hffff;
        begin
            int i;
            for (i = 0;(i < plen);i++)
                begin
                    data_tmp = payload[i];
                    CRC16_TASK(crc32_ini, data_tmp, crc32_tmp,1'b1);
                    crc32_ini = crc32_tmp;
                end
        end
        begin
            if (rev_en == 1'b1 ) begin
                int j;
                for (j = 0;(j < 8);j++)
                begin
                    fcs[(8 + j)] = (~(crc32_ini[(15 - j)]));
                    fcs[(0 + j)] = (~(crc32_ini[(7 - j)]));
                end
            end
            else  begin
                fcs = crc32_ini ;
            end
        end
    end
endfunction



function   automatic void get_eth_fcs2(ref bit[7 :0] payload[$],output bit [31 :0] fcs,input bit rev_en = 1'b1);
    //
    int plen;
    bit [31:0] crc32_ini;
    bit [31:0] crc32_tmp;
    bit [ 7:0] data_tmp;

    begin
        plen = payload.size();
        crc32_ini = 32'hffffffff;
        begin
            int i;
            for (i = 0;(i < plen);i++)
                begin
                    data_tmp = payload[i];
                    CRC32_TASK(crc32_ini, data_tmp, crc32_tmp,1'b1);
                    crc32_ini = crc32_tmp;
                end
        end
        begin
            if (rev_en == 1'b1 ) begin
                int j;
                for (j = 0;(j < 8);j++)
                begin
                    fcs[(24 + j)] = (~(crc32_ini[(31 - j)]));
                    fcs[(16 + j)] = (~(crc32_ini[(23 - j)]));
                    fcs[(8 + j)] = (~(crc32_ini[(15 - j)]));
                    fcs[(0 + j)] = (~(crc32_ini[(7 - j)]));
                end
            end
            else  begin
                fcs = crc32_ini ;
            end
        end
    end
endfunction


function automatic void get_aal5_crc(ref bit[7:0] data_in[],output bit [31:0] aal5_crc,input bit rev_en = 1'b1);
//
    int plen;
    bit [31:0] crc32_ini;
    bit [31:0] crc32_tmp;
    byte data_tmp;

    begin
        plen = data_in.size();
        crc32_ini = 32'hffffffff;
        begin
            int i;
            for (i = 0;(i < plen);i++)
                begin
                    data_tmp = data_in[i];
                    CRC32_TASK(crc32_ini, data_tmp, crc32_tmp,1'b0);
                    crc32_ini = crc32_tmp;
                end
        end
        begin
            if (rev_en == 1'b1 ) begin
                int j;
                for (j = 0;(j < 8);j++)
                begin
                    aal5_crc[(24 + j)] = (~(crc32_ini[(24 + j)]));
                    aal5_crc[(16 + j)] = (~(crc32_ini[(16 + j)]));
                    aal5_crc[(8 + j)] = (~(crc32_ini[(8 + j)]));
                    aal5_crc[(0 + j)] = (~(crc32_ini[(0 + j)]));
                end
            end
            else  begin
                aal5_crc = crc32_ini ;
            end
        end
    end
endfunction

function automatic void get_bip32(ref bit[7:0] data_in[],output bit [31:0] bip32);
//
    int plen;
    bit [31:0] bip32_temp1;
    bit [31:0] bip32_temp2;

    begin
        plen = data_in.size();
        bip32_temp1 = 32'b0;
        bip32_temp2 = 32'b0;
        if(plen%4 != 0)
        begin
            $display("Error:The data is not 32 bytes multiple for BIP32");
            $stop;
        end
        for(int i=0;i<plen/4;i++)
        begin
            bip32_temp2 = {data_in[i*4],data_in[i*4+1],data_in[i*4+2],data_in[i*4+3]};
            bip32_temp1 = bip32_temp1 ^ bip32_temp2;
        end
        bip32 = bip32_temp1;
    end
endfunction

function automatic void get_scramble(ref bit[7:0] data_in[],ref bit [7:0] data_out[]);
//
    int plen_in;
    int plen_out;
    bit [7:0] scramble;
    bit [7:0] scrb_temp;

    begin
        scramble = 8'b11111110;
        plen_in = data_in.size();
        plen_out = data_out.size();
        if(plen_in != plen_out)
        begin
            $display("Error:The length of data before scrameble and after scramble is not equal,please check the ref array");
            $stop;
        end
        for(int i=0;i<plen_in;i++)
        begin
            data_out[i] = data_in[i] ^ scramble;
            //scrb_temp[7] = scramble[7] ^ scramble[6];
            //scrb_temp[6] = scramble[6] ^ scramble[5];
            //scrb_temp[5] = scramble[5] ^ scramble[4];
            //scrb_temp[4] = scramble[4] ^ scramble[3];
            //scrb_temp[3] = scramble[3] ^ scramble[2];
            //scrb_temp[2] = scramble[2] ^ scramble[1];
            //scrb_temp[1] = scramble[1] ^ scramble[0];
            //scrb_temp[0] = scramble[0] ^ scrb_temp[7];
            scrb_temp[7] = scramble[6] ^ scramble[5];
            scrb_temp[6] = scramble[5] ^ scramble[4];
            scrb_temp[5] = scramble[4] ^ scramble[3];
            scrb_temp[4] = scramble[3] ^ scramble[2];
            scrb_temp[3] = scramble[2] ^ scramble[1];
            scrb_temp[2] = scramble[1] ^ scramble[0];
            scrb_temp[1] = scramble[0] ^ scrb_temp[7];
            scrb_temp[0] = scrb_temp[7] ^ scrb_temp[6];
            scramble = scrb_temp;
        end
    end
endfunction

////将GEM帧头部分进行解绕操作后，输出
//function automatic void gem_header_descr(ref bit[7:0] payload[], input int l_offset = 0);
//    bit[7:0]    gem_hd[]        ;
//    bit[63:0]   gem_header      ;
//    bit[63:0]   new_gem_header  ;
//    bit[7:0]    new_gem_hd[]    ;
//    int         l_num           ;
//
//    gem_hd = new[8];
//    l_num  = payload.size();
//
//    foreach (gem_hd[id])
//    begin
//        if(l_num<=(l_offset+id))
//            gem_hd[id]=0;
//        else
//            gem_hd[id]=payload[l_offset+id];
//    end
//
//
//    gem_hd = new[8](gem_hd);
//    gem_header ={>>{gem_hd}};
//
//    new_gem_header = gem_header^`IDLE_GEM_HEADER;
//    $display("%m[%t]\nGEM header descramble: old gem header: %h, new gem_header: %h",$time,gem_header,new_gem_header);
//
//    new_gem_hd = new[8];
//    new_gem_hd = {>>{new_gem_header}};
//
//    foreach (new_gem_hd[id])
//    begin
//        if(l_num>(l_offset+id))
//            payload[l_offset+id]=new_gem_hd[id];
//    end
//
//endfunction

function automatic void get_crc8(ref bit[7:0] data_in[],output bit[7:0] crc8);
//
    int plen;
    bit [7:0] crc8_temp;
    bit [7:0] poly_temp;

    begin
        crc8_temp = 8'h00;
        poly_temp = 8'h07;
        plen = data_in.size();
        for(int i=0;i<plen;i++)
        begin
            crc8_temp = crc8_temp ^ data_in[i];
            for(int j=0;j<8;j++)
            begin
                if(crc8_temp[7] == 1'b1)
                begin
                    crc8_temp = crc8_temp << 1;
                    crc8_temp = crc8_temp ^ poly_temp;
                end
                else
                begin
                    crc8_temp = crc8_temp << 1;
                end
            end
        end
        crc8 = crc8_temp;
    end
endfunction

function automatic void get_hec(ref bit[7:0] data_in[],output bit[12:0] hec);
//
    int plen;
    bit [11:0] crc12_temp;
    bit [11:0] poly_temp;

    begin
        crc12_temp = 12'b0;
        poly_temp = 12'h539;
        plen = data_in.size();
        for(int i=0;i<plen;i++)
        begin
            if(i == plen - 1)
            begin
                crc12_temp[11:9] = crc12_temp[11:9] ^ data_in[plen-1][7:5];
                for(int j=0;j<3;j++)
                begin
                    if(crc12_temp[11] == 1'b1)
                    begin
                        crc12_temp = crc12_temp << 1;
                        crc12_temp = crc12_temp ^ poly_temp;
                    end
                    else
                    begin
                        crc12_temp = crc12_temp << 1;
                    end
                end
            end
            else
            begin
                crc12_temp[11:4] = crc12_temp[11:4] ^ data_in[i];
                for(int j=0;j<8;j++)
                begin
                    if(crc12_temp[11] == 1'b1)
                    begin
                        crc12_temp = crc12_temp << 1;
                        crc12_temp = crc12_temp ^ poly_temp;
                    end
                    else
                    begin
                        crc12_temp = crc12_temp << 1;
                    end
                end
            end
        end
        hec[12:1] = crc12_temp;
        hec[0] = hec[12]^ hec[11]^hec[10]^hec[9]^hec[8]^hec[7]^hec[6]^hec[5]^hec[4]^hec[3]^hec[2]^hec[1]^data_in[plen-1][7]^data_in[plen-1][6]^data_in[plen-1][5];
        for(int i=0;i<plen-1;i++)
        begin
            hec[0] = hec[0]^data_in[i][7]^data_in[i][6]^data_in[i][5]^data_in[i][4]^data_in[i][3]^data_in[i][2]^data_in[i][1]^data_in[i][0];
        end
    end
endfunction


`define get_port_data(chn, data_in)\
begin\
    uvm_sequence_item data_ori;\
    chn.get(data_ori);\
    if(!$cast(data_in, data_ori))\
    begin\
        `uvm_fatal(get_type_name(), "cast type missmatch");\
    end\
end


`define peek_port_data(chn, data_in)\
begin\
    uvm_sequence_item data_ori;\
    chn.peek(data_ori);\
    if(!$cast(data_in, data_ori))\
    begin\
        `uvm_fatal(get_type_name(), "cast type missmatch");\
    end\
end


`endif
