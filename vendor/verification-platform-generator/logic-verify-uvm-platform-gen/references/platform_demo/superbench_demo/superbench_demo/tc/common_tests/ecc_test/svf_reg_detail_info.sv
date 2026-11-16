`define GLB_CLK        tb_top.u_ped_seg_top.clk_sys
typedef struct{    
    bit             ignore_flag                ; // ram_ecc测试忽略标记 0:测试       1:不测试
	bit             inject_ram_en              ; //是否支持配置注错  0：不支持  1：支持
    bit             ecc_en                     ; // 是否是ecc校验       0:奇偶校验   1:ecc校验
	int             ram_type                   ; // ram类型             1:DCSDP 双时钟简单双端口RAM   2:SDP 简单双端口  3:SP 简单单端口  4:BDP 真双端口RAM
    string          fiforam_path               ; // 对应ram例化名                                       ex：tb_top.u_ped_seg_top.u_ped.u_fbm_ped_data_ram
    string          ramdata_path               ; // bottom ram data                                     ex：u_ram_cmn_func.ram_data_trunk
    string          tbl_ral_str                ; // 配置ram的ral路径                                    ex："reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"
    bit[511:0]      tbl_mask                   ; // 配置ram表项掩码                                     ex：位宽48bit，掩码为{48{1'b1}}      
    uvm_reg         ecc_inject_reg             ; // 配置ram 注错寄存器对应的ral路径                     ex：reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject，如没有，填写null
    int             ecc_inject_offset          ; // 配置rm 在注错寄存器中的偏移                        ex：1
	uvm_reg         ecc_debug_ecc_err_reg      ; // ram cc_err信息对应的寄存器ral路径                  ex：reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0 如没有，填写null
    int             ecc_debug_ecc_err_offset   ; // ram ecc_err信息在对应寄存器的偏移(起始地址)         ex：1                                                                                                    
	uvm_reg         ecc_debug_sbit_err_reg     ; // ram sbit_err信息对应的寄存器ral路径                 ex：reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0 如没有，填写null
    int             ecc_debug_sbit_err_offset  ; // ram sbit_err信息在对应寄存器的偏移(起始地址)        ex：1
	uvm_reg         ecc_debug_sbit_addr_reg    ; // ram 单bit错误地址信息对应的寄存器ral路径            ex：reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0 如没有，填写null
    int             ecc_debug_sbit_addr_offset ; // ram 单bit错误地址信息在对应寄存器的偏移(起始地址)   ex：1                                                                                                    
	uvm_reg         ecc_debug_dbit_err_reg     ; // ram dbit_err信息对应的寄存器ral路径                 ex：reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0 如没有，填写null
    int             ecc_debug_dbit_err_offset  ; // ram dbit_err信息在对应寄存器的偏移(起始地址)        ex：1                                                                                                  
	uvm_reg         ecc_debug_dbit_addr_reg    ; // ram 多bit错误地址信息对应的寄存器ral路径            ex：reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0 如没有，填写null
    int             ecc_debug_dbit_addr_offset ; // ram 多bit错误地址信息在对应寄存器的偏移(起始地址)   ex：1	
} reg_ecc_info_struct;

class reg_info_class extends uvm_component;
    ral_sys_ld2025 reg_model;

    reg_ecc_info_struct int_status_ecc_reg_list[(11-1):0];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction:new

    `uvm_component_utils(reg_info_class)

    task reg_ecc_info_get();
		int_status_ecc_reg_list[0].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[0].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[0].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[0].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[0].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_ped_gi.u_beatnum_info_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[0].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"                   ;
        int_status_ecc_reg_list[0].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl";       ;
        int_status_ecc_reg_list[0].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[0].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[0].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[0].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[0].ecc_debug_ecc_err_offset   =   16                                                ;		
		int_status_ecc_reg_list[0].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[0].ecc_debug_sbit_err_offset  =   17                                                ;		
		int_status_ecc_reg_list[0].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[0].ecc_debug_sbit_addr_offset =   20                                                ;	
        int_status_ecc_reg_list[0].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[0].ecc_debug_dbit_err_offset  =   18                                                ; 
        int_status_ecc_reg_list[0].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[0].ecc_debug_dbit_addr_offset =   20                                                ;

        int_status_ecc_reg_list[1].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[1].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[1].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[1].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[1].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_ped_gi.u_causeid_info_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[1].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;   
        int_status_ecc_reg_list[1].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl";       ;
        int_status_ecc_reg_list[1].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[1].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[1].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[1].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[1].ecc_debug_ecc_err_offset   =   8                                                 ;		
		int_status_ecc_reg_list[1].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[1].ecc_debug_sbit_err_offset  =   9                                                 ;		
		int_status_ecc_reg_list[1].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[1].ecc_debug_sbit_addr_offset =   12                                                ;	
        int_status_ecc_reg_list[1].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[1].ecc_debug_dbit_err_offset  =   10                                                ; 
        int_status_ecc_reg_list[1].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[1].ecc_debug_dbit_addr_offset =   12                                                ;

        int_status_ecc_reg_list[2].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[2].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[2].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[2].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[2].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_ped_gi.u_aib1_info_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[2].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[2].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl";       ;
        int_status_ecc_reg_list[2].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[2].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[2].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[2].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[2].ecc_debug_ecc_err_offset   =   0                                                 ;		
		int_status_ecc_reg_list[2].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[2].ecc_debug_sbit_err_offset  =   1                                                 ;		
		int_status_ecc_reg_list[2].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[2].ecc_debug_sbit_addr_offset =   4                                                 ;	
        int_status_ecc_reg_list[2].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[2].ecc_debug_dbit_err_offset  =   2                                                 ; 
        int_status_ecc_reg_list[2].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug1     ;
        int_status_ecc_reg_list[2].ecc_debug_dbit_addr_offset =   4                                                 ;

        int_status_ecc_reg_list[3].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[3].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[3].ecc_en                     =   0                                                 ;
		int_status_ecc_reg_list[3].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[3].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_fbm_ped_data_ram"   ;
        int_status_ecc_reg_list[3].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[3].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[3].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[3].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[3].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[3].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[3].ecc_debug_ecc_err_offset   =   9                                                 ;		
		int_status_ecc_reg_list[3].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[3].ecc_debug_sbit_err_offset  =   10                                                ;		
		int_status_ecc_reg_list[3].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[3].ecc_debug_sbit_addr_offset =   13                                                ;	
        int_status_ecc_reg_list[3].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[3].ecc_debug_dbit_err_offset  =   11                                                ; 
        int_status_ecc_reg_list[3].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[3].ecc_debug_dbit_addr_offset =   13                                                ;

        int_status_ecc_reg_list[4].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[4].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[4].ecc_en                     =   0                                                 ;
		int_status_ecc_reg_list[4].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[4].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_sch_ped_info_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[4].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[4].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[4].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[4].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[4].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[4].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[4].ecc_debug_ecc_err_offset   =   0                                                 ;		
		int_status_ecc_reg_list[4].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[4].ecc_debug_sbit_err_offset  =   1                                                 ;		
		int_status_ecc_reg_list[4].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[4].ecc_debug_sbit_addr_offset =   4                                                 ;	
        int_status_ecc_reg_list[4].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[4].ecc_debug_dbit_err_offset  =   2                                                 ; 
        int_status_ecc_reg_list[4].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug2     ;
        int_status_ecc_reg_list[4].ecc_debug_dbit_addr_offset =   4                                                 ;

        int_status_ecc_reg_list[5].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[5].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[5].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[5].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[5].fiforam_path               =   "tb_top.u_ped_seg_top.u_seg.u_seg_beatcnt_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[5].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[5].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[5].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[5].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[5].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[5].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[5].ecc_debug_ecc_err_offset   =   9                                                 ;		
		int_status_ecc_reg_list[5].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[5].ecc_debug_sbit_err_offset  =   10                                                ;		
		int_status_ecc_reg_list[5].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[5].ecc_debug_sbit_addr_offset =   13                                                ;	
        int_status_ecc_reg_list[5].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[5].ecc_debug_dbit_err_offset  =   11                                                ; 
        int_status_ecc_reg_list[5].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[5].ecc_debug_dbit_addr_offset =   13                                                ;

        int_status_ecc_reg_list[6].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[6].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[6].ecc_en                     =   0                                                 ;
		int_status_ecc_reg_list[6].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[6].fiforam_path               =   "tb_top.u_ped_seg_top.u_seg.u_eacl_seg_info_fifo.genblk3.U_SDP_RAM_v"   ;
        int_status_ecc_reg_list[6].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[6].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[6].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[6].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[6].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[6].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[6].ecc_debug_ecc_err_offset   =   0                                                 ;		
		int_status_ecc_reg_list[6].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[6].ecc_debug_sbit_err_offset  =   1                                                 ;		
		int_status_ecc_reg_list[6].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[6].ecc_debug_sbit_addr_offset =   4                                                 ;	
        int_status_ecc_reg_list[6].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[6].ecc_debug_dbit_err_offset  =   2                                                 ; 
        int_status_ecc_reg_list[6].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug3     ;
        int_status_ecc_reg_list[6].ecc_debug_dbit_addr_offset =   4                                                 ;

        int_status_ecc_reg_list[7].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[7].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[7].ecc_en                     =   0                                                 ;
		int_status_ecc_reg_list[7].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[7].fiforam_path               =   "tb_top.u_ped_seg_top.u_seg.u_seg_data_mod_save_ram"   ;
        int_status_ecc_reg_list[7].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[7].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[7].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[7].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[7].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[7].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[7].ecc_debug_ecc_err_offset   =   11                                                ;		
		int_status_ecc_reg_list[7].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[7].ecc_debug_sbit_err_offset  =   12                                                ;		
		int_status_ecc_reg_list[7].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[7].ecc_debug_sbit_addr_offset =   15                                                ;	
        int_status_ecc_reg_list[7].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[7].ecc_debug_dbit_err_offset  =   13                                                ; 
        int_status_ecc_reg_list[7].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[7].ecc_debug_dbit_addr_offset =   15                                                ;

        int_status_ecc_reg_list[8].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[8].inject_ram_en              =   0                                                 ;
        int_status_ecc_reg_list[8].ecc_en                     =   0                                                 ;
		int_status_ecc_reg_list[8].ram_type                   =   2                                                 ;
        int_status_ecc_reg_list[8].fiforam_path               =   "tb_top.u_ped_seg_top.u_seg.u_ped_seg_data_ram"   ;
        int_status_ecc_reg_list[8].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[8].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[8].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[8].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[8].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[8].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[8].ecc_debug_ecc_err_offset   =   0                                                 ;		
		int_status_ecc_reg_list[8].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[8].ecc_debug_sbit_err_offset  =   1                                                 ;		
		int_status_ecc_reg_list[8].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[8].ecc_debug_sbit_addr_offset =   4                                                 ;	
        int_status_ecc_reg_list[8].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[8].ecc_debug_dbit_err_offset  =   2                                                 ; 
        int_status_ecc_reg_list[8].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug4     ;
        int_status_ecc_reg_list[8].ecc_debug_dbit_addr_offset =   4                                                 ;

        int_status_ecc_reg_list[9].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[9].inject_ram_en              =   1                                                 ;
        int_status_ecc_reg_list[9].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[9].ram_type                   =   3                                                 ;
        int_status_ecc_reg_list[9].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_cib_pedseg.u_spram_ped_aib1_tbl"   ;
        int_status_ecc_reg_list[9].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[9].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_aib1_tbl"        ;
        int_status_ecc_reg_list[9].tbl_mask                   =   {48{1'b1}}                                        ; 
		int_status_ecc_reg_list[9].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[9].ecc_inject_offset          =   0                                                 ;
        int_status_ecc_reg_list[9].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[9].ecc_debug_ecc_err_offset   =   0                                                 ;		
		int_status_ecc_reg_list[9].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[9].ecc_debug_sbit_err_offset  =   1                                                 ;		
		int_status_ecc_reg_list[9].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[9].ecc_debug_sbit_addr_offset =   4                                                 ;	
        int_status_ecc_reg_list[9].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[9].ecc_debug_dbit_err_offset  =   2                                                 ; 
        int_status_ecc_reg_list[9].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[9].ecc_debug_dbit_addr_offset =   4                                                 ;

        int_status_ecc_reg_list[10].ignore_flag                =   0                                                 ;
		int_status_ecc_reg_list[10].inject_ram_en              =   1                                                 ;
        int_status_ecc_reg_list[10].ecc_en                     =   1                                                 ;
		int_status_ecc_reg_list[10].ram_type                   =   3                                                 ;
        int_status_ecc_reg_list[10].fiforam_path               =   "tb_top.u_ped_seg_top.u_ped.u_cib_pedseg.u_spram_ped_causeid_tbl"   ;
        int_status_ecc_reg_list[10].ramdata_path               =   "u_ram_cmn_func.ram_data_trunk"   ;
        int_status_ecc_reg_list[10].tbl_ral_str                =   "reg_model.cib_dp.cib_pedseg.ped_causeid_tbl"     ;
        int_status_ecc_reg_list[10].tbl_mask                   =   {6{1'b1}}                                         ; 
		int_status_ecc_reg_list[10].ecc_inject_reg             =   reg_model.cib_dp.cib_pedseg.pedseg_ramecc_inject  ;
        int_status_ecc_reg_list[10].ecc_inject_offset          =   1                                                 ;
        int_status_ecc_reg_list[10].ecc_debug_ecc_err_reg      =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[10].ecc_debug_ecc_err_offset   =   13                                                ;		
		int_status_ecc_reg_list[10].ecc_debug_sbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[10].ecc_debug_sbit_err_offset  =   14                                                ;		
		int_status_ecc_reg_list[10].ecc_debug_sbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[10].ecc_debug_sbit_addr_offset =   17                                                ;	
        int_status_ecc_reg_list[10].ecc_debug_dbit_err_reg     =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[10].ecc_debug_dbit_err_offset  =   15                                                ; 
        int_status_ecc_reg_list[10].ecc_debug_dbit_addr_reg    =   reg_model.cib_dp.cib_pedseg.pedseg_ecc_debug0     ;
        int_status_ecc_reg_list[10].ecc_debug_dbit_addr_offset =   17                                                ;

    endtask:reg_ecc_info_get

endclass:reg_info_class
