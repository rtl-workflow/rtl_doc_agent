//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : gaea_platform
//Initial-Date    : 2023-09-08 17:32:14
//Abstract        : svf_ram_ecc_test
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0 ( 2023-09-08 17:32:14 , by gaea_platform))
//   ... version info ...
//
//##################################################################
`ifndef _svf_ram_ecc_test_CLASS_
`define _svf_ram_ecc_test_CLASS_

`define TC svf_ram_ecc_test

class `TC extends basic_tc;

    reg_info_class reg_info_class_detail;
    `uvm_component_utils(`TC)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction:new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        reg_info_class_detail = reg_info_class::type_id::create("reg_info_class_detail",this);
        set_report_max_quit_count(5000);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        reg_info_class_detail.reg_model = reg_model;
    endfunction:connect_phase

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);
        //#1us;
        phase.drop_objection(this);
    endtask:reset_phase

    function uvm_reg get_uvm_reg_by_str(string ral_path,int addr); 
        uvm_reg_block blks[$],vr_uvm_block0, vr_uvm_block1,vr_uvm_block2;
        uvm_reg          vr_reg       ;
        uvm_reg_field    vr_field     ;
        uvm_status_e     status       ;
        string           split_val[$] ;
        string           real_ral_path;

        $sformat(real_ral_path,"%s[%0d]",ral_path,addr);
        uvm_reg_block::get_root_blocks(blks);
        uvm_split_string(real_ral_path,".",split_val);

        //foreach(blks[i]) begin
            //`uvm_info(get_name(),$psprintf("blks[%0d]=%s", i,blks[i].get_full_name), UVM_LOW);
        //end
        //foreach(split_val[i]) begin
            //`uvm_info(get_name(),$psprintf("split_val[%0d]=%s", i,split_val[i]), UVM_LOW);
        //end
        foreach(blks[i]) begin
            vr_uvm_block0 = blks[i].get_block_by_name(split_val[0]);
            if(vr_uvm_block0!=null) begin
                `uvm_info(get_name(),$psprintf("uvm_block0_name=%s",vr_uvm_block0.get_full_name), UVM_LOW);
                vr_uvm_block1 = vr_uvm_block0.get_block_by_name(split_val[1]);
                `uvm_info(get_name(),$psprintf("uvm_block1_name=%s",split_val[1]), UVM_LOW);
                if(vr_uvm_block1!=null) begin
                    if(split_val.size()==3) begin
                        vr_reg = vr_uvm_block1.get_reg_by_name(split_val[2]);
                        `uvm_info(get_name(),$psprintf("reg_name=%s",split_val[2]), UVM_LOW);
                    end
                    else begin
                        vr_uvm_block2 = vr_uvm_block1.get_block_by_name(split_val[2]);
                        `uvm_info(get_name(),$psprintf("uvm_block2_name=%s",split_val[2]), UVM_LOW);
                        vr_reg = vr_uvm_block2.get_reg_by_name(split_val[3]);
                        `uvm_info(get_name(),$psprintf("reg_name=%s",split_val[3]), UVM_LOW);
                    end
                    break;
                end
            end
        end

        return vr_reg;
    endfunction:get_uvm_reg_by_str;

    function dataram_wr_clk_trans(string fiforam_path,int dp_port_no,ref string w_en,ref string r_en,ref string cs_n,ref string wdin,ref string rclk,ref string wclk, ref string waddr,ref string raddr,ref int ram_type,ref int ram_depth,ref int ram_width); 
        if(ram_type==1) begin
            w_en     = "wren"          ;
            r_en     = "rden"          ;
            wdin     = "data"          ;
            rclk     = "rdclock"       ;
            wclk     = "wrclock"       ;
            waddr    = "wraddress"     ;
            raddr    = "rdaddress"     ;
            //ram_type = "DCSDP_WRAP"    ;
            uvm_hdl_read($psprintf("%s.WRITE_DEPTHBIT",fiforam_path),ram_depth);
            uvm_hdl_read($psprintf("%s.WRITE_WIDTHBIT",fiforam_path),ram_width);
            `uvm_info(get_name(),$psprintf("ram_type is DCSDP_WRAP ram_depth=%0d ram_width=%0d",ram_depth,ram_width), UVM_LOW);
        end
        else if(ram_type==2) begin
            w_en     = "wren"          ;
            r_en     = "rden"          ;
            wdin     = "data"          ;
            rclk     = "clock"         ;
            wclk     = "clock"         ;
            waddr    = "wraddress"     ;
            raddr    = "rdaddress"     ;
            //ram_type = "SDP_WRAP"      ;
            uvm_hdl_read($psprintf("%s.WRITE_DEPTHBIT",fiforam_path),ram_depth);
            uvm_hdl_read($psprintf("%s.WRITE_WIDTH",fiforam_path),ram_width)   ;
            `uvm_info(get_name(),$psprintf("ram_type is SDP_WRAP ram_depth=%0d ram_width=%0d",ram_depth,ram_width), UVM_LOW);
        end
        else if(ram_type==3) begin
            w_en     = "wren"          ;
            cs_n     = "cs_n"          ;
            wdin     = "data"          ;
            rclk     = "clock"         ;
            wclk     = "clock"         ;
            waddr    = "address"       ;
            raddr    = "address"       ;
            //ram_type = "SP_WRAP"       ;
            uvm_hdl_read($psprintf("%s.DEPTHBIT",fiforam_path),ram_depth);
            uvm_hdl_read($psprintf("%s.WIDTH",fiforam_path),ram_width)   ;
            `uvm_info(get_name(),$psprintf("ram_type is SP_WRAP ram_depth=%0d ram_width=%0d",ram_depth,ram_width), UVM_LOW);
        end
        else if(ram_type==4) begin
            if(dp_port_no==0) begin
                w_en     = "wren_a"          ;
                r_en     = "rden_a"          ;
                wdin     = "data_a"          ;
                rclk     = "clock_a"         ;
                wclk     = "clock_a"         ;
                waddr    = "address_a"       ;
                raddr    = "address_a"       ;
                uvm_hdl_read($psprintf("%s.A_DEPTHBIT",fiforam_path),ram_depth);
                uvm_hdl_read($psprintf("%s.A_WIDTH",fiforam_path),ram_width)   ;
            end
            else begin
                w_en     = "wren_b"          ;
                r_en     = "rden_b"          ;
                wdin     = "data_b"          ;
                rclk     = "clock_b"         ;
                wclk     = "clock_b"         ;
                waddr    = "address_b"       ;
                raddr    = "address_b"       ;
                uvm_hdl_read($psprintf("%s.B_DEPTHBIT",fiforam_path),ram_depth);
                uvm_hdl_read($psprintf("%s.B_WIDTH",fiforam_path),ram_width)   ;
            end
            ram_type = "BDP_WRAP"      ;
            `uvm_info(get_name(),$psprintf("ram_type is BDP_WRAP dp_port_no=%0d ram_depth=%0d ram_width=%0d",dp_port_no,ram_depth,ram_width), UVM_LOW);
        end
        else begin
            w_en     = "wen"          ;
            r_en     = "ren"          ;
            wdin     = "din"          ;
            rclk     = "rclk"         ;
            wclk     = "wclk"         ;
            waddr    = "waddr"        ;
            raddr    = "raddr"        ;
            //ram_type = "UN_KNOWN"     ;
            `uvm_info(get_name(),$psprintf("ram_type is UN_KNOWN ram_depth=%0d ram_width=%0d",ram_depth,ram_width), UVM_LOW);
        end
        `uvm_info(get_name(),$psprintf("w_en=%s r_en=%s cs_n=%s wdin=%s rclk=%s wclk=%s waddr=%s raddr=%s ram_depth=%0d ram_width=%0d",w_en,r_en,cs_n,wdin,rclk,wclk,waddr,raddr,ram_depth,ram_width), UVM_LOW);
    endfunction:dataram_wr_clk_trans

    //配置ram中断注入测试步骤： 
    //1、注错：打开注错使能，写注错地址，写完注错地址后关闭注错使能，写注错地址周围10个左右其他地址 
    //2、检查：读注错地址周围10个地址，检查没有中断产生
	//       读注错地址,检查中断寄存器和中断调试寄存器，预期中断拉起，单bit注错时 ecc_err和sbiterr拉高，单bit错误可纠 
	//       多bit注错时 ecc_err和dbiterr拉高，多bit错误不可纠 ，ecc_addr为对应注入地址A
    //3、回刷：写1清中断状态寄存器对应bit，写注错地址寄存器清除该ram的ecc故障，检查中断不再产生
    //4、重复1~3步骤，A分别取最小地址、随机地址、最大地址进行验证
    task cfgram_ecc_inject_test(string tbl_ral_str, int ram_depth,bit[511:0] ram_mask,int ram_addr,uvm_reg ecc_inject_reg,int ecc_inject_offset,uvm_reg ecc_debug_ecc_err_reg,int ecc_debug_ecc_err_offset,uvm_reg ecc_debug_sdbit_err_reg,int ecc_debug_sdbit_err_offset,uvm_reg ecc_debug_sdbit_addr_reg,int ecc_debug_sdbit_addr_offset,string fiforam_path,string ramdata_path,bit sbit_flag); 
        bit[31:0]     inject_tmp   ;
        bit[31:0]     inject_tmp_r ;
        bit[511:0]    wd_tmp       ;
        bit[511:0]    rd_tmp       ;
        bit[31:0]     ecc_status   ;
        bit[31:0]     ecc_addr     ;
        uvm_status_e  status       ;
        int           int_value=1  ;
        int           r_int_value  ;
        uvm_reg       cfg_ram      ;
        int           start_addr   ;
        int           end_addr     ;

        cfg_ram = get_uvm_reg_by_str(tbl_ral_str,ram_addr);
        `uvm_info(get_name(),$psprintf("ram_name = %s ram_addr='h%h inject sbit_flag=%0d test begin", cfg_ram.get_name(),ram_addr,sbit_flag), UVM_LOW);

        inject_tmp    = (32'b1<< ecc_inject_offset)   ;
        inject_tmp_r  = ~inject_tmp                   ;

        //1、注错：打开注错使能，写注错地址，写完注错地址后关闭注错使能，写注错地址周围10个左右其他地址
        if(sbit_flag) begin
            if(ecc_inject_reg!=null)
                ecc_inject_reg.write(status, inject_tmp,UVM_FRONTDOOR);
            else
                uvm_hdl_force($psprintf("%s.inject_sbiterr",fiforam_path),1'b1);
        end
        else begin
            uvm_hdl_force($psprintf("%s.inject_dbiterr",fiforam_path),1'b1);
        end
        wd_tmp = {16{$urandom()}} & ram_mask;
        cfg_ram.write(status, wd_tmp,UVM_FRONTDOOR);
        if(sbit_flag) begin
            if(ecc_inject_reg!=null)
                ecc_inject_reg.write(status, 0,UVM_FRONTDOOR);
            else
                uvm_hdl_force($psprintf("%s.inject_sbiterr",fiforam_path),1'b0);
        end
        else begin
            uvm_hdl_force($psprintf("%s.inject_dbiterr",fiforam_path),1'b0);
        end
        if(ram_addr==0) begin
            start_addr = 0;
            end_addr   = ((2**ram_depth-10)>0)?10:(2**ram_depth);
        end
        else if(ram_addr!=2**ram_depth) begin
            start_addr = ((ram_addr-5)>0)?(ram_addr-5):0;
            end_addr   = ((ram_addr+5) < (2**ram_depth))?(ram_addr+5):(2**ram_depth);
        end
        else begin
            start_addr = ((2**ram_depth-10)>0)?(2**ram_depth-10):0;
            end_addr   = 2**ram_depth;
        end
        for(int i=start_addr; i<end_addr;i++) begin
            if(i!=ram_addr) begin
                cfg_ram = get_uvm_reg_by_str(tbl_ral_str,i);
                cfg_ram.write(status, {16{$urandom()}} & ram_mask,UVM_FRONTDOOR);
            end
        end
        //2、检查：读注错地址周围10个地址，检查没有中断产生
        //       读注错地址,检查中断寄存器和中断调试寄存器，预期中断拉起，单bit注错时 ecc_err和sbiterr拉高，单bit错误可纠 
        //       多bit注错时 ecc_err和dbiterr拉高，多bit错误不可纠 ，ecc_addr为对应注入地址A
        for(int i=start_addr; i<end_addr;i++) begin
            if(i!=ram_addr) begin
                cfg_ram = get_uvm_reg_by_str(tbl_ral_str,i);
                cfg_ram.read(status, rd_tmp,UVM_FRONTDOOR);
                @(posedge `GLB_CLK);
                #1ns;
                uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
                if(ecc_status!=0) begin
                    `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h read_addr='h%h, after write not inject addr,read not inject addr,ecc_err is not 0",cfg_ram.get_name(),ram_addr,i));
                end
            end
        end
        cfg_ram = get_uvm_reg_by_str(tbl_ral_str,ram_addr);
        cfg_ram.read(status, rd_tmp,UVM_FRONTDOOR);
        if(sbit_flag) begin
            if((rd_tmp & ram_mask)!= wd_tmp) begin
                `uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject sbiterr,sbit error not correct, wd_tmp= 'h%h  rd_tmp= 'h%h",cfg_ram.get_name(),ram_addr,wd_tmp,rd_tmp));
            end
        end
        else begin
            if((rd_tmp & ram_mask)!= wd_tmp) begin
                `uvm_info(get_name, $psprintf("ram_name = %s ram_addr='h%h after inject dbiterr,dbit error not correct, wd_tmp= 'h%h  rd_tmp= 'h%h",cfg_ram.get_name(),ram_addr,wd_tmp,rd_tmp),UVM_LOW);
            end
        end
		
        //@(posedge `GLB_CLK);
        //#1ns;
        //uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
        //if(ecc_status!=1) begin
        //    `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h, after write inject addr,read inject addr,ecc_err is not 1",cfg_ram.get_name(),ram_addr));
        //end
		if(ecc_debug_ecc_err_reg!=null) begin
			ecc_debug_ecc_err_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			if(rd_tmp[ecc_debug_ecc_err_offset] != 1) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_ecc_err status check fail expect is 1,real is 0",cfg_ram.get_name(),ram_addr));
			end
		end
		if(ecc_debug_sdbit_err_reg!=null) begin
			ecc_debug_sdbit_err_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			if(rd_tmp[ecc_debug_sdbit_err_offset] != 1) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_sdbit_err status check fail expect is 1,real is 0",cfg_ram.get_name(),ram_addr));
			end
		end
		if(ecc_debug_sdbit_addr_reg!=null) begin
			ecc_debug_sdbit_addr_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			for(int i=0; i < ram_depth; i++) begin
				ecc_addr[i] = rd_tmp[ecc_debug_sdbit_addr_offset+i];
			end
			if(ecc_addr != ram_addr) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_sdbit_addr check fail expect is 'h%h,real is 'h%h",cfg_ram.get_name(),ram_addr,ram_addr,ecc_addr));
			end
		end
		
        //3、回刷：写1清中断状态寄存器对应bit，写注错地址寄存器清除该ram的ecc故障，检查中断不再产生
        cfg_ram = get_uvm_reg_by_str(tbl_ral_str,ram_addr);
        cfg_ram.write(status, $urandom(),UVM_FRONTDOOR);
        //cfg_ram.write(status, $urandom(),UVM_FRONTDOOR);
        cfg_ram.read(status, rd_tmp,UVM_FRONTDOOR);

        @(posedge `GLB_CLK);
        #1ns;
        uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
        if(ecc_status!=0) begin
            `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h , after back brush ecc_err is not 0",cfg_ram.get_name(),ram_addr));
        end

        `uvm_info(get_name(),$psprintf("ram_name = %s ram_addr='h%h inject sbiterr/dbiterr test end", cfg_ram.get_name(),ram_addr), UVM_LOW);

    endtask:cfgram_ecc_inject_test
	
    task dataram_inject_test(string fiforam_path,string ramdata_path,string w_en,string r_en,string cs_n,string wdin,string rclk,string wclk,string waddr,string raddr,int ram_type,int ram_depth,int ram_width,int ram_addr,uvm_reg ecc_debug_ecc_err_reg,int ecc_debug_ecc_err_offset,uvm_reg ecc_debug_sdbit_err_reg,int ecc_debug_sdbit_err_offset,uvm_reg ecc_debug_sdbit_addr_reg,int ecc_debug_sdbit_addr_offset,int ecc_flag,int sbit_flag); 
        bit[31:0]     int_tmp        ;
        bit[31:0]     int_tmp_r      ;
        bit[511:0]    ram_mask       ;
        bit[511:0]    wd_tmp         ;
        bit[511:0]    rd_tmp         ;
        bit[31:0]     ecc_status     ;
        bit[31:0]     ecc_addr       ;
        uvm_status_e  status         ;
        int           int_value = 1  ;
        int           r_int_value    ;
        int           sbit_inject_pos;
        int           dbit_inject_pos;
        string        split_val[$]   ;
        string        fifo_path = "" ;
        uvm_reg       cfg_ram        ;
        int           start_addr     ;
        int           end_addr       ;
        int           ram_out_reg    ;
        int           fifo_flag      ;
        if(ram_addr==0) begin
            start_addr = 0;
            end_addr   = ((2**ram_depth-10)>0)?10:(2**ram_depth);
        end
        else if(ram_addr!=2**ram_depth) begin
            start_addr = ((ram_addr-5)>0)?(ram_addr-5):0;
            end_addr   = ((ram_addr+5) < (2**ram_depth))?(ram_addr+5):(2**ram_depth);
        end
        else begin
            start_addr = ((2**ram_depth-10)>0)?(2**ram_depth-10):0;
            end_addr   = 2**ram_depth;
        end

        if(!(uvm_re_match("/.*fifo.*/",fiforam_path)) || !(uvm_re_match("/.*info.*/",fiforam_path)) || !(uvm_re_match("/.*FIFO.*/",fiforam_path)) || !(uvm_re_match("/.*INFO.*/",fiforam_path))) begin
            uvm_split_string(fiforam_path,".",split_val);
            for(int i = 0; i < split_val.size - 2; i++) begin
                if(i!=0) begin
                    fifo_path = {fifo_path,".",split_val[i]};
                end
                else begin
                    fifo_path = split_val[0];
                end
            end
            fifo_flag = 1;
        end
        else begin
            fifo_flag = 0;
        end
        if(fifo_flag == 0)begin
            uvm_hdl_read($psprintf("%s.RAM_OUT_REG",fiforam_path),ram_out_reg);
        end
        else begin
            uvm_hdl_read($psprintf("%s.RAM_OUT_REG",fifo_path),ram_out_reg);
        end
        `uvm_info(get_name(),$psprintf("dataram_inject_test fifo_path= %s fiforam_path= %s ram_out_reg = %0d", fifo_path,fiforam_path,ram_out_reg), UVM_LOW);

        ram_mask = {ram_width{1'b1}};
        `uvm_info(get_name(),$psprintf("ram_name = %s ram_type = %d ram_addr='h%h inject ecc_flag=%0d sbit_flag=%0d test begin", fiforam_path,ram_type,ram_addr,ecc_flag,sbit_flag), UVM_LOW);

        sbit_inject_pos       = $urandom_range(0,ram_depth-1)      ;
        dbit_inject_pos       = $urandom_range(1,ram_depth-1)      ;
        //1、注错：写注错地址周围10个左右其他地址,读注错地址周围10个左右其他地址，写注错地址，注错，读注错地址 
        wd_tmp = {16{$urandom()}} & ram_mask;
        if(ram_type== 3) begin
            for(int i=start_addr; i<end_addr;i++) begin
                if(i!=ram_addr) begin
                  @(posedge `GLB_CLK);
                  #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0)     ;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1)     ;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),i);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),{16{$urandom()}} & ram_mask)   ;
                    `uvm_info(get_name(),$psprintf("SP_WRAP first wd_tmp='h%h", {16{$urandom()}} & ram_mask), UVM_LOW);
                end
            end
            for(int i=start_addr; i<end_addr;i++) begin
                if(i!=ram_addr) begin
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
                    #100ns;
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),i);
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
                    @(posedge `GLB_CLK);
                    #1ns;

                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,cs_n)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr));
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));
                    
                    repeat(ram_out_reg) @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
                    if(ecc_status!=0) begin
                        `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h read_addr='h%h, after write not inject addr,read not inject addr,ecc_err is not 0",fiforam_path,ram_addr,i));
                    end
                end
            end
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0)     ;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1)     ;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),ram_addr);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),wd_tmp)   ;
            `uvm_info(get_name(),$psprintf("SP_WRAP first wd_tmp='h%h", wd_tmp), UVM_LOW);
            @(posedge `GLB_CLK);
            uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
            `uvm_info(get_name(),$psprintf("SP_WRAP first rd_tmp='h%h", rd_tmp), UVM_LOW);
            if(sbit_flag || !ecc_flag) begin
                uvm_hdl_force($psprintf("%s.%s[%0d]",fiforam_path,ramdata_path,sbit_inject_pos),~wd_tmp[sbit_inject_pos]);
                uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
                `uvm_info(get_name(),$psprintf("SP_WRAP %s insert 1 bit wrong value at address='h%h err_data='h%h",fiforam_path,ram_addr,rd_tmp), UVM_LOW);
            end
            else begin
                uvm_hdl_force($psprintf("%s.%s[0]",fiforam_path,ramdata_path),~wd_tmp[0]);
                uvm_hdl_force($psprintf("%s.%s[%0d]",fiforam_path,ramdata_path,dbit_inject_pos),~wd_tmp[dbit_inject_pos]);
                uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
                `uvm_info(get_name(),$psprintf("SP_WRAP %s insert 2 bit wrong value at address='h%h err_data='h%h",fiforam_path,ram_addr,rd_tmp), UVM_LOW);
            end
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            #100ns;
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),ram_addr);
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            @(posedge `GLB_CLK);
            #1ns;

            uvm_hdl_release($psprintf("%s.%s",fiforam_path,cs_n)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr));
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));

            repeat(ram_out_reg) @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,ramdata_path));
            uvm_hdl_read($psprintf("%s.q",fiforam_path),rd_tmp);
        end
        else begin
            for(int i=start_addr; i<end_addr;i++) begin
                if(i!=ram_addr) begin
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),i);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),{16{$urandom()}} & ram_mask);
                   `uvm_info(get_name(),$psprintf("NO_SP_WRAP first wd_tmp='h%h", {16{$urandom()}} & ram_mask), UVM_LOW);
                end
            end
            for(int i=start_addr; i<end_addr;i++) begin
                if(i!=ram_addr) begin
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
                    #100ns;
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b1);
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),i);
                    @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b0);

                    if(fifo_flag) begin
                        uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b1);
                        @(posedge `GLB_CLK);
                        uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b0);
                        @(posedge `GLB_CLK);
                    end
                    @(posedge `GLB_CLK);
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin));
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,r_en)) ;
                    uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));
                    repeat(ram_out_reg) @(posedge `GLB_CLK);
                    #1ns;
                    uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
                    if(ecc_status!=0) begin
                        `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h read_addr='h%h, after write not inject addr,read not inject addr,ecc_err is not 0",fiforam_path,ram_addr,i));
                    end
               end
            end
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),ram_addr);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),wd_tmp);
            `uvm_info(get_name(),$psprintf("NO_SP_WRAP first wd_tmp='h%h", wd_tmp), UVM_LOW);

            @(posedge `GLB_CLK);
            uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
            `uvm_info(get_name(),$psprintf("NOT_SP_WRAP first rd_tmp='h%h", rd_tmp), UVM_LOW);
            if(sbit_flag || !ecc_flag) begin
                uvm_hdl_force($psprintf("%s.%s[%0d]",fiforam_path,ramdata_path,sbit_inject_pos),~wd_tmp[sbit_inject_pos]);
                uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
                `uvm_info(get_name(),$psprintf("NOT_SP_WRAP %s insert 1 bit wrong value at address='h%h err_data='h%h",fiforam_path,ram_addr,rd_tmp), UVM_LOW);
            end
            else begin
                uvm_hdl_force($psprintf("%s.%s[0]",fiforam_path,ramdata_path),~wd_tmp[0]);
                uvm_hdl_force($psprintf("%s.%s[%0d]",fiforam_path,ramdata_path,dbit_inject_pos),~wd_tmp[dbit_inject_pos]);
                uvm_hdl_read($psprintf("%s.%s",fiforam_path,ramdata_path),rd_tmp);
                `uvm_info(get_name(),$psprintf("NOT_SP_WRAP %s insert 2 bit wrong value at address='h%h err_data='h%h",fiforam_path,ram_addr,rd_tmp), UVM_LOW);
            end
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            #100ns;
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),ram_addr);
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b0);

            if(fifo_flag) begin
                uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b1);
                @(posedge `GLB_CLK);
                uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b0);
                repeat(ram_out_reg) @(posedge `GLB_CLK);
                uvm_hdl_read($psprintf("%s.q",fiforam_path),rd_tmp);
                uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
                if(ecc_status!=1) begin
                    `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h, after write inject addr,read inject addr,ecc_err is not 1",fiforam_path,ram_addr));
                end
            end

            @(posedge `GLB_CLK);
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin));
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,r_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));

            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,ramdata_path));
        end
        //2、检查：读注错地址周围10个地址，检查没有中断产生
        //       读注错地址,检查中断寄存器和中断调试寄存器，预期中断拉起，单bit注错时 ecc_err和sbiterr拉高，单bit错误可纠 
        //       多bit注错时 ecc_err和dbiterr拉高，多bit错误不可纠 ，ecc_addr为对应注入地址A
        //uvm_hdl_read($psprintf("%s.q",fiforam_path),rd_tmp);
        if(sbit_flag) begin
            if((rd_tmp & ram_mask)!= wd_tmp) begin
                `uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject sbiterr,sbit error not correct, wd_tmp= 'h%h  rd_tmp= 'h%h",fiforam_path,ram_addr,wd_tmp,rd_tmp));
            end
        end
        else begin
            if((rd_tmp & ram_mask)!= wd_tmp) begin
                `uvm_info(get_name, $psprintf("ram_name = %s ram_addr='h%h after inject dbiterr or prtyerr,dbit error not correct, wd_tmp= 'h%h  rd_tmp= 'h%h",fiforam_path,ram_addr,wd_tmp,rd_tmp),UVM_LOW);
            end
        end
        if(!fifo_flag) begin
            uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
            if(ecc_status!=1) begin
                `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h, after write inject addr,read inject addr,ecc_err is not 1",fiforam_path,ram_addr));
            end
        end
		
		if(ecc_debug_ecc_err_reg!=null) begin
			ecc_debug_ecc_err_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			if(rd_tmp[ecc_debug_ecc_err_offset] != 1) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_ecc_err status check fail expect is 1,real is 0",fiforam_path,ram_addr));
			end
		end
		if(ecc_debug_sdbit_err_reg!=null) begin
			ecc_debug_sdbit_err_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			if(rd_tmp[ecc_debug_sdbit_err_offset] != 1) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_sdbit_err status check fail expect is 1,real is 0",fiforam_path,ram_addr));
			end
		end
		if(ecc_debug_sdbit_addr_reg!=null) begin
			ecc_debug_sdbit_addr_reg.read(status, rd_tmp,UVM_FRONTDOOR);
			for(int i=0; i < ram_depth; i++) begin
				ecc_addr[i] = rd_tmp[ecc_debug_sdbit_addr_offset+i];
			end
			if(ecc_addr != ram_addr) begin
				`uvm_error(get_type_name, $psprintf("ram_name = %s ram_addr='h%h after inject err,ecc_debug_sdbit_addr check fail expect is 'h%h,real is 'h%h",fiforam_path,ram_addr,ram_addr,ecc_addr));
			end
		end
		
        //3、回刷：写1清中断状态寄存器对应bit，写注错地址寄存器清除该ram的ecc故障，检查中断不再产生
        if(ram_type== 3) begin
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),ram_addr);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),wd_tmp);
            `uvm_info(get_name(),$psprintf("SP_WRAP second wd_tmp='h%h", wd_tmp), UVM_LOW);
            @(posedge `GLB_CLK);
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,cs_n)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr));
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin)) ;
        end
        else begin
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),32'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,waddr),ram_addr);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,wdin),wd_tmp);
            `uvm_info(get_name(),$psprintf("NO_SP_WRAP second wd_tmp='h%h", wd_tmp), UVM_LOW);

            @(posedge `GLB_CLK);
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,waddr)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,wdin));
        end
        if(ram_type == 3) begin
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            #100ns;
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b0);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),ram_addr);
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,cs_n),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,cs_n)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));

        end
        else begin
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,w_en),1'b0);
            #100ns;
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b1);
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,raddr),ram_addr);
            @(posedge `GLB_CLK);
            #1ns;
            uvm_hdl_force($psprintf("%s.%s",fiforam_path,r_en),1'b0);

            if(fifo_flag) begin
                uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b1);
                @(posedge `GLB_CLK);
                uvm_hdl_force($psprintf("%s.fifo_ren",fifo_path),1'b0);
                @(posedge `GLB_CLK);
            end

            @(posedge `GLB_CLK);
            #1ns;

            uvm_hdl_release($psprintf("%s.%s",fiforam_path,w_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,r_en)) ;
            uvm_hdl_release($psprintf("%s.%s",fiforam_path,raddr));

        end        
        repeat(ram_out_reg) @(posedge `GLB_CLK);
        uvm_hdl_read($psprintf("%s.q",fiforam_path),rd_tmp);
        @(posedge `GLB_CLK);
        #1ns;
        uvm_hdl_read($psprintf("%s.ecc_err",fiforam_path),ecc_status);
        if(ecc_status!=0) begin
            `uvm_error(get_type_name, $psprintf("ram_name = %s inject_addr='h%h , after back brush ecc_err is not 0",fiforam_path,ram_addr));
        end
        `uvm_info(get_name(),$psprintf("ram_name = %s ram_type = %d ram_addr='h%h inject ecc_flag=%0d sbit_flag=%0d test end", fiforam_path,ram_type,ram_addr,ecc_flag,sbit_flag), UVM_LOW);

    endtask:dataram_inject_test

    task ram_ecc_call_test(); 		
		bit           ignore_flag                   ;
		bit           inject_ram_en                    ;
        bit           ecc_en                        ;
		int           ram_type                      ;
        string        fiforam_path                  ;
        string        ramdata_path                  ;
        string        tbl_ral_str                   ;
        bit[511:0]    tbl_mask                      ;
        uvm_reg       ecc_inject_reg                ;
		uvm_reg       ecc_debug_ecc_err_reg         ;
		uvm_reg       ecc_debug_sbit_err_reg        ;
		uvm_reg       ecc_debug_sbit_addr_reg       ;
		uvm_reg       ecc_debug_dbit_err_reg        ;
		uvm_reg       ecc_debug_dbit_addr_reg       ;
        int           ecc_inject_offset             ;
		int           ecc_debug_ecc_err_offset      ;
		int           ecc_debug_sbit_err_offset     ;
		int           ecc_debug_sbit_addr_offset    ;
		int           ecc_debug_dbit_err_offset     ;
		int           ecc_debug_dbit_addr_offset    ;
		int           ram_depth = 1                 ; // +
		uvm_reg       cfg_ram                       ; // +

        int           ram_addr          ;
		int           ram_width         ;
        int           dp_port_no        ;

        string        w_en              ;
        string        r_en              ;
        string        cs_n              ;
        string        wdin              ;
        string        rclk              ;
        string        wclk              ;
        string        waddr             ;
        string        raddr             ;

        for(int i = 0; i < $size(reg_info_class_detail.int_status_ecc_reg_list); i++) begin
            if(!reg_info_class_detail.int_status_ecc_reg_list[i].ignore_flag) begin
                inject_ram_en                 = reg_info_class_detail.int_status_ecc_reg_list[i].inject_ram_en                ;
                ecc_en                     = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_en                    ;
                ram_type                   = reg_info_class_detail.int_status_ecc_reg_list[i].ram_type                  ;
                fiforam_path               = reg_info_class_detail.int_status_ecc_reg_list[i].fiforam_path              ;
                ramdata_path               = reg_info_class_detail.int_status_ecc_reg_list[i].ramdata_path              ;
                tbl_ral_str                = reg_info_class_detail.int_status_ecc_reg_list[i].tbl_ral_str               ;
                tbl_mask                   = reg_info_class_detail.int_status_ecc_reg_list[i].tbl_mask                  ;
                ecc_inject_reg             = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_inject_reg            ;
                ecc_inject_offset          = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_inject_offset         ;
                ecc_debug_ecc_err_reg      = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_ecc_err_reg     ;
                ecc_debug_ecc_err_offset   = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_ecc_err_offset  ;
                ecc_debug_sbit_err_reg     = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_sbit_err_reg    ;
                ecc_debug_sbit_err_offset  = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_sbit_err_offset ;
                ecc_debug_sbit_addr_reg    = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_sbit_addr_reg   ;
                ecc_debug_sbit_addr_offset = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_sbit_addr_offset;
                ecc_debug_dbit_err_reg     = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_dbit_err_reg    ;
                ecc_debug_dbit_err_offset  = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_dbit_err_offset ;
                ecc_debug_dbit_addr_reg    = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_dbit_addr_reg   ;
                ecc_debug_dbit_addr_offset = reg_info_class_detail.int_status_ecc_reg_list[i].ecc_debug_dbit_addr_offset;

				dataram_wr_clk_trans(fiforam_path,dp_port_no,w_en,r_en,cs_n,wdin,rclk,wclk,waddr,raddr,ram_type,ram_depth,ram_width);

                for(int j = 0; j < 3; j++) begin
                    if(j==0) begin
                        ram_addr = 0;
                    end
                    else if(j==1) begin
                        ram_addr = $urandom() & {ram_depth{1'b1}};
                    end
                    else begin
                        ram_addr = {ram_depth{1'b1}};
                    end
                    if(inject_ram_en) begin
                        cfgram_ecc_inject_test(tbl_ral_str,ram_depth,tbl_mask,ram_addr,ecc_inject_reg,ecc_inject_offset,ecc_debug_ecc_err_reg,ecc_debug_ecc_err_offset,ecc_debug_sbit_err_reg,ecc_debug_sbit_err_offset,ecc_debug_sbit_addr_reg,ecc_debug_sbit_addr_offset,fiforam_path,ramdata_path,1);
						cfgram_ecc_inject_test(tbl_ral_str,ram_depth,tbl_mask,ram_addr,ecc_inject_reg,ecc_inject_offset,ecc_debug_ecc_err_reg,ecc_debug_ecc_err_offset,ecc_debug_dbit_err_reg,ecc_debug_dbit_err_offset,ecc_debug_dbit_addr_reg,ecc_debug_dbit_addr_offset,fiforam_path,ramdata_path,0);
                    end
                    else begin
                        if(ecc_en) begin
                            dataram_inject_test(fiforam_path,ramdata_path,w_en,r_en,cs_n,wdin,rclk,wclk,waddr,raddr,ram_type,ram_depth,ram_width,ram_addr,ecc_debug_ecc_err_reg,ecc_debug_ecc_err_offset,ecc_debug_sbit_err_reg,ecc_debug_sbit_err_offset,ecc_debug_sbit_addr_reg,ecc_debug_sbit_addr_offset,1,1);
							dataram_inject_test(fiforam_path,ramdata_path,w_en,r_en,cs_n,wdin,rclk,wclk,waddr,raddr,ram_type,ram_depth,ram_width,ram_addr,ecc_debug_ecc_err_reg,ecc_debug_ecc_err_offset,ecc_debug_dbit_err_reg,ecc_debug_dbit_err_offset,ecc_debug_dbit_addr_reg,ecc_debug_dbit_addr_offset,1,0);
                        end
                        else begin
                            dataram_inject_test(fiforam_path,ramdata_path,w_en,r_en,cs_n,wdin,rclk,wclk,waddr,raddr,ram_type,ram_depth,ram_width,ram_addr,ecc_debug_ecc_err_reg,ecc_debug_ecc_err_offset,ecc_debug_sbit_err_reg,ecc_debug_sbit_err_offset,ecc_debug_sbit_addr_reg,ecc_debug_sbit_addr_offset,0,0);
                        end
                    end
                end
            end
        end

    endtask:ram_ecc_call_test

    virtual task configure_phase(uvm_phase phase);
        //super.configure_phase(phase);
        phase.raise_objection(this);
        #10us;
        reg_info_class_detail.reg_ecc_info_get();
        key_status_dfx_chk_en   = 0;
        cnt_dfx_chk_en          = 0;
        trace_dfx_chk_en        = 0;
        abnormal_dfx_chk_en     = 0;
        force tb_top.u_ped_seg_top.u_ped.u_ped_phe.fsm_start_flag = 0;
        force tb_top.u_ped_seg_top.u_seg.fsm_start_flag = 0;
        #10ns;
        ram_ecc_call_test();
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.drop_objection(this);
    endtask:configure_phase

    virtual task main_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endtask:main_phase

    virtual task post_main_phase(uvm_phase phase);
        super.post_main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        phase.raise_objection(this);

        phase.drop_objection(this);
    endtask:post_main_phase

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if($test$plusargs("UVM_VERBOSITY=UVM_DEBUG"))begin
            check_config_usage();
        end
        `uvm_info(get_type_name(),"check_phase():check_phase() finished", UVM_HIGH);
        phase.phase_done.display_objections();
    endfunction:check_phase

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction:report_phase

endclass

`undef TC
`endif // svf_ram_ecc_test_CLASS
