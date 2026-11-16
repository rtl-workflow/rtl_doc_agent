// ---------------------------------------------------------------------
//                  OTN Verification Project
//                  =================================
// File			:	ovpm.sv
// Author		:	Shi Xiao Yu 00125255
// Email        :   shixiaoyu00125255@huawei.com
// Created		:	Thu 18 Jun 2009 02:19:19 PM CST
// Copyright (c)2008 by Huawei
// ---------------------------------------------------------------------
// Description	:
// 
// ---------------------------------------------------------------------

`ifndef OVPM__SV
`define OVPM__SV

`ifndef INIT_PRINT_LEN
    `define INIT_PRINT_LEN 0
`endif

`ifndef OVPM_MPI_DATA_WIDTH
    `define OVPM_MPI_DATA_WIDTH 32
`endif

`ifndef CN_SEQ_W
    `define CN_SEQ_W 7
`endif

// vmm // `include "vmm_ral.sv"

class ovpm #(int LENGTH = 16) extends uvm_object;

    `uvm_object_utils(ovpm)
 
// **************************************************************************
// function(task)   :   psarray_byte
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_byte(string    vr_name = "",
                                           bit [7:0] vr_list[],
                                           string    prefix = "",
                                           int       vr_length = `INIT_PRINT_LEN);

extern static function string psarray_byte_q(string    vr_name = "",
                                             bit [7:0] vr_list[$],
                                             string    vr_prefix = "",
                                             int       vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   psarray_int
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_int(string vr_name = "",
                                          int    vr_list[],
                                          string prefix = "",
                                          int    vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   psarray_bit
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_bit(string vr_name = "",
                                          bit    vr_list[],
                                          string prefix = "",
                                          int    vr_length = `INIT_PRINT_LEN);

extern static function string psarray_bit_q(string    vr_name = "",
                                            bit       vr_list[$],
                                            string    vr_prefix = "",
                                            int       vr_length = `INIT_PRINT_LEN);
// **************************************************************************
// function(task)   :   psarray_frame
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_frame(string        vr_name = "",
                                            ovpt::frame_e vr_list[],
                                            string        prefix = "",
                                            int           vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   psarray_otu_map_mode
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_otu_map_mode(string               vr_name = "",
                                                   ovpt::otu_map_mode_e vr_list[],
                                                   string               prefix = "",
                                                   int                  vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   psarray_cbyte_adjust
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_cbyte_adjust(string               vr_name = "",
                                                   ovpt::cbyte_adjust_e vr_list[],
                                                   string               prefix = "",
                                                   int                  vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   psarray_jc_adjust
// purpose          :   Function for print dynamic array with wanted length
// author           :   Long Zhen 45271
// **************************************************************************
extern static function string psarray_jc_adjust(string            vr_name = "",
                                                ovpt::jc_adjust_e vr_list[],
                                                string            prefix = "",
                                                int               vr_length = `INIT_PRINT_LEN);

// **************************************************************************
// function(task)   :   cmp_array2byte 
// purpose          :   Function for compare the selected part of the array with the input byte
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function bit cmp_array2byte(ref bit[7:0]   vr_array[],
                                          input int      vr_start,
                                          input int      vr_end,
                                          input bit[7:0] vr_cmp_byte);

// **************************************************************************
// function(task)   :   cmp_array2double_byte 
// purpose          :   Function for compare the selected part of the array with the input double byte
// author           :   Huang Shan Yong 191679 
// **************************************************************************
extern static function bit cmp_array2double_byte(ref bit[7:0]    vr_array[],
                                                 input int       vr_start,
                                                 input int       vr_end,
                                                 input bit[15:0] vr_cmp_double_byte);
// **************************************************************************
// function(task)   :   cmp_queue2byte 
// purpose          :   Function for compare the selected part of the queue with the input byte
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function bit cmp_queue2byte(ref bit[7:0]   vr_queue[$],
                                          input int      vr_start,
                                          input int      vr_end,
                                          input bit[7:0] vr_cmp_byte);

// **************************************************************************
// function(task)   :   byte_array_cut 
// purpose          :   Function for cut the input array to the selected part
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function void byte_array_cut(ref bit[7:0] vr_array[],
                                           input int    vr_start,
                                           input int    vr_end);

// **************************************************************************
// function(task)   :   byte_array_cut 
// purpose          :   Function for cut the input array to the selected part
// author           :   Yuan Ying 00152761 
// **************************************************************************
extern static function void bit_array_cut(ref bit   vr_array[],
                                          input int vr_start,
                                          input int vr_end);

// **************************************************************************
// function(task)   :   byte_array_joint
// purpose          :   Function for joint the input array, vr_array1 <= {vr_array1,vr_array2} 
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function void byte_array_joint(ref bit[7:0] vr_array1[],
                                             ref bit[7:0] vr_array2[]);

// **************************************************************************
// function(task)   :   byte_array_compare
// purpose          :   Function for compare the selected slice of the input two array, 
//                      return is the count of the total different bits.
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function int byte_array_compare_bit(ref bit[7:0] vr_array1[],
                                                  ref bit[7:0] vr_array2[],
                                                  input int    vr_start,
                                                  input int    vr_end);

// **************************************************************************
// function(task)   :   fix_rate_err_ins
// purpose          :   Function for insert error bit at a fix rate
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function void fix_rate_err_ins (ref bit[7:0] vr_bytes[],
                                              ref int      vr_cycle_count, // count for the err cycle
                                              ref int      vr_total_num,   // total error num, -1 means constant insert  
                                              input int    vr_err_cycle,
                                              input int    vr_err_num,
                                              input int    vr_offset = 0);

// **************************************************************************
// function(task)   :   fix_rate_err_ins_avge
// purpose          :   Function for insert error bit average
// author           :   Xie Hong Bo 232351 
// **************************************************************************
extern static function void fix_rate_err_ins_avge (ref bit[7:0] vr_bytes[],
                                                   ref int      vr_cycle_count,  // count for the err cycle
                                                   ref int      vr_total_num,    // total error num, -1 means constant insert  
                                                   input int    vr_err_cycle,
                                                   input int    vr_err_num,
                                                   input int    vr_offset = 0);                             
                             
// **************************************************************************
// function(task)   :   byte_array_bit_adjust
// purpose          :   Function for adjust the bit order of the vr_array
// author           :   Liu Tian Zhu 48758 
// **************************************************************************
extern static function void byte_array_bit_adjust(ref bit[7:0] vr_array[],
                                                  input int    vr_bit_order,
                                                  ref bit[7:0] vr_remain_data);

// **************************************************************************
// function(task)   :   crc16_correct_table
// purpose          :   Function for look up crc correct bit mask
// author           :   Chen Yang 65070
// **************************************************************************
extern static function bit[32:0] crc16_correct_table(bit[15:0] vr_crc_result);

// **************************************************************************
// function(task)   :   scrm
// purpose          :   Function for calculate all kinds of scramble
// author           :   Shi Xiao Yu 00125255
// **************************************************************************
extern static function void scrm(bit [LENGTH -1:0]     vr_poly,
                                 ref bit [LENGTH -1:0] vr_scrm_reg,
                                 ref bit [7:0]         vr_data[],
                                 input bit             vr_mode = 0,
                                 input int             vr_start_pos = -1,
                                 input int             vr_end_pos = -1,
                                 input bit             vr_x1_use = 0);

// **************************************************************************
// function(task)   :   descrm
// purpose          :   Function for calculate all kinds of descramble
// author           :   Shi Xiao Yu 00125255
// **************************************************************************
extern static function void descrm(bit [LENGTH -1:0]     vr_poly,
                                   ref bit [LENGTH -1:0] vr_descrm_reg,
                                   ref bit [7:0]         vr_data[],
                                   input bit             vr_mode = 0,
                                   input int             vr_start_pos = -1,
                                   input int             vr_end_pos = -1,
                                   input bit             vr_x1_use = 0);

// **************************************************************************
// function(task)   :   gen_prbs31_data 
// purpose          :   Function for generate prbs31 data in accord with the input data and length
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static function void gen_prbs31_data(ref   bit [30:0]   vr_prbs31_ini_data,
                                            input int          vr_length,
                                            ref   bit [7:0]    vr_data[],
                                            input int unsigned vr_offset = 0);

// **************************************************************************
// function(task)   :   gen_pattern_data 
// purpose          :   Function for generate pattern data in accord with the input data, error enable and length
// author           :   Yang Yang 189277
// **************************************************************************
extern static function void gen_pattern_data(input bit [15:0]    vr_err_pattern,
                                             input bit [15:0]    vr_exp_pattern,
                                             input int           vr_length,
                                             input int           vr_err_start_bytes,
                                             ref   bit [7:0]     vr_data[],
                                             ref   int           vr_err_num
                                           );

// **************************************************************************
// function(task)   :   gen_pn11_data 
// purpose          :   Function for generate pn11 data in accord with the input data and length
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static function void gen_pn11_data(ref   bit [10:0]   vr_pn11_ini_data,
                                          input int          vr_length,
                                          ref   bit [7:0]    vr_data[],
                                          input int unsigned vr_offset = 0);

// **************************************************************************
// function(task)   :   pn11_data_check 
// purpose          :   Function for check if the input data is pn11 data 
// Note             :   User should input the right vr_pn11_ini_data!! 
//                      vr_pn11_is_sync means the sync state of pn11-checking
//                      vr_pn11_is_sync == 1 means input is pn11, 0 means input isn't pn11
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static function void pn11_data_check(ref bit        vr_pn11_is_sync,
                                            ref bit [10:0] vr_pn11_ini_data,
                                            ref bit [7:0]  vr_data[]);

// **************************************************************************
// function(task)   :   seq_data_check 
// purpose          :   Function for check if the input data is a repeated sequence,eg. 10b_error fixed-code 
// Note             :   User should input the fixed sequence: vr_seq_data
//                      vr_seq_is_sync == 1 means the input data is expected repeated sequence                      
// author           :   Xu Aiguo 00139108
// **************************************************************************
extern static function void seq_data_check(ref   bit       vr_seq_is_sync,
                                           ref   int       vr_seq_ini_idx,
                                           input bit [7:0] vr_seq_data[],
                                           ref   bit [7:0] vr_data[]);

// **************************************************************************
// function(task)   :   get_simtime
// purpose          :   Function for delay by unit of ns for simulation
// author           :   Wang Lei 00191641
// **************************************************************************
extern static function real get_simtime(string unit = "ns");

// **************************************************************************
// function(task)   :   ovp_delay_ns
// purpose          :   Function for delay by unit of ns for simulation
// author           :   Wang Lei 00191641
// **************************************************************************
extern static task ovp_delay_ns(input real delay,
                                input bit  vr_print = 0);


// **************************************************************************
// function(task)   :   ovp_delay_us
// purpose          :   Function for delay by unit of us for simulation
// author           :   Wang Lei 00191641
// **************************************************************************
extern static task ovp_delay_us(input real delay,
                                input bit  vr_print = 0);

// **************************************************************************
// function(task)   :   ovp_delay_ms
// purpose          :   Function for delay by unit of ms for simulation
// author           :   Wang Lei 00191641
// **************************************************************************
extern static task ovp_delay_ms(input real delay,
                                input bit  vr_print = 0);


// **************************************************************************
// function(task)   :   bit2byte
// purpose          :   Function for delay by unit of ms for simulation
// author           :   Wang Lei 00191641
// **************************************************************************
extern static function          bit2byte(ref    bit      pr_bit_a[],
                                         output bit[7:0] pr_byte_a[]);
extern static function          byte2bit(ref  bit[7:0]   pr_byte_a[],
                                         output bit      pr_bit_a[]);
extern static function bit[6:0] crc_calc(ref bit[7:0]    pr_in_a[]);
extern static function bit[7:0] sum_calc(ref bit[7:0]    pr_in_a[]);
extern static function void     gen_prbs_bit(ref   int               	pr_prbs_ini_data,
											 input ovpt::prbs_type_e   pr_prbs_type = ovpt::PRBS23, 
                                             input int           	    pr_length,
                                             ref   bit           	    pr_data[],
                                             input int unsigned  	    pr_offset = 0
                                            );

extern static function void     prbs_bit_check(ref   bit           	     pr_prbs_is_sync,
											   input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                                			   ref   int                 pr_prbs_ini_data,
			                                   ref   bit                 pr_data[]
            				                  );
extern static function void     gen_prbs_byte(ref   int               	pr_prbs_ini_data,
										  	  input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                                              input int           	    pr_length,
                                              ref   bit[7:0]      	    pr_data[],
                                              input int unsigned  	    pr_offset = 0
                                             );

extern static function void     prbs_byte_check(ref   bit           	  pr_prbs_is_sync,
											    input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                                			    ref   int                 pr_prbs_ini_data,
			                                    ref   bit[7:0]            pr_data[]
            				                   );
 
// **************************************************************************
// function(task)   :   floor\ceiling
// purpose          :   real to int 
// author           :   xiexianchuan 00180017
// **************************************************************************
extern static function int      floor(real vr_real);
extern static function int      ceiling(real vr_real);

extern static function void bit_reverse(ref bit[LENGTH -1 :0] reverse_da);

// **************************************************************************
// function(task)   :   field_check
// purpose          :   Function for check the dut reg field out by ral model
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static task field_check(ref uvm_reg_field                      vr_field,
                               input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data,
                               output bit                             vr_result_is_ok,
                               input  int                             vr_frm_cnt = 0,
                               input  int                             vr_stream_id = 0,
                               input  int                             vr_scnr_num = 0,
                               input  bit                             vr_print_mode = 0);

// **************************************************************************
// function(task)   :   rc_field_check
// purpose          :   Function for check the dut rc reg field out by ral model
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static task rc_field_check(ref uvm_reg_field                     vr_field,
                                  input bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data1,
                                  input bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data2,
                                  output bit                            vr_result_is_ok,
                                  input int                             vr_frm_cnt = 0,
                                  input int                             vr_stream_id = 0,
                                  input int                             vr_scnr_num = 0,
                                  input bit                             vr_print_mode = 0);

// **************************************************************************
// function(task)   :   reg_check
// purpose          :   Function for check the dut reg out by ral model
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static task reg_check(input uvm_reg                         vr_reg,
                             input bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data,
                             output bit vr_result_is_ok);

// **************************************************************************
// function(task)   :   rc_reg_check
// purpose          :   Function for check the dut rc_reg out by ral model
// author           :   Liu Tian Zhu 48758
// **************************************************************************
extern static task rc_reg_check(input uvm_reg                         vr_reg,
                                input bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data1,
                                input bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data2,
                                output bit vr_result_is_ok);

// **************************************************************************
// function(task)   :   check_reg
// purpose          :   Function for check the dut reg out by ral model
// author           :   dengrong 00300406
// **************************************************************************
extern static task check_reg(uvm_reg                          vr_reg,
                             bit [`OVPM_MPI_DATA_WIDTH -1:0]  exp = 'h0,
                             bit [`OVPM_MPI_DATA_WIDTH -1:0]  msk = 'h0,
                             bit                             vr_chk = 1);

// **************************************************************************
// function(task)   :   check_fld
// purpose          :   Function for check the dut reg out by ral model
// author           :   dengrong 00300406
// **************************************************************************
extern static task check_fld(uvm_reg_field                      fld,
                             bit [`OVPM_MPI_DATA_WIDTH -1:0]    exp = 'h0,
                             bit [`OVPM_MPI_DATA_WIDTH -1:0]    msk = 'h0,
                             bit                                chk = 1);
// **************************************************************************
// function(task)   :   gen_odtu_seq_cn
// purpose          :   gen_odtu_seq_cn 
// author           :   shujun 00190652
// **************************************************************************
extern  static  function void   gen_odtu_seq_cn(input bit [`CN_SEQ_W:0]     vr_poly,
                                                ref   bit [`CN_SEQ_W:0]     vr_res,
                                                input int                   vr_cn_q[],
                                                ref   int                   vr_cn);

// **************************************************************************
// function(task)   :   gen_odtu_poly
// purpose          :   gen_odtu_poly 
// author           :   shujun 00190652
// **************************************************************************
extern  static  function void   gen_odtu_poly(input int                   vr_ch_cid,
                                              ref   bit [`CN_SEQ_W:0]     vr_poly,
                                              ref   bit [`CN_SEQ_W:0]     vr_res);
// **************************************************************************
// function(task)   :   chk_odtu_seq_cn
// purpose          :   chk_odtu_seq_cn 
// author           :   shujun 00190652
// **************************************************************************
extern  static  function void   chk_odtu_seq_cn(input bit [`CN_SEQ_W:0]     vr_poly,
                                                ref   bit [`CN_SEQ_W:0]     vr_res,
                                                input int                   vr_cn_q[],
                                                input int                   vr_cn[],
                                                ref   bit                   vr_err[]);

// vmm // extern static function void chk_report_int(input vmm_log vr_log,
// vmm //                                            input string  vr_check_name,
// vmm //                                            input bit     vr_result_is_ok,
// vmm //                                            input int     vr_exp_data,
// vmm //                                            input int     vr_act_data,
// vmm //                                            input string  vr_severity = "error");
// vmm // 
// vmm // extern static function void chk_report_string(input vmm_log vr_log,
// vmm //                                               input string  vr_check_name,
// vmm //                                               input bit     vr_result_is_ok,
// vmm //                                               input string  vr_exp_data,
// vmm //                                               input string  vr_act_data,
// vmm //                                               input string  vr_severity = "error");

// **************************************************************************
// function(task)   :   crc
// purpose          :   Function for calculate all kinds of crc
// author           :   Shi Xiao Yu 00125255
// description      :   common polynomial
//                      16: CCITT 1021, OTHER 8005
//                      32: 04C11DB7
// **************************************************************************
typedef enum bit [15:0] {CRC16_CCITT = 16'h1021, CRC16_DEFAULT = 16'h8005, CRC16_SPB67 = 16'h941F} crc16_e;
typedef enum bit [31:0] {CRC32_DEFAULT = 32'h04C11DB7} crc32_e;
typedef enum bit [11:0] {CRC12_DEFAULT = 12'h80F} crc12_e;

static function bit [LENGTH -1:0] crc(bit [7:0]         vr_data[],
                                      bit [LENGTH -1:0] vr_poly,
                                      bit [LENGTH -1:0] vr_init_value = 0,
                                      bit               vr_inv = 0);

    bit [LENGTH -1:0]   vr_next_crc; // next crc
    bit [7:0]           vr_data_tmp; // tmp data
    bit                 vr_callback;

    vr_next_crc = vr_init_value;
    
    for(int i=0; i<vr_data.size; i++) begin

        vr_data_tmp = vr_data[i];

        if(vr_inv == 0) begin
            for(int j=7; j>=0; j--) begin
                vr_callback = vr_next_crc[LENGTH -1] ^ vr_data_tmp[j];
                for(int k=LENGTH -1; k>0; k--)
                    vr_next_crc[k] = vr_next_crc[k-1] ^ (vr_callback & vr_poly[k]);
                vr_next_crc[0] = vr_callback & vr_poly[0];
            end
        end
        else begin
            for(int j=0; j<=7; j++) begin
                vr_callback = vr_next_crc[LENGTH -1] ^ vr_data_tmp[j];
                for(int k=LENGTH -1; k>0; k--)
                    vr_next_crc[k] = vr_next_crc[k-1] ^ (vr_callback & vr_poly[k]);
                vr_next_crc[0] = vr_callback & vr_poly[0];
            end
        end
    end
    
    if(&vr_init_value == 1'b1) begin
        if(vr_inv == 1'b0)
            crc = ~vr_next_crc;
        else begin
            for(int i=LENGTH/8 -1; i>=0; i--) begin
                for(int j=0; j<=7; j++) begin
                    crc[8*(i+1)-j-1] = ~vr_next_crc[i*8+j];
                end
            end
        end
    end
    else
        crc = vr_next_crc;

endfunction : crc

static function bit [LENGTH -1:0] ol_crc(bit [7:0]         vr_data[],
                                         bit [LENGTH -1:0] vr_poly,
                                         bit [LENGTH -1:0] vr_init_value = 0,
                                         bit               vr_inv = 0);

    bit [LENGTH -1:0]   vr_next_crc; // next crc
    bit [7:0]           vr_data_tmp; // tmp data
    bit                 vr_callback;

    vr_next_crc = vr_init_value;
    
    for(int i=0; i<vr_data.size; i++) begin

        vr_data_tmp = vr_data[i];

        if(vr_inv == 0) begin
            for(int j=7; j>=0; j--) begin
                vr_callback = vr_next_crc[LENGTH -1] ^ vr_data_tmp[j];
                for(int k=LENGTH -1; k>0; k--)
                    vr_next_crc[k] = vr_next_crc[k-1] ^ (vr_callback & vr_poly[k]);
                vr_next_crc[0] = vr_callback & vr_poly[0];
            end
        end
        else begin
            for(int j=0; j<=7; j++) begin
                vr_callback = vr_next_crc[LENGTH -1] ^ vr_data_tmp[j];
                for(int k=LENGTH -1; k>0; k--)
                    vr_next_crc[k] = vr_next_crc[k-1] ^ (vr_callback & vr_poly[k]);
                vr_next_crc[0] = vr_callback & vr_poly[0];
            end
        end
    end
    
    ol_crc = vr_next_crc;

endfunction : ol_crc
// **************************************************************************
// function(task)   :   get_dyd_pattern
// purpose          :  
// author           :   Shi Hua 166869
// **************************************************************************
static function void get_dyd_pattern(ref bit arr[], input int level);
    bit flag;
    int len,pow;
    len = arr.size();
    if (level>0)
        pow = (1<<(level -1));
    for(int i=0;i<len;i++) begin
        if(level == 0) 
            flag = !(i%2);
        else if (pow<2*len) 
            flag = ((i/pow)%2);
        else 
            flag =1;
        arr[i] = flag;
    end

endfunction : get_dyd_pattern

// **************************************************************************
// function(task)   :   prbs_gen
// purpose          :  
// author           :   Shi Xiao Yu 125255
// **************************************************************************
static function void prbs_gen(bit [LENGTH -1:0]     vr_poly,
                              ref bit [LENGTH -1:0] vr_reg,
                              ref bit [7:0]         vr_data[],
                              input bit             vr_reverse = 0);
    
    if (vr_data.size == 0)
        vr_data = new[1];

    for(int i=0; i<vr_data.size; i++) begin
        for(int j=7; j>=0; j--) begin
            bit vr_bit_tmp;

            foreach(vr_poly[index]) begin
                vr_bit_tmp ^= (vr_poly[index] & vr_reg[index]);
            end

            vr_data[i][j]       = vr_reverse ? ~vr_reg[LENGTH -1] : vr_reg[LENGTH -1];
            vr_reg[LENGTH -1:1] = vr_reg[LENGTH -2:0];
            vr_reg[0]           = vr_bit_tmp;
        end
    end
endfunction : prbs_gen

// **************************************************************************
// function(task)   :   prbs_chk
// purpose          :  
// author           :   Shi Xiao Yu 125255
// **************************************************************************
static function void prbs_chk(bit [LENGTH -1:0]     vr_poly,
                              ref bit [LENGTH -1:0] vr_reg,
                              ref bit [7:0]         vr_data[],
                              ref bit               vr_chk[],
                              input bit             vr_reverse = 0);
    
    int vr_cnt;
    vr_chk = new[vr_data.size *8];
    
    for(int i=0; i<vr_data.size; i++) begin
        for(int j=7; j>=0; j--) begin
            bit vr_bit_tmp;

            vr_bit_tmp = vr_reverse ? ~vr_data[i][j] : vr_data[i][j];
            
            foreach(vr_poly[index]) begin
                vr_bit_tmp ^= (vr_poly[index] & vr_reg[index]);
            end

            vr_reg[LENGTH -1:1] = vr_reg[LENGTH -2:0];
            vr_reg[0]           = vr_reverse ? ~vr_data[i][j] : vr_data[i][j];
            vr_chk[vr_cnt++]    = vr_bit_tmp;
        end
    end
endfunction : prbs_chk
// **************************************************************************
// function(task)   :   prbs_bit_gen
// purpose          :  
// author           :   h00191679
// **************************************************************************
static function void prbs_bit_gen(bit [LENGTH -1:0]     vr_poly,
                                  ref bit [LENGTH -1:0] vr_reg,
                                  ref bit               vr_data[],
                                  input bit             vr_reverse = 0);
    
    if (vr_data.size == 0)
        vr_data = new[1];

    for(int i=0; i<vr_data.size; i++) begin
        bit vr_bit_tmp;

        foreach(vr_poly[index]) begin
            vr_bit_tmp ^= (vr_poly[index] & vr_reg[index]);
        end

        vr_data[i]          = vr_reverse ? ~vr_reg[LENGTH -1] : vr_reg[LENGTH -1];
        vr_reg[LENGTH -1:1] = vr_reg[LENGTH -2:0];
        vr_reg[0]           = vr_bit_tmp;
    end
endfunction : prbs_bit_gen

// **************************************************************************
// function(task)   :   prbs_bit_chk
// purpose          :  
// author           :   h00191679
// **************************************************************************
static function void prbs_bit_chk(bit [LENGTH -1:0]     vr_poly,
                                  ref bit [LENGTH -1:0] vr_reg,
                                  ref bit               vr_data[],
                                  ref bit               vr_chk[],
                                  input bit             vr_reverse = 0);
    
    int vr_cnt;
    vr_chk = new[vr_data.size];
    
    for(int i=0; i<vr_data.size; i++) begin
        bit vr_bit_tmp;

        vr_bit_tmp = vr_reverse ? ~vr_data[i] : vr_data[i];
        
        foreach(vr_poly[index]) begin
            vr_bit_tmp ^= (vr_poly[index] & vr_reg[index]);
        end

        vr_reg[LENGTH -1:1] = vr_reg[LENGTH -2:0];
        vr_reg[0]           = vr_reverse ? ~vr_data[i] : vr_data[i];
        vr_chk[vr_cnt++]    = vr_bit_tmp;
    end
endfunction : prbs_bit_chk

static function gen_ts(bit[2:0] vr_rand_mod, // 0: random; 1: even; 2: front continue; 3: back continue; 4: 1+2; 5: 1+3.
                       int      vr_total_ts, // total ts num 
                       int      vr_valid_ts, // valid ts num
                       int      vr_cpy_num,  // calender will copy by vr_cpy_num cfg
                       int      vr_cid_wid,  // cid width
                       int      vr_cid[],    // physical chan's cid
                       int      vr_ts_num[], // physical chan's ts total num
                       ref int  vr_dut_ts[], // output calender ts for dut cfg, this size equal vr_valid_ts
                       ref int  vr_env_ts[]);// output calender ts for env cfg, this size equal vr_total_ts*vr_cpy_num

    int  vr_mpi_sit[$];
    int  vr_ts_tmp[$];
    int  vr_ts_ini[];
    int  vr_ts_r[$];
    int  vr_ts_back[$];
    int  vr_chan_num;
    int  vr_index=0;
    int  vr_inval_value;
    int  vr_mpi_value;

    vr_chan_num = vr_cid.size;
    vr_inval_value = 2**vr_cid_wid - 1;
    vr_mpi_value = vr_inval_value;
    $display("======== mpi_cid ========");
    $displayh("%0h", vr_mpi_value);

    //gen mpi ts index
    for (int i=0; i < vr_total_ts; i++) begin
        if ((((vr_total_ts - vr_valid_ts) *(i+1)) % vr_total_ts) < (vr_total_ts - vr_valid_ts))
            vr_mpi_sit.push_back(i);
    end
    $display("======== mpi_sit ========");
    $display(vr_mpi_sit);

    //gen cid ts
    foreach (vr_ts_num[i]) vr_ts_num[i] = vr_ts_num[i]/vr_cpy_num;
    for (int i=0; i<vr_valid_ts; i++) vr_ts_tmp.push_back(vr_inval_value);
    for (int i=0; i<vr_chan_num; i++) begin
        for (int j=0; j<vr_ts_num[i]; j++) begin
            vr_ts_tmp[vr_index] = vr_cid[i];
            vr_index ++;
        end
    end

    //gen random or even cid ts
    if (vr_rand_mod == 0) vr_ts_tmp.shuffle();
    if (vr_rand_mod == 1) gen_even_ts(vr_ts_tmp);
    if (vr_rand_mod == 3) begin
        foreach(vr_ts_tmp[i]) vr_ts_back.push_front(vr_ts_tmp[i]);
        vr_ts_tmp = vr_ts_back;
    end
    if (vr_rand_mod == 4) begin
        vr_ts_r = vr_ts_tmp[0:(vr_ts_num.sum-1)];
        gen_even_ts(vr_ts_r);
        vr_ts_tmp[0:(vr_ts_num.sum-1)] = vr_ts_r;
    end
    if (vr_rand_mod == 5) begin
        vr_ts_r = vr_ts_tmp[0:(vr_ts_num.sum-1)];
        gen_even_ts(vr_ts_r);
        vr_ts_tmp[0:(vr_ts_num.sum-1)] = vr_ts_r;
        foreach(vr_ts_tmp[i]) vr_ts_back.push_front(vr_ts_tmp[i]);
        vr_ts_tmp = vr_ts_back;
    end

    //gen dut_ts
    vr_dut_ts = vr_ts_tmp;
    //$display("======== dut_ts  ========");
    //$displayh(vr_dut_ts);
    $display(ovpm::psarray_int("", vr_dut_ts, "%m.dut_ts\n", vr_dut_ts.size));

    //insert mpi ts
    vr_ts_ini = new[vr_total_ts];
    foreach (vr_ts_ini[i]) begin
        if (i inside vr_mpi_sit) vr_ts_ini[i] = vr_mpi_value;
        else vr_ts_ini[i] = vr_ts_tmp.pop_front();
    end
    vr_env_ts = new[vr_total_ts*vr_cpy_num];
    foreach (vr_env_ts[i]) vr_env_ts[i] = vr_ts_ini[i%vr_total_ts];

    //$display("======== env_ts  ========");
    //$displayh(vr_env_ts);
    $display(ovpm::psarray_int("", vr_env_ts, "%m.env_ts\n", vr_env_ts.size));
endfunction: gen_ts

static function gen_even_ts(ref int vr_ts[$]);
    int    i_ts[];
    int    o_ts[];
    int    o_ts_q[$];
    int    vr_cid_tmp[$];
    int    vr_cid[$];
    int    vr_num[];
    int    vr_num_tmp[];
    int    vr_index[$];
    int    vr_num_data[];
    int    vr_pos_vld[];
    int    vr_pos_dis[$];
    int    vr_shift;
    int    p;
    int    c;

    if (vr_ts.size == 0) $display("Input ts must be not null !!");
    else i_ts = vr_ts;
    
    foreach (i_ts[i]) begin
        if ((i_ts[i] inside vr_cid_tmp) == 0) begin
            vr_cid_tmp.push_back(i_ts[i]);
        end
    end

    vr_num = new[vr_cid_tmp.size];
    vr_num_tmp = new[vr_cid_tmp.size];
    foreach (vr_cid_tmp[i]) begin
        foreach (i_ts[j]) begin
            if (i_ts[j] == vr_cid_tmp[i]) begin
                vr_num[i]++;
                vr_num_tmp[i]++;
            end
        end
    end

    // queue by ts_num from high to low
    vr_num.rsort();
    foreach (vr_num[i]) begin
        for (int j=0; j<vr_num.size; j++) begin
            if (vr_num_tmp[j] == vr_num[i]) begin
                vr_index.push_back(j);
                vr_num_tmp[j] = 0;
            end
        end
    end

    for (int i=0; i<vr_num.size; i++) begin
        vr_cid.push_back(vr_cid_tmp[vr_index.pop_front()]);
    end

    //sigma-delta
    p = i_ts.size;
    o_ts = new[p];
    vr_pos_vld = new[p];
    foreach (vr_pos_vld[i]) vr_pos_vld[i] = i;
    for (int i=0; i<vr_num.size; i++) begin
        c = vr_num[i];
        for (int j=0; j<p; j++) begin
            if ((((j+1)*c)%p) < c) begin
                o_ts[vr_pos_vld[j]] = vr_cid[i];
            end
            else begin
                vr_pos_dis.push_back(vr_pos_vld[j]);
            end
        end

        vr_pos_vld = new[p-c];
        foreach (vr_pos_vld[m]) vr_pos_vld[m] = vr_pos_dis[m];
        vr_pos_dis.delete();

        p = p - c;
    end

    o_ts_q = o_ts;
    vr_shift = $urandom_range(0, (o_ts_q.size -1));
    if (vr_shift == 0) vr_ts = o_ts_q;
    else vr_ts = {o_ts_q[vr_shift:$],o_ts_q[0:(vr_shift-1)]};

endfunction: gen_even_ts

endclass

function string ovpm::psarray_byte(string    vr_name,
                                   bit [7:0] vr_list[],
                                   string    prefix,
                                   int       vr_length);

    psarray_byte = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_byte,"%s %-20s : %4d. %2h\n",psarray_byte,vr_name,i,vr_list[i]);
                else
                    $sformat(psarray_byte,"%s %-20s : %4d. %2h",psarray_byte,vr_name,i,vr_list[i]);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_byte,"%s %-20s   %4d. %2h\n",psarray_byte,"",i,vr_list[i]);
            else
                $sformat(psarray_byte,"%s %-20s   %4d. %2h",psarray_byte,"",i,vr_list[i]);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_byte,"%s %2h\n",psarray_byte,vr_list[i]);
            else
                $sformat(psarray_byte,"%s %2h",psarray_byte,vr_list[i]);
        end
        if(i%16==15)
            $sformat(psarray_byte,"%s %2h\n",psarray_byte,vr_list[i]);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_byte

function string ovpm::psarray_byte_q(string      vr_name,
                                     bit [7:0]   vr_list[$],
                                     string      vr_prefix,
                                     int         vr_length);

    psarray_byte_q = vr_prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_byte_q,"%s %-20s : %04d. %h\n",psarray_byte_q,vr_name,i,vr_list[i]);
                else
                    $sformat(psarray_byte_q,"%s %-20s : %04d. %h",psarray_byte_q,vr_name,i,vr_list[i]);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_byte_q,"%s %-20s   %04d. %h\n",psarray_byte_q,"",i,vr_list[i]);
            else
                $sformat(psarray_byte_q,"%s %-20s   %04d. %h",psarray_byte_q,"",i,vr_list[i]);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_byte_q,"%s %h\n",psarray_byte_q,vr_list[i]);
            else
                $sformat(psarray_byte_q,"%s %h",psarray_byte_q,vr_list[i]);
        end
        if(i%16==15)
            $sformat(psarray_byte_q,"%s %h\n",psarray_byte_q,vr_list[i]);
        if(i== vr_length -1) 
            break;
    end

endfunction: psarray_byte_q


function string ovpm::psarray_int(string vr_name,
                                  int    vr_list[],
                                  string prefix,
                                  int    vr_length);

    psarray_int = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_int,"%s %-20s : %4d. %3h\n",psarray_int,vr_name,i,vr_list[i]);
                else
                    $sformat(psarray_int,"%s %-20s : %4d. %3h",psarray_int,vr_name,i,vr_list[i]);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_int,"%s %-20s   %4d. %3h\n",psarray_int,"",i,vr_list[i]);
            else
                $sformat(psarray_int,"%s %-20s   %4d. %3h",psarray_int,"",i,vr_list[i]);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_int,"%s %3h\n",psarray_int,vr_list[i]);
            else
                $sformat(psarray_int,"%s %3h",psarray_int,vr_list[i]);
        end
        if(i%16==15)
            $sformat(psarray_int,"%s %3h\n",psarray_int,vr_list[i]);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_int

function string ovpm::psarray_bit(string vr_name,
                                  bit    vr_list[],
                                  string prefix,
                                  int    vr_length);

    psarray_bit = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%32==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_bit,"%s %-10s : %4d. %h\n",psarray_bit,vr_name,i,vr_list[i]);
                else
                    $sformat(psarray_bit,"%s %-10s : %4d. %h"  ,psarray_bit,vr_name,i,vr_list[i]);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_bit,"%s %-10s   %4d. %h\n",psarray_bit,"",i,vr_list[i]);
            else
                $sformat(psarray_bit,"%s %-10s   %4d. %h"  ,psarray_bit,"",i,vr_list[i]);
        end
        if((i%32>0)&&(i%32<31)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_bit,"%s %h\n",psarray_bit,vr_list[i]);
            else
                $sformat(psarray_bit,"%s %h"  ,psarray_bit,vr_list[i]);
        end
        if(i%32==31)
            $sformat(psarray_bit,"%s %h\n"    ,psarray_bit,vr_list[i]);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_bit

function string ovpm::psarray_bit_q(string     vr_name,
                                    bit        vr_list[$],
                                    string     vr_prefix,
                                    int        vr_length);

    psarray_bit_q = vr_prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_bit_q,"%s %-20s : %4d. %h\n",psarray_bit_q,vr_name,i,vr_list[i]);
                else
                    $sformat(psarray_bit_q,"%s %-20s : %4d. %h",psarray_bit_q,vr_name,i,vr_list[i]);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_bit_q,"%s %-20s   %4d. %h\n",psarray_bit_q,"",i,vr_list[i]);
            else
                $sformat(psarray_bit_q,"%s %-20s   %4d. %h",psarray_bit_q,"",i,vr_list[i]);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_bit_q,"%s %h\n",psarray_bit_q,vr_list[i]);
            else
                $sformat(psarray_bit_q,"%s %h",psarray_bit_q,vr_list[i]);
        end
        if(i%16==15)
            $sformat(psarray_bit_q,"%s %h\n",psarray_bit_q,vr_list[i]);
        if(i== vr_length -1) 
            break;
    end

endfunction: psarray_bit_q

function string ovpm::psarray_frame(string        vr_name,
                                    ovpt::frame_e vr_list[],
                                    string        prefix,
                                    int           vr_length);

    psarray_frame = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_frame,"%s %-20s : %4d. %s\n",psarray_frame,vr_name,i,vr_list[i].name);
                else
                    $sformat(psarray_frame,"%s %-20s : %4d. %s",psarray_frame,vr_name,i,vr_list[i].name);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_frame,"%s %-20s   %4d. %s\n",psarray_frame,"",i,vr_list[i].name);
            else
                $sformat(psarray_frame,"%s %-20s   %4d. %s",psarray_frame,"",i,vr_list[i].name);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_frame,"%s %s\n",psarray_frame,vr_list[i].name);
            else
                $sformat(psarray_frame,"%s %s",psarray_frame,vr_list[i].name);
        end
        if(i%16==15)
            $sformat(psarray_frame,"%s %s\n",psarray_frame,vr_list[i].name);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_frame

function string ovpm::psarray_otu_map_mode(string               vr_name,
                                           ovpt::otu_map_mode_e vr_list[],
                                           string               prefix,
                                           int                  vr_length);

    psarray_otu_map_mode = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_otu_map_mode,"%s %-20s : %4d. %s\n",psarray_otu_map_mode,vr_name,i,vr_list[i].name);
                else
                    $sformat(psarray_otu_map_mode,"%s %-20s : %4d. %s",psarray_otu_map_mode,vr_name,i,vr_list[i].name);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_otu_map_mode,"%s %-20s   %4d. %s\n",psarray_otu_map_mode,"",i,vr_list[i].name);
            else
                $sformat(psarray_otu_map_mode,"%s %-20s   %4d. %s",psarray_otu_map_mode,"",i,vr_list[i].name);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_otu_map_mode,"%s %s\n",psarray_otu_map_mode,vr_list[i].name);
            else
                $sformat(psarray_otu_map_mode,"%s %s",psarray_otu_map_mode,vr_list[i].name);
        end
        if(i%16==15)
            $sformat(psarray_otu_map_mode,"%s %s\n",psarray_otu_map_mode,vr_list[i].name);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_otu_map_mode

function string ovpm::psarray_cbyte_adjust(string               vr_name,
                                           ovpt::cbyte_adjust_e vr_list[],
                                           string               prefix,
                                           int                  vr_length);

    psarray_cbyte_adjust = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_cbyte_adjust,"%s %-20s : %4d. %s\n",psarray_cbyte_adjust,vr_name,i,vr_list[i].name);
                else
                    $sformat(psarray_cbyte_adjust,"%s %-20s : %4d. %s",psarray_cbyte_adjust,vr_name,i,vr_list[i].name);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_cbyte_adjust,"%s %-20s   %4d. %s\n",psarray_cbyte_adjust,"",i,vr_list[i].name);
            else
                $sformat(psarray_cbyte_adjust,"%s %-20s   %4d. %s",psarray_cbyte_adjust,"",i,vr_list[i].name);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_cbyte_adjust,"%s %s\n",psarray_cbyte_adjust,vr_list[i].name);
            else
                $sformat(psarray_cbyte_adjust,"%s %s",psarray_cbyte_adjust,vr_list[i].name);
        end
        if(i%16==15)
            $sformat(psarray_cbyte_adjust,"%s %s\n",psarray_cbyte_adjust,vr_list[i].name);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_cbyte_adjust

function string ovpm::psarray_jc_adjust(string            vr_name,
                                        ovpt::jc_adjust_e vr_list[],
                                        string            prefix,
                                        int               vr_length);

    psarray_jc_adjust = prefix;

    if( ( vr_length <= 0 ) || ( vr_length > vr_list.size ) )
        vr_length = vr_list.size;

    foreach(vr_list[i]) begin
        if(i%16==0) begin
            if(i==0) begin
                if(i==vr_list.size()-1)
                    $sformat(psarray_jc_adjust,"%s %-20s : %4d. %s\n",psarray_jc_adjust,vr_name,i,vr_list[i].name);
                else
                    $sformat(psarray_jc_adjust,"%s %-20s : %4d. %s",psarray_jc_adjust,vr_name,i,vr_list[i].name);
            end
            else if(i==vr_list.size()-1)
                $sformat(psarray_jc_adjust,"%s %-20s   %4d. %s\n",psarray_jc_adjust,"",i,vr_list[i].name);
            else
                $sformat(psarray_jc_adjust,"%s %-20s   %4d. %s",psarray_jc_adjust,"",i,vr_list[i].name);
        end
        if((i%16>0)&&(i%16<15)) begin
            if(i==vr_list.size()-1)
                $sformat(psarray_jc_adjust,"%s %s\n",psarray_jc_adjust,vr_list[i].name);
            else
                $sformat(psarray_jc_adjust,"%s %s",psarray_jc_adjust,vr_list[i].name);
        end
        if(i%16==15)
            $sformat(psarray_jc_adjust,"%s %s\n",psarray_jc_adjust,vr_list[i].name);
        if(i== vr_length -1) 
            break;
    end

endfunction : psarray_jc_adjust

function bit ovpm::cmp_array2byte(ref bit[7:0]   vr_array [],
                                  input int      vr_start,
                                  input int      vr_end,
                                  input bit[7:0] vr_cmp_byte);
    if (vr_end < vr_start) begin
        $display("OVPM::cmp_array2byte() : received an error input : vr_start: %0d, vr_end: %0d",vr_start,vr_end);
    end
    for (int i=vr_start; i<vr_end ; i++) begin
        if (vr_array[i] != vr_cmp_byte) begin
            return 0;
        end
    end 
    return 1;
endfunction : cmp_array2byte

function bit ovpm::cmp_array2double_byte(ref bit[7:0]    vr_array [],
                                         input int       vr_start,
                                         input int       vr_end,
                                         input bit[15:0] vr_cmp_double_byte);
    if (vr_end < vr_start) begin
        $display("OVPM::cmp_array2double_byte() : received an error input : vr_start: %0d, vr_end: %0d",vr_start,vr_end);
    end
    for (int i=vr_start; i<(vr_end-1) ; i=i+2) begin
        if ((vr_array[i] != vr_cmp_double_byte[15:8]) || (vr_array[i+1] != vr_cmp_double_byte[7:0])) begin
            return 0;
        end
    end 
    return 1;
endfunction : cmp_array2double_byte

function bit ovpm::cmp_queue2byte(ref bit[7:0]   vr_queue [$],
                                  input int      vr_start,
                                  input int      vr_end,
                                  input bit[7:0] vr_cmp_byte);
    if (vr_end < vr_start) begin
        $display("OVPM::cmp_queue2byte() : received an error input : vr_start: %0d, vr_end: %0d",vr_start,vr_end);
    end
    for (int i=vr_start; i<vr_end ; i++) begin
        if (vr_queue[i] != vr_cmp_byte) begin
            return 0;
        end
    end 
    return 1;
endfunction : cmp_queue2byte


function void ovpm::byte_array_cut(ref bit[7:0] vr_array [],
                                   input int    vr_start,
                                   input int    vr_end);
    int vr_len = vr_end - vr_start + 1;
    for (int i=0; i <vr_len; i++) begin
        vr_array[i] = vr_array[i + vr_start];
    end
    vr_array = new[vr_len](vr_array);    
endfunction : byte_array_cut

function void ovpm::bit_array_cut(ref bit   vr_array [],
                                  input int vr_start,
                                  input int vr_end);
    int vr_len = vr_end - vr_start + 1;
    for (int i=0; i <vr_len; i++) begin
        vr_array[i] = vr_array[i + vr_start];
    end
    vr_array = new[vr_len](vr_array);    
endfunction : bit_array_cut

function void ovpm::byte_array_joint(ref bit[7:0] vr_array1 [],
                                     ref bit[7:0] vr_array2 []);
    if (vr_array2.size != 0) begin
        int vr_array1_size = vr_array1.size;
        vr_array1 = new[vr_array1.size + vr_array2.size](vr_array1);
        foreach (vr_array2[i]) begin
            vr_array1[vr_array1_size + i] = vr_array2[i]; 
        end 
    end

endfunction : byte_array_joint

function int ovpm::byte_array_compare_bit(ref bit[7:0] vr_array1 [],
                                          ref bit[7:0] vr_array2 [],
                                          input int    vr_start,
                                          input int    vr_end);
    int vr_err_cnt;
    for (int i=vr_start; i<= vr_end; i++) begin
        if (vr_array1[i] != vr_array2[i] ) begin
            bit[7:0] vr_byte_err =  vr_array1[i] ^ vr_array2[i];
            for (int j=0; j<8 ; j++) begin
                vr_err_cnt = vr_err_cnt + vr_byte_err[j];
            end 
        end
    end 
    return vr_err_cnt;

endfunction : byte_array_compare_bit

function void ovpm::fix_rate_err_ins(ref bit[7:0] vr_bytes [],
                                     ref int      vr_cycle_count, 
                                     ref int      vr_total_num, 
                                     input int    vr_err_cycle,
                                     input int    vr_err_num,
                                     input int    vr_offset = 0);
    if (vr_err_num > vr_err_cycle*8 ) begin
        $display("ERROR, It is impossible to insert %0d error in only %0d bytes!",vr_err_num, vr_err_cycle);
        $finish;
    end
    if ((vr_err_cycle > 0) && (vr_err_num > 0) && (vr_total_num != 0)) begin
        int vr_err_byte = vr_err_num/8;
        int vr_err_bit  = vr_err_num%8;
        for (int i=vr_offset; i<vr_bytes.size ; i++) begin
            int vr_temp_err_cnt;
            if (vr_cycle_count < vr_err_byte)    vr_temp_err_cnt = 8;
            if (vr_cycle_count == vr_err_byte)   vr_temp_err_cnt = vr_err_bit;
      
            for (int k=0; k<vr_temp_err_cnt ; k++) begin
                vr_bytes[i][k] = ~ vr_bytes[i][k]; 
                if (vr_total_num > 0)  vr_total_num --;
                if (vr_total_num == 0) begin
                    vr_cycle_count = 0;
                    return;
                end ;
            end 
            vr_cycle_count ++;
            if (vr_cycle_count >= vr_err_cycle) begin 
                vr_cycle_count = 0; 
            end
        end 
    end               

endfunction : fix_rate_err_ins

function void ovpm::fix_rate_err_ins_avge(ref bit[7:0] vr_bytes [],
                                          ref int      vr_cycle_count, // count for the err cycle
                                          ref int      vr_total_num,   // total error num, -1 means constant insert
                                          input int    vr_err_cycle,
                                          input int    vr_err_num,
                                          input int    vr_offset = 0);
    if (vr_err_num > vr_err_cycle * 8 ) begin
        $display("ERROR, It is impossible to insert %0d error in only %0d bytes!",vr_err_num, vr_err_cycle);
        $finish;
    end
    if ((vr_err_cycle > 0) && (vr_err_num > 0) && (vr_total_num != 0)) begin
        real vr_err_avg ;
        real vr_err_remain;
        vr_err_avg = ($itor(vr_err_num) / $itor(vr_err_cycle));
        vr_err_remain = 0.0;
        ////$display("vr_err_cycle = %4d, vr_err_num = %4d, vr_total_num = %4d, vr_bytes.size = %4d, vr_err_avg = %f"
        ////        , vr_err_cycle, vr_err_num, vr_total_num, vr_bytes.size, vr_err_avg);
        for (int i = vr_offset; i < vr_bytes.size ; i ++) begin
            int vr_temp_err_cnt;
            vr_err_remain = vr_err_remain + vr_err_avg;
            ////$display("sum vr_err_remain = %f", vr_err_remain);
            vr_temp_err_cnt = $rtoi(vr_err_remain);
            vr_err_remain = vr_err_remain - $itor(vr_temp_err_cnt);
            ////$display("i = %4d, vr_temp_err_cnt = %4d, vr_err_remain = %f, vr_bytes[%4d] = %2h", i, vr_temp_err_cnt, vr_err_remain, i, vr_bytes[i]);
            for (int k = 0; k < vr_temp_err_cnt ; k ++) begin
                vr_bytes[i][k] = (~(vr_bytes[i][k]));
                if (vr_total_num > 0)  vr_total_num --;
                if (vr_total_num == 0) begin
                    vr_cycle_count = 0;
                    return;
                end ;
            end 
            vr_cycle_count ++;
            if (vr_cycle_count >= vr_err_cycle) begin 
                vr_cycle_count = 0; 
            end
            ////$display("vr_bytes[%4d] = %2h after insert error!", i, vr_bytes[i]);
        end
    end

endfunction : fix_rate_err_ins_avge

function void ovpm::byte_array_bit_adjust(ref bit[7:0] vr_array [],
                                          input int    vr_bit_order,
                                          ref bit[7:0] vr_remain_data);
    bit[7:0]  vr_store = vr_array[vr_array.size - 1];   
    bit[16:0] vr_temp = {8'h0 ,vr_store};
    for (int i= vr_array.size -1 ; i>0 ; i--) begin
        vr_temp[15:8] = vr_array[i-1];
        vr_array[i] = vr_temp[15-vr_bit_order -:8];
        vr_temp = vr_temp >> 8;
    end 
    vr_temp[15:8] = vr_remain_data;
    vr_array[0] = vr_temp[15-vr_bit_order -:8];    
    vr_remain_data = vr_store;

endfunction : byte_array_bit_adjust

function void ovpm::scrm(bit [LENGTH -1:0] vr_poly,
                     ref bit [LENGTH -1:0] vr_scrm_reg,
                     ref bit [7:0]         vr_data[],
                   input bit               vr_mode,
                   input int               vr_start_pos,
                   input int               vr_end_pos,
                   input bit               vr_x1_use);

    int         vr_sta_ind;
    int         vr_end_ind;
    bit [7:0]   vr_data_tmp;
    bit         vr_bit_tmp;

    if(vr_start_pos <= 0)
        vr_sta_ind = 0;
    else
        vr_sta_ind = vr_start_pos;

    if(vr_end_pos <= 0 || vr_end_pos < vr_sta_ind)
        vr_end_ind = vr_data.size -1;
    else
        vr_end_ind = vr_end_pos;

    if(vr_mode == 0) begin
        for(int i=vr_sta_ind; i<=vr_end_ind; i++) begin
            vr_data_tmp = vr_data[i];
            for(int j=7; j>=0; j--) begin
                foreach(vr_poly[index]) begin
                    if((vr_x1_use == 0) && (index == 0))
                        continue;
                    vr_data_tmp[j] = vr_data_tmp[j] ^ ( vr_poly[index] & vr_scrm_reg[index] );
                end
                vr_scrm_reg = {vr_scrm_reg[LENGTH -2:0],vr_data_tmp[j]};
            end

            vr_data[i] = vr_data_tmp;
        end
    end
    else begin
        for(int i=vr_sta_ind; i<=vr_end_ind; i++) begin
            vr_data_tmp = vr_data[i];
            for(int j=7; j>=0; j--) begin
                vr_data_tmp[j] = vr_data_tmp[j] ^ vr_scrm_reg[LENGTH -1];
                vr_bit_tmp = 0;
                foreach(vr_poly[index]) begin
                    if((vr_x1_use == 0) && (index == 0))
                        continue;
                    vr_bit_tmp = vr_bit_tmp ^ ( vr_poly[index] & vr_scrm_reg[index] );
                end
                vr_scrm_reg = {vr_scrm_reg[LENGTH -2:0],vr_bit_tmp};
            end

            vr_data[i] = vr_data_tmp;
        end
    end

endfunction : scrm

function void ovpm::descrm(bit [LENGTH -1:0] vr_poly,
                       ref bit [LENGTH -1:0] vr_descrm_reg,
                       ref bit [7:0]         vr_data[],
                     input bit               vr_mode,
                     input int               vr_start_pos,
                     input int               vr_end_pos,
                     input bit               vr_x1_use);
    
    int         vr_sta_ind;
    int         vr_end_ind;
    bit [7:0]   vr_data_tmp;
    bit         vr_bit_tmp;

    if(vr_start_pos <= 0)
        vr_sta_ind = 0;
    else
        vr_sta_ind = vr_start_pos;

    if(vr_end_pos <= 0 || vr_end_pos < vr_sta_ind)
        vr_end_ind = vr_data.size -1;
    else
        vr_end_ind = vr_end_pos;

    if(vr_mode == 0) begin
        for(int i=vr_sta_ind; i<=vr_end_ind; i++) begin
            vr_data_tmp = vr_data[i];
            for(int j=7; j>=0; j--) begin
                vr_bit_tmp = vr_data_tmp[j];
                foreach(vr_poly[index]) begin
                    if((vr_x1_use == 0) && (index == 0))
                        continue;
                    vr_bit_tmp = vr_bit_tmp ^ ( vr_poly[index] & vr_descrm_reg[index] );
                end
                vr_descrm_reg = {vr_descrm_reg[LENGTH -2:0],vr_data_tmp[j]};
                vr_data_tmp[j] = vr_bit_tmp;
            end

            vr_data[i] = vr_data_tmp;
        end
    end
    else begin
        for(int i=vr_sta_ind; i<=vr_end_ind; i++) begin
            vr_data_tmp = vr_data[i];
            for(int j=7; j>=0; j--) begin
                vr_data_tmp[j] = vr_data_tmp[j] ^ vr_descrm_reg[LENGTH -1];
                vr_bit_tmp = 0;
                foreach(vr_poly[index]) begin
                    if((vr_x1_use == 0) && (index == 0))
                        continue;
                    vr_bit_tmp = vr_bit_tmp ^ ( vr_poly[index] & vr_descrm_reg[index] );
                end
                vr_descrm_reg = {vr_descrm_reg[LENGTH -2:0],vr_bit_tmp};
            end

            vr_data[i] = vr_data_tmp;
        end
    end

endfunction : descrm

function void ovpm::gen_prbs31_data(ref   bit [30:0]   vr_prbs31_ini_data,
                                    input int          vr_length,
                                    ref   bit [7:0]    vr_data[],
                                    input int unsigned vr_offset = 0);
    // to ensure the output is not all-0
    if (vr_prbs31_ini_data == 'h0) begin
         vr_prbs31_ini_data = 'h7fff_ffff;
    end
    if (vr_data.size > vr_length + vr_offset) begin
        $display("Warning! when try to prbs31 data, the input parameter is \
                  length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", vr_length, vr_offset, vr_data.size);
    end
    if (vr_data.size < vr_length + vr_offset) begin
        vr_data = new[vr_offset + vr_length](vr_data);
    end

    for (int i = vr_offset; i< vr_offset + vr_length ; i++) begin
        vr_data[i] = vr_prbs31_ini_data[30 -:8];
        for (int j=0; j<8 ; j++) begin
            vr_prbs31_ini_data = {vr_prbs31_ini_data[29:0], (vr_prbs31_ini_data[30] ^ vr_prbs31_ini_data[27]) };
        end 
    end     

endfunction : gen_prbs31_data


function void ovpm::gen_pattern_data(input bit [15:0]    vr_err_pattern,
                                     input bit [15:0]    vr_exp_pattern,
                                     input int           vr_length,
                                     input int           vr_err_start_bytes,
                                     ref   bit [7:0]     vr_data[],
                                     ref   int           vr_err_num
                                   );

    int rd ;

    rd =vr_err_start_bytes;
    if (vr_data.size > vr_length*2 ) begin
         $display("Warning! when try to pattern data, the input parameter is \
                  length:%0d,   data.size:%0d. Do you really want to do this?", vr_length, vr_data.size);
    end

    if (vr_data.size < vr_length*2 ) begin
        vr_data = new[vr_length*2](vr_data);
    end
    for (int i = 0; i<rd*2; i=i+2) begin
        vr_data[i]       = vr_exp_pattern[15:8];
        vr_data[i+1]     = vr_exp_pattern[7:0];
    end
    for (int i = rd*2; i< vr_length*2 + rd*2; i=i+2) begin
        begin
            if (vr_err_num >0) begin
                vr_data[i]       = vr_err_pattern[15:8];
                vr_data[i+1]     = vr_err_pattern[7:0];
                vr_err_num--;
                if (vr_err_num < 0) begin
                    $display("Warning! The err_num in pattern insert deincr to 0!");
                    vr_err_num = 0;
                end
            end
            else if (vr_err_num<0) begin
                vr_data[i]       = vr_err_pattern[15:8];
                vr_data[i+1]     = vr_err_pattern[7:0];
            end
            else begin
                vr_data[i]       = vr_exp_pattern[15:8];
                vr_data[i+1]     = vr_exp_pattern[7:0];
            end

        end
    end     

endfunction : gen_pattern_data

function void ovpm::gen_pn11_data(ref   bit [10:0]   vr_pn11_ini_data,
                                  input int          vr_length,
                                  ref   bit [7:0]    vr_data[],
                                  input int unsigned vr_offset = 0);
    // to ensure the output is not all-0
    if (vr_pn11_ini_data == 'h0) begin
         vr_pn11_ini_data = 'h7ff;
    end
    if (vr_data.size > vr_length + vr_offset) begin
        $display("Warning! when try to pn11 data, the input parameter is \
                  length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", vr_length, vr_offset, vr_data.size);
    end
    if (vr_data.size < vr_length + vr_offset) begin
        vr_data = new[vr_offset + vr_length](vr_data);
    end

    for (int i = vr_offset; i< vr_offset + vr_length ; i++) begin
        vr_data[i] = vr_pn11_ini_data[10 -:8];
        for (int j=0; j<8 ; j++) begin
            vr_pn11_ini_data = {vr_pn11_ini_data[9:0], (vr_pn11_ini_data[10] ^ vr_pn11_ini_data[8]) };
        end 
    end     

endfunction : gen_pn11_data

function void ovpm::pn11_data_check(ref bit        vr_pn11_is_sync,
                                    ref bit [10:0] vr_pn11_ini_data,
                                    ref bit [7:0]  vr_data[]);
    bit[7:0]  vr_pn11_byte;           
    if (vr_pn11_is_sync == 0) begin
        vr_pn11_ini_data = {vr_data[0],vr_data[1][7:5]};
    end
    if (vr_pn11_ini_data == 'h0) begin
        vr_pn11_is_sync = 0;
        return;
    end
    foreach (vr_data[i]) begin
        vr_pn11_byte = vr_pn11_ini_data[10 -:8];
        for (int j=0; j<8 ; j++) begin
            vr_pn11_ini_data = {vr_pn11_ini_data[9:0], (vr_pn11_ini_data[10] ^ vr_pn11_ini_data[8]) };
        end 
        if (vr_data[i] != vr_pn11_byte) begin
            vr_pn11_is_sync = 0;
            return;
        end
    end 
    vr_pn11_is_sync = 1;
endfunction : pn11_data_check 

function real ovpm::get_simtime(string unit = "ns");
        real   pow;
        string str;
        real   rvalue;
        int    relsult;
        case (unit)
            "fs":    pow =1.0;
            "ps":    pow =1.0e3;
            "ns":    pow =1.0e6;
            "us":    pow =1.0e9;
            "ms":    pow =1.0e12;
            "s":     pow =1.0e15;
            "m":     pow =6.0e16;
            "h":     pow =3.6e18;
            default  pow = -1000;
        endcase
        if (pow < 0)  begin
            return pow;
        end
        $timeformat(-15,0,"fs",30);
        //$timeformat(-9,3,"",5);
        $sformat(str,"%t",$realtime);
        //$display("real=%d,str=%s",$realtime,str); 
        relsult=$sscanf(str,"%f",rvalue);
        rvalue = rvalue/pow;
        return rvalue;
endfunction : get_simtime

task ovpm::ovp_delay_ns(input real delay, input bit vr_print);
    longint unsigned  m_end_time,m_star_time,v_stand;    
    static  bit isstart=0;
    static  real m_unit=0;
    if (isstart==0)  begin
        m_star_time=get_simtime("fs");
        #1;
        m_end_time=get_simtime("fs");
        v_stand = (m_end_time-m_star_time);
        if ((v_stand==0)|(v_stand>=10000000)) begin
            $display("Error:%m timescale error:");
            $display("unit/percision must be 1ns/100ps/10ps/1ps/100fs/10fs/1fs");
            $finish;
            return;
        end
        if (v_stand>=1000000)      m_unit=1e6;//ns
        else if (v_stand>=100000)  m_unit=1e5;//100ps
        else if (v_stand>=10000)   m_unit=1e4;//10ps
        else if (v_stand>=1000)    m_unit=1e3;//ps
        else if (v_stand>=100)     m_unit=1e2;//100fs
        else if (v_stand>=10)      m_unit=1e1;//10fs
        else if (v_stand>=1)       m_unit=1;//fs
        isstart =1;
        
        #((delay-m_unit/1e6)*1e6/m_unit);
        $display("fb_delay %0d ns",delay);
    end 
    else begin    
        #(delay*1e6/m_unit);
        if (vr_print == 1) begin
            $display("ovp_delay %0d ns",delay);
        end
    end

endtask : ovp_delay_ns

task ovpm::ovp_delay_us(input real delay, input bit vr_print);
    ovp_delay_ns(delay*1e3, vr_print);
endtask : ovp_delay_us

task ovpm::ovp_delay_ms(input real delay, input bit vr_print);
    ovp_delay_ns(delay*1e6, vr_print);
endtask : ovp_delay_ms

task ovpm::field_check(ref    uvm_reg_field                   vr_field,
                       input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data,
                       output bit                             vr_result_is_ok,
                       input  int                             vr_frm_cnt,
                       input  int                             vr_stream_id,
                       input  int                             vr_scnr_num,
                       input  bit                             vr_print_mode);
    uvm_status_e  vr_status;
    bit   [`OVPM_MPI_DATA_WIDTH - 1:0]      vr_dout;
    
    vr_field.read(vr_status, vr_dout);

    if (vr_dout != vr_exp_data) begin
        if (vr_print_mode == 1) begin
            `uvm_error(vr_field.get_type_name(), $psprintf("Sub [%0d], Frm [%0d],Scnr [%0d]", vr_stream_id,vr_frm_cnt,vr_scnr_num));
        end
        `uvm_error(vr_field.get_type_name(),$psprintf("Register \"%s\" value read from DUT (0x%h) does not match expected value (0x%h)", vr_field.get_name(), vr_dout, vr_exp_data));
        vr_result_is_ok = 0;
    end
    else begin
        if (vr_print_mode == 1) begin
            `uvm_info(vr_field.get_type_name(),$psprintf("Sub [%0d], Frm_cnt ( %0d),Scnr (%0d)",vr_stream_id,vr_frm_cnt,vr_scnr_num),UVM_NONE);
        end
        `uvm_info(vr_field.get_type_name(),$psprintf("OK! Register \"%s\" value equal to expected value (0x%h)",vr_field.get_name(),vr_exp_data),UVM_NONE);
        vr_result_is_ok = 1;
    end

endtask : field_check

task ovpm::rc_field_check(ref    uvm_reg_field                   vr_field,
                          input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data1,
                          input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data2,
                          output bit                             vr_result_is_ok,
                          input  int                             vr_frm_cnt,
                          input  int                             vr_stream_id,
                          input  int                             vr_scnr_num,
                          input  bit                             vr_print_mode
                         );
    bit vr_result1;
    bit vr_result2;
    
    field_check(vr_field, vr_exp_data1, vr_result1,vr_frm_cnt,vr_stream_id,vr_scnr_num,vr_print_mode);
    field_check(vr_field, vr_exp_data2, vr_result2,vr_frm_cnt,vr_stream_id,vr_scnr_num,vr_print_mode);
    
    vr_result_is_ok = vr_result1 && vr_result2;

endtask : rc_field_check

task ovpm::reg_check(input  uvm_reg                         vr_reg,
                     input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data,
                     output bit                             vr_result_is_ok);
    uvm_status_e  vr_status;
    bit   [`OVPM_MPI_DATA_WIDTH - 1:0]      vr_dout;
    
    vr_reg.read(vr_status, vr_dout);

    if (vr_dout != vr_exp_data) begin
        `uvm_error(vr_reg.get_type_name(),$psprintf("Register \"%s\" value read from DUT (0x%h) does not match expected value (0x%h)",vr_reg.get_name(),vr_dout, vr_exp_data) );
        vr_result_is_ok = 0;
    end
    else begin
        `uvm_info(vr_reg.get_type_name(),$psprintf("OK! Register \"%s\" value equal to expected value (0x%h)",vr_reg.get_name(),vr_exp_data),UVM_NONE);
        vr_result_is_ok = 1;
    end

endtask : reg_check

task ovpm::rc_reg_check(input  uvm_reg                         vr_reg,
                        input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data1,
                        input  bit [`OVPM_MPI_DATA_WIDTH -1:0] vr_exp_data2,
                        output bit                             vr_result_is_ok);
    bit vr_result1;
    bit vr_result2;
    
    reg_check(vr_reg, vr_exp_data1, vr_result1);
    reg_check(vr_reg, vr_exp_data2, vr_result2);
    vr_result_is_ok = vr_result1 && vr_result2;

endtask : rc_reg_check

task ovpm::check_reg(uvm_reg                          vr_reg,
                     bit [`OVPM_MPI_DATA_WIDTH - 1:0] exp = 'h0,
                     bit [`OVPM_MPI_DATA_WIDTH - 1:0] msk = 'h0,
                     bit                              vr_chk = 1);

    uvm_reg_field                            vr_fields[$];
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_rdata;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_exp;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_act;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_exp_msk;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_act_msk;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         vr_msk;
    int              vr_lsb;
    int              vr_bits;
    string           vr_s;
    int              vr_tmp_int;
    uvm_status_e     vr_status;

    vr_reg.read(vr_status, vr_rdata);
    if (vr_chk == 1) begin
        vr_reg.get_fields(vr_fields);
        if (vr_fields.size > 0) 
        for (int i=vr_fields.size -1; i>=0; i--) begin
            //if (vr_fields[i].get_access() != uvm_ral::RC &&
            //    vr_fields[i].get_access() != uvm_ral::RO &&
            //    vr_fields[i].get_name()   != "rsv_0") 
            //    continue;
            if (vr_fields[i].get_name() == "reserved" || vr_fields[i].get_name() == "rsv_0") continue;

            vr_msk     = 'h0;
            vr_exp     = 'h0;
            vr_act     = 'h0;
            vr_exp_msk = 'h0;
            vr_act_msk = 'h0;
            vr_lsb     = vr_fields[i].get_lsb_pos();   //get_lsb_pos_in_register();
            vr_bits    = vr_fields[i].get_n_bits();
            vr_s       = vr_fields[i].get_full_name();

            vr_tmp_int = 0;
            for (int j=0; j<vr_bits; j++) begin
                vr_tmp_int   += msk[vr_lsb + j];
                vr_msk[j]     = msk[vr_lsb + j];
                vr_exp[j]     = exp[vr_lsb + j];
                vr_act[j]     = vr_rdata[vr_lsb + j];
                vr_exp_msk[j] = exp[vr_lsb + j]      | msk[vr_lsb + j];
                vr_act_msk[j] = vr_rdata[vr_lsb + j] | msk[vr_lsb + j];
            end
            
            if (vr_tmp_int == vr_bits) begin  // the whole field has been mask
                `uvm_info(vr_reg.get_type_name(),$psprintf("NOTE! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h, field mask", vr_s, vr_exp, vr_act, vr_msk),UVM_LOW);
            end
            else if (vr_exp_msk == vr_act_msk) begin
                `uvm_info(vr_reg.get_type_name(),$psprintf("OK! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h", vr_s, vr_exp, vr_act, vr_msk),UVM_NONE);
            end
            else begin
                `uvm_error(vr_reg.get_type_name(),$psprintf("ERROR! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h", vr_s, vr_exp, vr_act, vr_msk));
            end
        end
    end
endtask : check_reg

task ovpm::check_fld(uvm_reg_field                    fld,
                     bit [`OVPM_MPI_DATA_WIDTH - 1:0] exp = 'h0,
                     bit [`OVPM_MPI_DATA_WIDTH - 1:0] msk = 'h0,
                     bit                              chk = 1);
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         act;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         exp_msk;
    bit [`OVPM_MPI_DATA_WIDTH - 1:0]         act_msk;
    string           fld_name;
    uvm_status_e     vr_status;
    int              fld_bits;
    int              vr_tmp_int;

    fld.read(vr_status, act);
    
    if (chk == 1) begin
        fld_bits = fld.get_n_bits();
        fld_name = fld.get_full_name();

        for (int j=0; j<fld_bits; j++) begin
            vr_tmp_int += msk[j];
            exp_msk[j]  = exp[j] | msk[j];
            act_msk[j]  = act[j] | msk[j];
        end

        if (vr_tmp_int == fld_bits) begin  // the whole field has been mask
            `uvm_info(fld.get_type_name(),$psprintf("NOTE! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h, field mask", fld_name, exp, act, msk),UVM_LOW);
        end    
        else if (exp_msk == act_msk) begin
            `uvm_info(fld.get_type_name(),$psprintf("OK! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h", fld_name, exp, act, msk),UVM_NONE);
        end
        else begin
            `uvm_error(fld.get_type_name(),$psprintf("ERROR! %-80s : exp = 0x%0h, act = 0x%0h, msk = 0x%0h", fld_name, exp, act, msk));
        end
    end

endtask : check_fld

// vmm // function void ovpm::chk_report_int(input vmm_log vr_log,
// vmm //                                    input string  vr_check_name,
// vmm //                                    input bit     vr_result_is_ok,
// vmm //                                    input int     vr_exp_data,
// vmm //                                    input int     vr_act_data,
// vmm //                                    input string  vr_severity = "error");
// vmm //      if (vr_result_is_ok) begin
// vmm //          `vmm_note(vr_log, $psprintf("OK! When checking %s , the act value equal to expected value \"%0x\"  ", vr_check_name, vr_exp_data) );
// vmm //      end 
// vmm //      else begin
// vmm //          string vr_report =  $psprintf("When checking %s, the act value is \"%0x\", not equal to expect \"%0x\" ", vr_check_name, vr_exp_data, vr_act_data );
// vmm //         
// vmm //          case (vr_severity)
// vmm //               "error"   : `vmm_error(vr_log, vr_report);
// vmm //               "fatal"   : `vmm_fatal(vr_log, vr_report);
// vmm //               "warning" : `vmm_warning(vr_log, vr_report);
// vmm //               "note"    : `vmm_note(vr_log, vr_report);
// vmm //               default   : `vmm_fatal(vr_log, $psprintf("ovpm::chk_report_int() find an unsupported  vr_severity : %s", vr_severity) );
// vmm //          endcase
// vmm //      end
// vmm // 
// vmm // endfunction : chk_report_int
// vmm // 
// vmm // function void ovpm::chk_report_string(input vmm_log vr_log,
// vmm //                                       input string  vr_check_name,
// vmm //                                       input bit     vr_result_is_ok,
// vmm //                                       input string  vr_exp_data,
// vmm //                                       input string  vr_act_data,
// vmm //                                       input string  vr_severity = "error");
// vmm //      if (vr_result_is_ok) begin
// vmm //          `vmm_note(vr_log, $psprintf("OK! When checking %s , the act value equal to expected value %s  ", vr_check_name, vr_exp_data) );
// vmm //      end 
// vmm //      else begin
// vmm //          string vr_report =  $psprintf("When checking %s, the act value is %s, not equal to expect %s ", vr_check_name, vr_exp_data, vr_act_data );
// vmm //         
// vmm //          case (vr_severity)
// vmm //               "error"   : `vmm_error(vr_log, vr_report);
// vmm //               "fatal"   : `vmm_fatal(vr_log, vr_report);
// vmm //               "warning" : `vmm_warning(vr_log, vr_report);
// vmm //               "note"    : `vmm_note(vr_log, vr_report);
// vmm //               default   : `vmm_fatal(vr_log, $psprintf("ovpm::chk_report_int() find an unsupported  vr_severity : %s", vr_severity) );
// vmm //          endcase
// vmm //      end
// vmm // 
// vmm // endfunction : chk_report_string

function void ovpm::seq_data_check(ref   bit       vr_seq_is_sync,
                                   ref   int       vr_seq_ini_idx,
                                   input bit [7:0] vr_seq_data[],
                                   ref   bit [7:0] vr_data[]);
    bit[7:0]  vr_syn_err_cnt;
    if (vr_seq_is_sync == 0) begin
        vr_seq_ini_idx = 0;
    end
    if (vr_seq_data.size <= vr_seq_ini_idx) begin
        vr_seq_is_sync = 0;
        return;
    end
    foreach (vr_data[i]) begin
        if (vr_data[i] == vr_seq_data[vr_seq_ini_idx]) begin
            if(vr_seq_is_sync == 0) begin
                if(vr_data[i+vr_seq_data.size-1] == vr_seq_data[vr_seq_data.size-1]) vr_seq_is_sync = 1;
                else continue;
            end
            if(vr_seq_ini_idx++ == vr_seq_data.size-1) vr_seq_ini_idx = 0;
        end
        else begin
            if(vr_seq_is_sync == 1) begin 
                vr_seq_is_sync = 0;
                vr_seq_ini_idx = 0;
                $display("OVPM::seq_data_check():    warning! SYNC -> HUNT");
                if(vr_syn_err_cnt++ > 1) return;
            end
        end
    end 
endfunction : seq_data_check 

function bit [32:0] ovpm::crc16_correct_table(bit[15:0] vr_crc_result);
    case (vr_crc_result)
        //data single bit err position
        16'h0000 : return 33'h0_0000_0000;
        16'h1021 : return 33'h0_0001_0000;
        16'h2042 : return 33'h0_0002_0000;
        16'h4084 : return 33'h0_0004_0000;
        16'h8108 : return 33'h0_0008_0000;
        16'h1231 : return 33'h0_0010_0000;
        16'h2462 : return 33'h0_0020_0000;
        16'h48C4 : return 33'h0_0040_0000;
        16'h9188 : return 33'h0_0080_0000;
        16'h3331 : return 33'h0_0100_0000;
        16'h6662 : return 33'h0_0200_0000;
        16'hCCC4 : return 33'h0_0400_0000;
        16'h89A9 : return 33'h0_0800_0000;
        16'h0373 : return 33'h0_1000_0000;
        16'h06E6 : return 33'h0_2000_0000;
        16'h0DCC : return 33'h0_4000_0000;
        16'h1B98 : return 33'h0_8000_0000;
        //hec single bit err position
        16'h0001 : return 33'h0_0000_0001;
        16'h0002 : return 33'h0_0000_0002;
        16'h0004 : return 33'h0_0000_0004;
        16'h0008 : return 33'h0_0000_0008;
        16'h0010 : return 33'h0_0000_0010;
        16'h0020 : return 33'h0_0000_0020;
        16'h0040 : return 33'h0_0000_0040;
        16'h0080 : return 33'h0_0000_0080;
        16'h0100 : return 33'h0_0000_0100;
        16'h0200 : return 33'h0_0000_0200;
        16'h0400 : return 33'h0_0000_0400;
        16'h0800 : return 33'h0_0000_0800;
        16'h1000 : return 33'h0_0000_1000;
        16'h2000 : return 33'h0_0000_2000;
        16'h4000 : return 33'h0_0000_4000;
        16'h8000 : return 33'h0_0000_8000;
        default : begin
            return 33'h1_0000_0000;
        end
    endcase
endfunction : crc16_correct_table


// **************************************************************************
// function(task)   :   bit2byte
// purpose          :  
// author           :  
// **************************************************************************
function ovpm::bit2byte(ref    bit      pr_bit_a[],
                        output bit[7:0] pr_byte_a[]);
    bit [7:0] vr_byte;
	int vr_byte_size = pr_bit_a.size/8;
	pr_byte_a = new[vr_byte_size];
    for (int i=0;i<vr_byte_size;i++) begin
        for (int j=0;j<8;j++) begin
            vr_byte[7-j] = pr_bit_a[i*8+j];
        end
        pr_byte_a[i] = vr_byte;
    end
endfunction : bit2byte

function ovpm::byte2bit(ref    bit[7:0] pr_byte_a[],
                        output bit      pr_bit_a[]);
	pr_bit_a = new[pr_byte_a.size*8];
	foreach (pr_byte_a[index]) begin
		pr_bit_a[index*8+0] = pr_byte_a[index][7];
		pr_bit_a[index*8+1] = pr_byte_a[index][6];
		pr_bit_a[index*8+2] = pr_byte_a[index][5];
		pr_bit_a[index*8+3] = pr_byte_a[index][4];
		pr_bit_a[index*8+4] = pr_byte_a[index][3];
		pr_bit_a[index*8+5] = pr_byte_a[index][2];
		pr_bit_a[index*8+6] = pr_byte_a[index][1];
		pr_bit_a[index*8+7] = pr_byte_a[index][0];
	end
endfunction : byte2bit
 
// **************************************************************************
// function(task)   :   crc_calc
// purpose          :   calc SDH J0/J1 crc field 
// author           :  
// **************************************************************************
function bit[6:0] ovpm::crc_calc(ref bit[7:0] pr_in_a[]);
	bit [6:0] vr_output_data = 7'b1000001;
	bit       vr_bittmp;
	for (int i=0;i<pr_in_a.size();i++) begin
		for (int k=7;k>=0;k--) begin
			vr_bittmp         = pr_in_a[i][k]^vr_output_data[6];
			vr_output_data[6] = vr_output_data[5];
			vr_output_data[5] = vr_output_data[4];
			vr_output_data[4] = vr_output_data[3];
			vr_output_data[3] = vr_output_data[2]^vr_bittmp;
			vr_output_data[2] = vr_output_data[1];
			vr_output_data[1] = vr_output_data[0];
			vr_output_data[0] = vr_bittmp^1'b0;
		end
	end
	return vr_output_data;	
endfunction : crc_calc

// **************************************************************************
// function(task)   :   crc_calc
// purpose          :   calc SDH J0/J1 oh sum 
// author           :  
// **************************************************************************
function bit[7:0] ovpm::sum_calc(ref bit[7:0] pr_in_a[]);
	bit [7:0] vr_sum;
	for (int i=0;i<pr_in_a.size();i++) begin
	   vr_sum = vr_sum + pr_in_a[i];
    end
	return vr_sum;	
endfunction : sum_calc


// **************************************************************************
// function(task)   :   gen_prbs_bit
// purpose          :    
// author           :  
// **************************************************************************
function void ovpm::gen_prbs_bit(ref   int               	pr_prbs_ini_data,
								 input ovpt::prbs_type_e    pr_prbs_type = ovpt::PRBS23, 
                                 input int           	    pr_length,
                                 ref   bit           	    pr_data[],
                                 input int unsigned  	    pr_offset = 0
                                 );
	case (pr_prbs_type)
		ovpt::PRBS31	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[30 : 0] == 'h0) begin
    		     pr_prbs_ini_data = 'h7ff_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
        		$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[30];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[29 : 0], (pr_prbs_ini_data[30] ^ pr_prbs_ini_data[27]) };
    		end     			
		end
		ovpt::PRBS23	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[22 : 0] == 'h0) begin
    		     pr_prbs_ini_data = 'h7_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
        		//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
        		$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[22];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[21 : 0], (pr_prbs_ini_data[22] ^ pr_prbs_ini_data[19]) };
    		end     					
		end
		ovpt::PRBS20	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[19 : 0] == 'h0) begin
    		     pr_prbs_ini_data = 'hf_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
        		//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
        		$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[19];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[18 : 0], (pr_prbs_ini_data[19] ^ pr_prbs_ini_data[16]) };
    		end     					
		end
		ovpt::PRBS15	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[14 : 0] == 'h0) begin
    		     pr_prbs_ini_data = 'h7fff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
        		//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
        		$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[14];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[13 : 0], (pr_prbs_ini_data[14] ^ pr_prbs_ini_data[13]) };
    		end     					
		end
	endcase
endfunction : gen_prbs_bit 

// **************************************************************************
// function(task)   :   prbs_bit_check
// purpose          :    
// author           :  
// **************************************************************************
function void ovpm::prbs_bit_check(ref   bit           	    pr_prbs_is_sync,
  							       input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                  			       ref   int                pr_prbs_ini_data,
                                   ref   bit                pr_data[]
                                   );
    bit  vr_prbs_bit;           
	case (pr_prbs_type)
		ovpt::PRBS31	:	begin
    		if (pr_prbs_is_sync == 0) begin
				for (int m=0;m<31;m++) begin
    		    	pr_prbs_ini_data[30-m] = pr_data[m];
				end
    		end
    		if (pr_prbs_ini_data[30 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_bit = pr_prbs_ini_data[30];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[29 : 0], (pr_prbs_ini_data[30] ^ pr_prbs_ini_data[27]) };
    		    if (pr_data[i] != vr_prbs_bit) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 		
		end
		ovpt::PRBS23	:	begin
    		if (pr_prbs_is_sync == 0) begin
				for (int m=0;m<23;m++) begin
    		    	pr_prbs_ini_data[22-m] = pr_data[m];
				end
    		end
    		if (pr_prbs_ini_data[22 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_bit = pr_prbs_ini_data[22];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[21 : 0], (pr_prbs_ini_data[22] ^ pr_prbs_ini_data[19]) };
    		    if (pr_data[i] != vr_prbs_bit) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
		ovpt::PRBS20	:	begin
    		if (pr_prbs_is_sync == 0) begin
				for (int m=0;m<20;m++) begin
    		    	pr_prbs_ini_data[19-m] = pr_data[m];
				end
    		end
    		if (pr_prbs_ini_data[19 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_bit = pr_prbs_ini_data[19];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[18 : 0], (pr_prbs_ini_data[19] ^ pr_prbs_ini_data[16]) };
    		    if (pr_data[i] != vr_prbs_bit) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
		ovpt::PRBS15	:	begin
    		if (pr_prbs_is_sync == 0) begin
				for (int m=0;m<15;m++) begin
    		    	pr_prbs_ini_data[14-m] = pr_data[m];
				end
    		end
    		if (pr_prbs_ini_data[14 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_bit = pr_prbs_ini_data[14];
    		    pr_prbs_ini_data = {pr_prbs_ini_data[13 : 0], (pr_prbs_ini_data[14] ^ pr_prbs_ini_data[13]) };
    		    if (pr_data[i] != vr_prbs_bit) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
	endcase

    pr_prbs_is_sync = 1;
endfunction : prbs_bit_check

 
// **************************************************************************
// function(task)   :   gen_prbs_byte
// purpose          :    
// author           :  
// **************************************************************************
function void ovpm::gen_prbs_byte (ref   int               	pr_prbs_ini_data,
								   input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                                   input int           	    pr_length,
                                   ref   bit[7:0]      	    pr_data[],
                                   input int unsigned  	    pr_offset = 0
                                   );								   
	case (pr_prbs_type)
		ovpt::PRBS31	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[30 : 0] == 'h0) begin
    		    pr_prbs_ini_data = 'h7ff_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
				//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
				$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[30 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[29 : 0], (pr_prbs_ini_data[30] ^ pr_prbs_ini_data[27]) };
				end
    		end     			
		end
		ovpt::PRBS23	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[22 : 0] == 'h0) begin
    		    pr_prbs_ini_data = 'h7f_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
				//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
				$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[22 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	//pr_prbs_ini_data = {pr_prbs_ini_data[21 : 0], (pr_prbs_ini_data[22] ^ pr_prbs_ini_data[19]) };
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[21 : 0], (pr_prbs_ini_data[22] ^ pr_prbs_ini_data[17]) };
				end
    		end     					
		end
		ovpt::PRBS20	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[19 : 0] == 'h0) begin
    		    pr_prbs_ini_data = 'hf_ffff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
				//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
				$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[19 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[18 : 0], (pr_prbs_ini_data[19] ^ pr_prbs_ini_data[16]) };
				end
    		end     					
		end
		ovpt::PRBS15	:	begin
    		// to ensure the output is not all-0
    		if (pr_prbs_ini_data[14 : 0] == 'h0) begin
    		     pr_prbs_ini_data = 'h7fff;
    		end
    		if (pr_data.size > pr_length + pr_offset) begin
				//`uvm_error(get_type_name(),$psprintf("Warning! when try to prbs data, the input parameter is \
    		    //          length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size));
				$display("Warning! when try to prbs data, the input parameter is \
    		              length:%0d, offset:%0d,  data.size:%0d. Do you really want to do this?", pr_length, pr_offset, pr_data.size);
    		end
    		if (pr_data.size < pr_length + pr_offset) begin
    		    pr_data = new[pr_offset + pr_length](pr_data);
    		end

    		for (int i = pr_offset; i< pr_offset + pr_length ; i++) begin
    		    pr_data[i] = pr_prbs_ini_data[14 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	//pr_prbs_ini_data = {pr_prbs_ini_data[13 : 0], (pr_prbs_ini_data[14] ^ pr_prbs_ini_data[11]) };
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[13 : 0], (pr_prbs_ini_data[14] ^ pr_prbs_ini_data[13]) };
				end
    		end     					
		end
	endcase
endfunction : gen_prbs_byte

// **************************************************************************
// function(task)   :   prbs_byte_check
// purpose          :    
// author           :  
// **************************************************************************
function void ovpm::prbs_byte_check(ref   bit           	 pr_prbs_is_sync,
									input ovpt::prbs_type_e  pr_prbs_type = ovpt::PRBS23, 
                                    ref   int                pr_prbs_ini_data,
				                    ref   bit[7:0]           pr_data[]
                				    );
    bit [7:0] vr_prbs_byte;           

	case (pr_prbs_type)
		ovpt::PRBS31	:	begin
    		if (pr_prbs_is_sync == 0) begin
    		    pr_prbs_ini_data = {pr_data[0],pr_data[1],pr_data[2],pr_data[3][7:1]};
    		end
    		if (pr_prbs_ini_data[30 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_byte = pr_prbs_ini_data[30 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[29 : 0], (pr_prbs_ini_data[30] ^ pr_prbs_ini_data[27]) };
				end
    		    if (pr_data[i] != vr_prbs_byte) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 		
		end
		ovpt::PRBS23	:	begin
    		if (pr_prbs_is_sync == 0) begin
    		    pr_prbs_ini_data = {pr_data[0],pr_data[1],pr_data[2][7:1]};
    		end
    		if (pr_prbs_ini_data[22 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_byte = pr_prbs_ini_data[22 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[21 : 0], (pr_prbs_ini_data[22] ^ pr_prbs_ini_data[19]) };
				end
    		    if (pr_data[i] != vr_prbs_byte) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
		ovpt::PRBS20	:	begin
    		if (pr_prbs_is_sync == 0) begin
    		    pr_prbs_ini_data = {pr_data[0],pr_data[1],pr_data[2][7:4]};
    		end
    		if (pr_prbs_ini_data[19 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_byte = pr_prbs_ini_data[19 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[18 : 0], (pr_prbs_ini_data[19] ^ pr_prbs_ini_data[16]) };
				end
    		    if (pr_data[i] != vr_prbs_byte) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
		ovpt::PRBS15	:	begin
    		if (pr_prbs_is_sync == 0) begin
    		    pr_prbs_ini_data = {pr_data[0],pr_data[1][7:1]};
    		end
    		if (pr_prbs_ini_data[14 : 0] == 'h0) begin
    		    pr_prbs_is_sync = 0;
    		    return;
    		end
    		foreach (pr_data[i]) begin
    		    vr_prbs_byte = pr_prbs_ini_data[14 -:8];
        		for (int j=0; j<8 ; j++) begin
    		    	pr_prbs_ini_data = {pr_prbs_ini_data[13 : 0], (pr_prbs_ini_data[14] ^ pr_prbs_ini_data[11]) };
				end
    		    if (pr_data[i] != vr_prbs_byte) begin
    		        pr_prbs_is_sync = 0;
    		        return;
    		    end
    		end 				
		end
	endcase

    pr_prbs_is_sync = 1;									

endfunction : prbs_byte_check								

function int ovpm::floor(real vr_real);
    int     data;

    data = int'(vr_real);
    if(data > vr_real)
        floor = data - 1;
    else
        floor = data;

endfunction: floor

function int ovpm::ceiling(real vr_real);
    int     data;

    data = int'(vr_real);
    if(data < vr_real)
        ceiling = data + 1;
    else
        ceiling = data;

endfunction: ceiling

function void ovpm::bit_reverse(ref bit[LENGTH -1:0] reverse_da);

    bit[LENGTH -1:0]    tmp_da;

    tmp_da = reverse_da;
    for(int i=0; i<LENGTH; i++)
        reverse_da[i] = tmp_da[LENGTH -1 -i];

endfunction: bit_reverse

function void ovpm::gen_odtu_seq_cn(input bit [`CN_SEQ_W:0]     vr_poly,
                                    ref   bit [`CN_SEQ_W:0]     vr_res,
                                    input int                   vr_cn_q[],
                                    ref   int                   vr_cn);
    bit     seq[]; 
    seq = new[1];
    if(vr_cn_q.size != 2)
        `uvm_fatal("ovpm", $psprintf("gen_odtu_seq_cn error vr_cn_q.size=%0d ", vr_cn_q.size));
    ovpm#(`CN_SEQ_W + 1)::prbs_bit_gen(vr_poly,vr_res,seq);
    vr_cn = vr_cn_q[seq[0]];
endfunction: gen_odtu_seq_cn

function void ovpm::gen_odtu_poly(input int                   vr_ch_cid,
                                  ref   bit [`CN_SEQ_W:0]     vr_poly,
                                  ref   bit [`CN_SEQ_W:0]     vr_res);
    int     poly_num;
    int     poly[7][]='{{7},
                        {11,13},
                        {19,25},
                        {37,41,47,55,59,61},
                        {67,91,97,103,109,115},
                        {131,137,143,145,157,167,171,185,191,193,203,211,213,229,239,241,247,253},
                        {285,299,301,333,351,355,357,361,369,391,397,425,451,463,487,501}};
    vr_poly = poly[`CN_SEQ_W - 2][vr_ch_cid/(2 ** `CN_SEQ_W - 1)];
    vr_res  = vr_ch_cid%(2 ** `CN_SEQ_W - 1) + 1;
endfunction: gen_odtu_poly

function void ovpm::chk_odtu_seq_cn(input bit [`CN_SEQ_W:0]     vr_poly,
                                    ref   bit [`CN_SEQ_W:0]     vr_res,
                                    input int                   vr_cn_q[],
                                    input int                   vr_cn[],
                                    ref   bit                   vr_err[]);
    
    bit     seq[]; 
    if(vr_cn_q.size != 2)
        `uvm_fatal("ovpm", $psprintf("chk_odtu_seq_cn error vr_cn_q.size=%0d ", vr_cn_q.size));
    seq = new[vr_cn.size];
    foreach(vr_cn[i])
        if(vr_cn[i] == vr_cn_q[0])
            seq[i] = 0;
        else
            seq[i] = 1;
    ovpm#(`CN_SEQ_W + 1)::prbs_bit_chk(vr_poly,vr_res,seq,vr_err);
endfunction: chk_odtu_seq_cn

`endif
