// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : tc_reg_test.sv
// Author         : zengwenhua/z00472263
// Date           : 2020/06/10
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2020/06/10 zengwenhua  1.00 Create
// 
// ***********************************************************************
// DEFINE 
// ***********************************************************************
// Module 		: 
// Called by 	: 
// ***********************************************************************
// $Log: 
// 
// ***********************************************************************
typedef class basic_tc                      ;
class tc_reg_test extends basic_tc          ;
    `uvm_component_utils(tc_reg_test)
    typedef enum {REG_INIT, REG_RW, REG_PROPERTY, REG_DATA_GLUE, REG_ADDR_GLUE, REG_ALL_ADDR, REG_ALL} reg_test_item_e;
    reg_test_item_e         reg_test_item[$]            ;
    int                     first_addr, last_addr       ;
    bit [31:0]              invalid_data                ;
    //**************************************************************************************************//
    reg_test_task           u_reg_test                  ;
    uvm_reg                 regs[$]                     ;
    uvm_status_e            vr_status                   ;
    int                     exclude_address[$]          ;
    int                     value                       ;
    int                     reg_test_no=16'hFFFF        ;
    extern function new(string name="tc_reg_test", uvm_component parent)        ;
    extern virtual task rw_rst_cmd()                                            ;
    extern virtual function void build_phase(uvm_phase phase)                   ;
    extern virtual function void connect_phase(uvm_phase phase)                 ;
    extern virtual task run_phase(uvm_phase phase)                              ;
    extern virtual function void report_test_result()                           ;
    extern virtual function bit get_reg_access(uvm_reg v_reg, string access)    ;
endclass:tc_reg_test
//========================================================================================================
//
//========================================================================================================
function tc_reg_test::new(string name="tc_reg_test" , uvm_component parent)    ;
    super.new(name, parent);
endfunction:new
//========================================================================================================
//
//========================================================================================================
function void tc_reg_test::build_phase(uvm_phase phase)             ;
    super.build_phase(phase);
    `uvm_info(get_type_name(), $sformatf("reg_test_no=%0d (0-init 1-rw 2-property 3-data_glue 4-addr_glue 5-all_addr)", this.reg_test_no), UVM_NONE);
    if (this.reg_test_no == 'd0) this.reg_test_item.push_back(REG_INIT)             ;
    if (this.reg_test_no == 'd1) this.reg_test_item.push_back(REG_RW)               ;
    if (this.reg_test_no == 'd2) this.reg_test_item.push_back(REG_PROPERTY)         ;
    if (this.reg_test_no == 'd3) this.reg_test_item.push_back(REG_DATA_GLUE)        ;
    if (this.reg_test_no == 'd4) this.reg_test_item.push_back(REG_ADDR_GLUE)        ;
    if (this.reg_test_no == 'd5) this.reg_test_item.push_back(REG_ALL_ADDR)         ;
endfunction:build_phase
//========================================================================================================
//
//========================================================================================================
function void tc_reg_test::connect_phase(uvm_phase phase)           ;
    super.connect_phase(phase)              ;
    this.u_reg_test = new                   ;
    reg_model.get_registers(regs)           ;
    if(last_addr>first_addr)begin
    	`SET_VLD_ADDR(first_addr,last_addr)
    end
    `EXCLUDE_ACCESS_REG("pl_len_tb")
    `EXCLUDE_ACCESS_REG("cfg_wl_tb")
endfunction:connect_phase
//========================================================================================================
//
//========================================================================================================
task tc_reg_test::run_phase(uvm_phase phase)                        ;
    uvm_status_e        status  ;
    uvm_reg             vr_reg  ;
    logic [31:0]        vr_data ;
    //super.run_phase(phase)      ;
    phase.raise_objection(this);
    if(this.reg_test_item.size() ==0) this.reg_test_item.push_back(REG_RW) ;
    //***********************************************************************************************************************************//
    if(REG_INIT inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item}))begin
        `uvm_info(get_type_name(), $psprintf("start reg initial value test"), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        reg_model.reset()                                           ;
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ;
        u_reg_test.reg_write(regs, 32'hffff_ffff, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT); 

        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ; 
        u_reg_test.reg_write(regs, 32'h0, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);

        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ;
        `uvm_info(get_type_name(), $psprintf("reg initial value test done"), UVM_LOW);
    end
    //***********************************************************************************************************************************//
    if(REG_RW inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item}))begin
        `uvm_info(get_type_name(), $psprintf("start reg rw test"), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
        u_reg_test.reg_rw_read(regs, reg_test_dec::ACCESS_ORDER)    ;
        u_reg_test.reg_rw_write_read(regs, 32'h5555_5555, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);
        u_reg_test.reg_rw_write_read(regs, 32'haaaa_aaaa, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);
        `uvm_info(get_type_name(), $psprintf("reg rw test done"), UVM_LOW);
    end
    //***********************************************************************************************************************************//
    if(REG_PROPERTY inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item})) begin
        `uvm_info(get_type_name(), $psprintf("start reg property test"), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
        u_reg_test.reg_write(regs, 32'hffff_ffff, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ;

        u_reg_test.reg_write(regs, 32'h0, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ;

        u_reg_test.reg_write(regs, 32'hffff_ffff, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);
        u_reg_test.reg_read(regs, reg_test_dec::ACCESS_ORDER)       ;
        `uvm_info(get_type_name(), $psprintf("reg property test done"), UVM_LOW);
    end
    //***********************************************************************************************************************************//
    if(REG_DATA_GLUE inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item}))begin
        `uvm_info(get_type_name(), $psprintf("start reg data glue test"), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
        //==1.write one_hot value to areg then read.
        u_reg_test.bit_glue_chk(regs, 32'h1)                        ;

        //==2.write one_hot_reverse value to areg then read.        ;
        u_reg_test.bit_glue_chk(regs, 32'hffff_fffe)                ;
        `uvm_info(get_type_name(), $psprintf("reg data glue  test done"), UVM_LOW);
    end
    //***********************************************************************************************************************************//
    if(REG_ADDR_GLUE inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item}))begin
        `uvm_info(get_type_name(), $psprintf("start reg addr glue test"), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;
       
        //==2.write 55 to all reg
        u_reg_test.reg_write(regs, 32'h5555_5555, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);

        //==3.read 55 and write aa for per reg(in order)
        u_reg_test.reg_rw_read_write(regs, 32'haaaa_aaaa, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);

        //==4.read aa and write 55 for per reg(reverse order)
        u_reg_test.reg_rw_read_write(regs, 32'h5555_5555, reg_test_dec::ACCESS_REVER, UVM_FRONTDOOR, reg_test_dec::W_DEFAULT);

        //==5.read 55 and write random for per reg(in order)
        u_reg_test.reg_rw_read_write(regs, 32'haaaa_aaaa, reg_test_dec::ACCESS_ORDER, UVM_FRONTDOOR, reg_test_dec::W_RANDOM);

        //==6.read random and write random for per reg(reverse order)
        u_reg_test.reg_rw_read_write(regs, 32'haaaa_aaaa, reg_test_dec::ACCESS_REVER, UVM_FRONTDOOR, reg_test_dec::W_RANDOM);

        //==7.read random for all reg
        u_reg_test.reg_rw_read(regs, reg_test_dec::ACCESS_ORDER);
        `uvm_info(get_type_name(), $psprintf("reg addr glue  test done"), UVM_LOW);
    end
    //***********************************************************************************************************************************//
    if( (REG_ALL_ADDR inside {this.reg_test_item} || (REG_ALL inside {this.reg_test_item})) ) begin
        `uvm_info(get_type_name(), $psprintf("start reg all addr test"), UVM_LOW);
        `uvm_info(get_type_name(), $psprintf("start write random to address:%h~%h.", this.first_addr, this.last_addr), UVM_LOW);
        this.rw_rst_cmd()                                           ;
        this.reg_model.reset()                                      ;

        for(int address=this.first_addr; address<=this.last_addr; address++) begin
            if(address inside {this.exclude_address})begin
                `uvm_info(get_type_name(), $sformatf("exclude addr:%0h.", address), UVM_NONE);
            end
            else begin
                std::randomize( value );
                vr_reg=this.reg_model.default_map.get_reg_by_offset(address);
                if(vr_reg != null) vr_reg.write(status, value);
                else begin
                    this.u_env.u_bfm_cbus.write(address, value);
                    this.u_env.u_bfm_cbus.read(address, vr_data);
                    if(vr_data != invalid_data) begin
                        `uvm_error(get_type_name(), $sformatf("Invalid addr  is not 0xdead_beef, addr=0x%0h.", address));
                    end
                end
            end

            `uvm_info(get_type_name(), $sformatf("start check address:%0h~%0h", this.first_addr, this.last_addr), UVM_LOW);
            foreach(regs[i]) begin
                if(this.get_reg_access(regs[i], "RW") ==1) begin
                    regs[i].mirror(status, UVM_CHECK);
                end else begin
                    regs[i].read(status, value);
                end
            end
        end
    end
    //***********************************************************************************************************************************//
    phase.drop_objection(this)  ;
    this.report_test_result()   ;
endtask:run_phase
//========================================================================================================
//
//========================================================================================================
function void tc_reg_test::report_test_result()                             ;
    uvm_report_server   report_svr = uvm_report_server::get_server()        ;
    int count_fatal = report_svr.get_severity_count(UVM_FATAL)              ;
    int count_err   = report_svr.get_severity_count(UVM_ERROR)              ;
    int count_warning = report_svr.get_severity_count(UVM_WARNING)          ;

    if(count_fatal == 0) begin
        if(count_err == 0) begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation PASSED at%15t (%0d warning) \n" ,
                        $realtime, count_warning), UVM_NONE)
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t (%0d errors, %0d warning) \n" ,
                        $realtime,count_err, count_warning), UVM_NONE)
        end
    end
    else begin
        `uvm_info(get_type_name(), $sformatf("\n\nSimulation *FAILED* at%15t (%0d fatals, %0d errors, %0d warning) \n" ,
                        $realtime,count_fatal, count_err, count_warning), UVM_NONE)
    end
endfunction:report_test_result
//========================================================================================================
//
//========================================================================================================
function bit tc_reg_test::get_reg_access(uvm_reg v_reg, string access)      ;
    uvm_reg_field   fields[$]   ;
    v_reg.get_fields(fields)    ;
    foreach(fields[i]) begin
        if(fields[i].get_access()==access) return 1;
    end
    return 0;
endfunction:get_reg_access

task tc_reg_test::rw_rst_cmd();

endtask:rw_rst_cmd
