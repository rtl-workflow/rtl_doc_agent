//*************************************************************************
//  Copyright(c) 2018, Huawei Technologies Co., Ltd.
//  All rights reserved.
//  
//  PROJECT GROUP : gaea_platform
//  FILENAME      : basic_fcov.sv
//  AUTHOR        : l00431352
//  EMAIL         : l00431352@huawei.com
//  CREATION TIME : 2018-09-06 20:48:07 [by gen_env_uvm]
//  VERSION       : default 2.0
//  ABSTRACT      : default empty
//Description   :   this class is the basic logic verification property of fcov,to provide users with a reference
//*************************************************************************

`ifndef _BASIC_FCOV_SV
`define _BASIC_FCOV_SV

`ifndef TGS
`ifdef BASIC_FCOV

//covergroup basic_lm_cnt_cg with function sample(bit [31:0] lm_cnt);
//    option.per_instance = 1;
//    lm_cnt_cp: coverpoint lm_cnt {
//        bins b_all_0 = {0};
//        bins b_all_1 = {'1};
//        bins j = {'1 -> 0};
//        `PRJ_COV_WILDCARD_32
//    }
//endgroup: basic_lm_cnt_cg
//
//covergroup basic_cos_map_cg with function sample(int cos_en,bit [7:0][2:0] cos);
//    option.per_instance = 1;
//    cos0_cp1: coverpoint cos[0] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos0_cp0: coverpoint cos[0] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos1_cp1: coverpoint cos[1] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos1_cp0: coverpoint cos[1] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos2_cp1: coverpoint cos[2] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos2_cp0: coverpoint cos[2] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos3_cp1: coverpoint cos[3] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos3_cp0: coverpoint cos[3] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos4_cp1: coverpoint cos[4] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos4_cp0: coverpoint cos[4] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos5_cp1: coverpoint cos[5] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos5_cp0: coverpoint cos[5] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos6_cp1: coverpoint cos[6] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos6_cp0: coverpoint cos[6] iff(cos_en == 0) {bins b[] = {[0:7]};}
//    cos7_cp1: coverpoint cos[7] iff(cos_en == 1) {bins b[] = {[1:7]};}
//    cos7_cp0: coverpoint cos[7] iff(cos_en == 0) {bins b[] = {[0:7]};}
//endgroup: basic_cos_map_cg

typedef class eth_frame;
//typedef class mag_eth;
//typedef class basic_env_cfg;
//typedef class ral_block_OHP_OH_INTER;

//covergroup basic_lm_cnt_cg with function sample(bit [31:0] lm_cnt);
//    option.per_instance = 1;
//    lm_cnt_cp: coverpoint lm_cnt {
//        bins b_all_0 = {0};
//        bins b_all_1 = {'1};
//        bins j = {'1 -> 0};
//        `PRJ_COV_WILDCARD_32
//    }
//endgroup: basic_lm_cnt_cg


class basic_fcov;

    //`include "basic_eg_rm_cg.sv"
    //`include "basic_ing_rm_cg.sv"
    covergroup dummy_cg with function sample(bit dummy);
        dummy_cp : coverpoint dummy {bins bins_dummy = {1};} 
    endgroup

    //covergroup basic_pkt_kind_cg with function sample(enum {PKT_1588_SYNC,PKT_1588_DLR,PKT_1588_ANC,PKT_1588_IPV6,PKT_MNG,PKT_APS} pkt_kind);
    //    option.per_instance = 1;
    //    pkt_kind_cp: coverpoint pkt_kind;
    //endgroup: basic_pkt_kind_cg

    //ingress pkt
    covergroup basic_ing_pkt_cg with function sample(eth_frame ing_pkt);
        option.per_instance = 1;
        //pkt_kind_cp     : coverpoint ing_pkt.pkt_kind;
        //$display("debug fcov %d",ing_pkt.pload.size());
        pkt_len_cp      : coverpoint ing_pkt.frm_len {
            bins b_len[] = {63,64,128,256,512,1499,1500};
            //bins b_len[] = {[64:1500]};
        }
        //pkt_port_id_cp  : coverpoint ing_pkt.m_port_id {
        //    bins b_port_id[] = {[0:15]};
        //}
        //pkt_chan_id_cp  : coverpoint ing_pkt.m_chanid {
        //    bins b_chanid[] = {[0:7]};
        //}
        //pkt_ptype_cp  : coverpoint ing_pkt.m_ptype {
        //    bins b_ptype[] = {1,3};
        //}


        //pkt_cross0: cross pkt_port_id_cp,pkt_chan_id_cp;
        //pkt_cross1: cross pkt_port_id_cp,pkt_len_cp{
        //   bins b_0 = binsof(pkt_port_id_cp) intersect {[0:'hf]} && binsof(pkt_len_cp);
        //}

    endgroup: basic_ing_pkt_cg

    //egress pkt
    covergroup basic_eg_pkt_cg with function sample(eth_frame eg_pkt);
        option.per_instance = 1;
        //pkt_kind_cp     : coverpoint eg_pkt.pkt_kind;
        pkt_len_cp      : coverpoint eg_pkt.frm_len {
            //bins b_len[] = {42,43,64,128,256,512,1499,1500};
            bins b_len[] = {[0:1500]};
        }
        //pkt_port_id_cp  : coverpoint eg_pkt.m_port_id {
        //    bins b_port_id[] = {[0:15]};
        //}
        //pkt_chan_id_cp  : coverpoint eg_pkt.m_chanid {
        //    bins b_chanid[] = {[0:7]};
        //}
        //pkt_ptype_cp  : coverpoint eg_pkt.m_ptype {
        //    bins b_ptype[] = {1,3,8};
        //}

        //pkt_backts_cp : coverpoint eg_pkt.bk_pkt_en {
        //    bins b_bk_en[] = {0,1};
        //}

        //pkt_cross0: cross pkt_port_id_cp,pkt_chan_id_cp;
        //pkt_cross1: cross pkt_port_id_cp,pkt_len_cp{
        //   bins b_0 = binsof(pkt_port_id_cp) intersect {[0:'hf]} && binsof(pkt_len_cp);
        //}

    endgroup: basic_eg_pkt_cg

    //covergroup basic_env_cfg_cg with function sample(ral_block_OHP_OH_INTER ral_model);
    //    option.per_instance = 1;
    //    option_cp0   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[0 ].get() {bins b_option[]   = {0,1,2,3};}
    //    option_cp1   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[1 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp2   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[2 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp3   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[3 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp4   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[4 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp5   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[5 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp6   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[6 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp7   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[7 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp8   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[8 ].get() {bins b_option[]   = {0,1,2,3};}
    //    option_cp9   :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[9 ].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp10  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[10].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp11  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[11].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp12  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[12].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp13  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[13].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp14  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[14].get() {bins b_option[]   = {0,1,2  };}
    //    option_cp15  :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[15].get() {bins b_option[]   = {0,1,2  };}

    //    frm_mode_cp0 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[0 ].get()   {bins b_frm_mode[] = {0,1,2};}//1,2,4 frame;
    //    frm_mode_cp1 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[1 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp2 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[2 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp3 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[3 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp4 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[4 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp5 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[5 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp6 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[6 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp7 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[7 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp8 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[8 ].get()   {bins b_frm_mode[] = {0,1  };}//1,2,4 frame;
    //    frm_mode_cp9 :coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[9 ].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp10:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[10].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp11:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[11].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp12:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[12].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp13:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[13].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp14:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[14].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;
    //    frm_mode_cp15:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[15].get()   {bins b_frm_mode[] = {0    };}//1,2,4 frame;


    //    //ing_fcs_en_cp: coverpoint u_basic_env_cfg.u_func_basic_ing_cfg.fcs_en {
    //    //    bins b_fcs_en[] = {0,1};
    //    //}
    //    //cross cg;
    //    option_frm_mode_cross0:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[0 ].get()
    //    iff(ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[0 ].get()!=2'b00){
    //        bins b1= {0};           //b_option
    //        bins b2= {1};           //b_option
    //        bins b3= {2};           //b_option
    //        bins b4= {3};           //b_option
    //    }
    //    option_frm_mode_cross8:coverpoint ral_model.OHP_OH_INTER_PHY_MODE_OPTION[8 ].get()
    //    iff(ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[8 ].get()==2'b00){
    //        bins b1= {0};           //b_option
    //        bins b2= {1};           //b_option
    //        bins b3= {2};           //b_option
    //    }


    //    //option_frm_mode_cross0: cross option_cp0,frm_mode_cp0{
    //    //    //ignore_bins option_frm_mode_cp0 =binsof(option_cp0.b_option[3]);
    //    //};
    //    //option_frm_mode_cross8: cross option_cp8,frm_mode_cp8;
    //    option_portid_cross_all: cross option_cp0,frm_mode_cp0 {
    //       illegal_bins ignr_b = binsof(option_cp0) intersect {3} && binsof(frm_mode_cp0) intersect {0};
    //    }
    //    frm_mode_portid_cross_all: cross frm_mode_cp8,option_cp8{
    //       ignore_bins ignr_b = binsof(option_cp8) intersect {3} && binsof(frm_mode_cp8) intersect {0};
    //    }
    //    //fcs_ing_eg_cross_en: cross eg_fcs_en_cp,ing_fcs_en_cp,ing_fcs_en_del_cp;

    //endgroup: basic_env_cfg_cg
    

    //covergroup basic_eg_rm_cg with  function sample(ral_block_OHP_OH_INTER ral_model, eth_pkt in_pkt);
    //    option.per_instance = 1;

    //    eg_fcs_en_cp: coverpoint ral_model.OHP_OH_INTER_PHY_CFG_TX_FCS_EN[in_pkt.m_port_id].get() {bins b_tx_fcs_en[]   = {0,1};}

    //    ipv6_pkt_cp : coverpoint in_pkt.ipv6_flag iff(in_pkt.pkt_kind == eth_pkt::PKT_1588) {bins b_ipv6_flag = {1};}

    //    ipg_block_cp: coverpoint ral_model.OHP_OH_INTER_PHY_CFG_IPG_BLOCK[in_pkt.m_port_id].get() {
    //        bins b1= {0};
    //        bins b2= {[1:126]};
    //        bins b3= {127};
    //    }

    //    hiclk_mode_cp: coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_HICLK_AUTO_BACK_EN[in_pkt.m_port_id].get() iff(in_pkt.pkt_kind == eth_pkt::PKT_1588) {
    //        bins b1 = {0};
    //        bins b2 = {1};
    //    }
    //    
    //    pkt_opcode_cp : coverpoint in_pkt.ptp_type iff(in_pkt.pkt_kind == eth_pkt::PKT_1588) {
    //        bins b_ptp_type[] = {1,2,3,6};
    //    }

    //    p1588_len_cp: coverpoint (in_pkt.pload.size()-in_pkt.offset_1588)%2 iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ipv6_flag ==1) {
    //       bins b_1588_len[] = {0,1};
    //    }

    //    offset_1588_cp: coverpoint in_pkt.offset_1588%2 iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ipv6_flag ==1) {
    //       bins b_offset_len[] = {0,1};
    //    }

    //    standard_mode_cp: coverpoint ral_model.OHP_OH_INTER_PHY_MODE_STANDARD_MODE[in_pkt.m_port_id].get() {
    //        bins b1 = {0};
    //        bins b2 = {1};
    //    }

    //    frm_single_en_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_FRM_SINGLE_EN[in_pkt.m_port_id].get() iff(in_pkt.pkt_kind == eth_pkt::PKT_1588) {
    //        bins b_single_en[] = {0,1};
    //    }
    //    checksum_inv1_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_IPV6_CHECKSUM_INV1[in_pkt.m_port_id].get()iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ipv6_flag ==1) {
    //        bins b_inv1[] = {0,1};
    //    }
    //    checksum_inv0_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_IPV6_CHECKSUM_INV0[in_pkt.m_port_id].get()iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ipv6_flag ==1) {
    //        bins b_inv0[] = {0,1};
    //    }
    //    rx_ts_sop_en_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_RX_TS_SOP_EN[in_pkt.m_port_id].get()iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ptp_type inside {1,2,3,6}) {
    //        bins b_sop_en[] = {0,1};
    //    }
    //    tx_cf_msb_overwr_en_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_TX_CF_MSB_OVERWR_EN[in_pkt.m_port_id].get() iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ptp_type inside {1,2,3,6}) {
    //        bins b_overwr_en[] = {0,1};
    //    }
    //    tx_ts_47b_en_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_TX_TS_47B_EN[in_pkt.m_port_id].get()iff(in_pkt.pkt_kind == eth_pkt::PKT_1588 && in_pkt.ptp_type inside {1,2,3,6}) {
    //        bins b_ts_47b_en[] = {0,1};
    //    }
    //    frm_tx_count_cp:coverpoint ral_model.OHP_OH_INTER_PHY_P1588_CFG_FRM_TX_COUNT[in_pkt.m_port_id].get() iff(in_pkt.pkt_kind == eth_pkt::PKT_1588){
    //        bins b_low = {1};
    //        bins b_mid = {[2:28]};
    //        bins b_big = {29};
    //    }

    //    //frm_mode_cp: coverpoint ral_model.OHP_OH_INTER_PHY_MODE_FRM_MODE[in_pkt.m_port_id].get();
    //    asym_b31_cp: coverpoint ral_model.OHP_OH_INTER_PHY_TX_ASYM_CFG[in_pkt.m_port_id].get()>>31 { bins b_sign[] = {0,1};}

    //    pload_len_offset_len_cross: cross p1588_len_cp,offset_1588_cp;
    //    asym_b31_hiclk_mode_cross: cross hiclk_mode_cp,asym_b31_cp;
    //    pkt_opcode_hiclk_mode_cross: cross hiclk_mode_cp,pkt_opcode_cp;
    //    pkt_kind_ipg_block_cross: cross in_pkt.pkt_kind,ipg_block_cp {
    //        ignore_bins ignr_b = binsof(in_pkt.pkt_kind) intersect {eth_pkt::PKT_APS} && binsof(ipg_block_cp);
    //    }


    //endgroup: basic_eg_rm_cg

    //covergroup basic_ing_rm_cg with  function sample(ral_block_OHP_OH_INTER ral_model, mag_eth in_pkt);
    //    option.per_instance = 1;

    //    ing_fcs_en_cp    : coverpoint ral_model.OHP_OH_INTER_PHY_CFG_RX_FCS_CHK_EN[in_pkt.m_port_id].get() {bins b_rx_fcs_chk_en[]   = {0,1};}
    //    ing_fcs_del_en_cp: coverpoint ral_model.OHP_OH_INTER_PHY_CFG_RX_FCS_DEL_EN[in_pkt.m_port_id].get() {bins b_rx_fcs_del_en[]   = {0,1};}
    //    fcs_ing_eg_cross_en: cross ing_fcs_en_cp,ing_fcs_del_en_cp;

    //endgroup: basic_ing_rm_cg

    //basic_lm_cnt_cg basic_lm_cnt_cg_inst[2][int];
    //basic_cos_map_cg basic_cos_map_cg_inst[256];

    function new();
        this.dummy_cg = new();
        //foreach(basic_cos_map_cg_inst[i]) u_basic_fcov.basic_cos_map_cg_inst[i] = new();
        //this.basic_pkt_kind_cg = new;
        this.basic_eg_pkt_cg   = new;
        this.basic_ing_pkt_cg   = new;
        $display("debug fcov");
        //this.basic_env_cfg_cg   = new;
        //this.basic_eg_rm_cg = new();
        //this.basic_ing_rm_cg = new();

    endfunction:new
endclass:basic_fcov

basic_fcov u_basic_fcov = new();//gloable variable, you can use u_basic_fcov at anywhere



`define u_basic_fcov(cg_sample) u_basic_fcov.cg_sample;

//`define basic_lm_cnt_cov(i,j,cg_sample) begin \
//    case(j) \
//        0,1,2048,4094,4095: begin \
//            if(u_basic_fcov.basic_lm_cnt_cg_inst[i][j] == null) u_basic_fcov.basic_lm_cnt_cg_inst[i][j] = new(); \
//            u_basic_fcov.basic_lm_cnt_cg_inst[i][j].cg_sample; \
//        end \
//    endcase \
//end
//`define basic_cos_map_cov(i,cg_sample) begin \
//    u_basic_fcov.basic_cos_map_cg_inst[i].cg_sample; \
//end

`endif
`else
`define u_basic_fcov(cg_sample);
//`define basic_lm_cnt_cov(i,j,cg_sample);
//`define basic_cos_map_cov(i,cg_sample);
`endif


`endif
