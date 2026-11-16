// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : reg_test_define.sv
// Author         : zengwenhua/z00472263
// Date           : 2020/06/11
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2020/06/11 zengwenhua  1.00 Create
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

`ifndef REG_TEST_DEFINE__SV
`define REG_TEST_DEFINE__SV
`define VMM_RAL_DATA_WIDTH 32
`define SET_COMPLIMENT_VALUE(regs) \
    regs.get_fields(fields); \
    foreach(fields[j]) begin \
        string          vr_fields_name  ;\
        uvm_reg_data_t  v               ;\
        uvm_reg_data_t  vr_size         ;\
        vf_field_name   = fields[j].get_name()  ;\
        if(vf_field_name.compare("rsv_") == 1) begin\
            `uvm_info("", $sformatf("Register \"%s\" has a reserved filed", regs.get_full_name()), UVM_DEBUG);\
        end\
        else begin\
            v = fields[j].get();\
            `uvm_info("", $sformatf("Set_compliment_value, regs_name =%s, field_name=%s, old_value=%b", regs.get_full_name(), vr_field_name, v), UVM_DEBUG);\
            vr_size = fields[j].get_n_bits();\
            for(int i=0; i<vr_size; i++) begin\
                vr_bit_l.push_back(~vr_value[i]);\
            end\
        end\
    end\
    foreach(vr_bit_l[i]) begin\
        vr_v[i] = vr_bit_l[i];\
    end\
    `uvm_info("", $sformatf("Set_compliment_value, regs_name =%s, field_name=%s, new_value=%b", regs.get_full_name(), vr_field_name, vr_v), UVM_DEBUG);\
    vr_bit_l.delete();

`define SET_RANDOM_VALUE(regs) \
    regs.get_fields(fields); \
    foreach(fields[j]) begin \
        string          vr_fields_name  ;\
        uvm_reg_data_t  v               ;\
        uvm_reg_data_t  vr_size         ;\
        vf_field_name   = fields[j].get_name()  ;\
        if(vf_field_name.compare("rsv_") == 1) begin\
            `uvm_info("", $sformatf("Register \"%s\" has a reserved filed", regs.get_full_name()), UVM_DEBUG);\
        end\
        else begin\
            v = $urandom_range(0, {`VMM_RAL_DATA_WIDTH{1'b1}});\
            vr_size = fields[j].get_n_bits();\
            for(int i=0; i<vr_size; i++) begin\
                vr_bit_l.push_back(v[i]);\
            end\
            `uvm_info("", $sformatf("Set_compliment_value, regs_name =%s, field_name=%s, rand_value=%b", regs.get_full_name(), vr_field_name, v), UVM_DEBUG);\
        end\
    end\
    foreach(vr_bit_l[i]) begin\
        vr_v[i] = vr_bit_l[i];\
    end\
    vr_bit_l.delete();

`define SET_ACCESS_ORDER \
    if(order == reg_test_dec::ACCESS_ORDER) begin \
        `uvm_info("", "Access registers in order ...", UVM_NONE);\
    end\
    else if(order == reg_test_dec::ACCESS_REVER) begin\
        `uvm_info("", "Access register in reverse ...", UVM_NONE);\
        vr_regs = regs;\
        vr_size = regs.size;\
        for(int i=0; i<vr_size; i++) begin\
            regs[i] = vr_regs[vr_size-1-i] ;\
        end\
    end\
    else begin\
        `uvm_info("", "Access register in random ...", UVM_NONE);\
        vr_regs = regs;\
        vr_size = regs.size;\
        vr_rr = new(vr_size);\
        for(int i=0; i<vr_size; i++) begin\
            vr_rr.randomize();\
            regs[vr_rr.value] = vr_regs[i] ;\
        end\
    end

`define GET_REGS_PROPERTY\
    string vr_domains[]; \
    uvm_reg_field vr_fields[$];\
    int vr_len;\
    \
    vr_domains = new[1];\
    vr_domains[0] = "default";\
    \
    vr_reg_name = regs[i].get_name;\
    regs[i].get_fields(vr_fields);\
    vr_reg_access = "USER1" ; \
    vr_len = vr_reg_name.len();\
    foreach(vr_fields[j]) begin \
        string      vr_field_access ;\
        string      vr_field_name   ;\
        uvm_reg_data_t  v           ;\
        vr_field_name = vr_fields[j].get_name();\
        vr_field_access = vr_fields[j].get_access();\
        if(vr_field_access == "RW") begin\
            if(vr_field_name.substr(0,3) == "rsv_") begin \
                `uvm_info("", $sformatf("Register \"%s\" has a reserved field", regs[i].get_full_name()), UVM_LOW); \
            end \
            else if(vr_reg_access == "RO") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RW and RO field",regs[i].get_full_name()), UVM_LOW); \
            end \
            else if(vr_reg_access == "RC") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RW and RC field",regs[i].get_full_name()), UVM_LOW); \
            end \
            else begin \
                vr_reg_access = "RW";\
            end\
        end\
        else if(vr_field_access == "RO") begin\
            if(vr_field_name.substr(0,3) == "rsv_") begin\
                `uvm_info("", $sformatf("Register \"%s\" has a reserved field",regs[i].get_full_name()), UVM_LOW);\
            end\
            else if(vr_reg_access == "RW") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RO and RW field",regs[i].get_full_name()), UVM_LOW);\
            end \
            else if(vr_reg_access == "RC") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RO and RC field",regs[i].get_full_name()), UVM_LOW);\
            end \
            else begin\
                vr_reg_access = "RO";\
            end \
        end\
        else if(vr_field_access == "RC") begin\
            if(vr_field_name.substr(0,3) == "rsv_") begin\
                `uvm_info("", $sformatf("Register \"%s\" has a reserved field",regs[i].get_full_name()), UVM_LOW);\
            end\
             else if(vr_reg_access == "RW") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RC and RW field",regs[i].get_full_name()), UVM_LOW); \
            end\
            else if(vr_reg_access == "RO") begin\
                `uvm_info("", $sformatf("Register \"%s\" has both RC and RO field",regs[i].get_full_name()), UVM_LOW);\
            end \
            else begin \
                vr_reg_access = "RC";\
            end \
        end\
    end\
    if(vr_reg_access == "USER1") \
       `uvm_fatal("",$sformatf("Register \"%s\" has a reserved field",regs[i].get_full_name() )); 

`define GET_REGS_RW_PROPERTY\
    string vr_domains[]; \
    uvm_reg_field vr_fields[$];\
    int vr_len;\
    string reg_field_property[$];\
    \
    vr_domains = new[1];\
    vr_domains[0] = "default";\
    \
    vr_reg_name = regs[i].get_name;\
    regs[i].get_fields(vr_fields);\
    vr_len = vr_reg_name.len();\
    reg_field_property.delete();\
    foreach(vr_fields[j]) begin \
        string      vr_field_access ;\
        string      vr_field_name   ;\
        uvm_reg_data_t  v           ;\
        vr_field_name = vr_fields[j].get_name();\
        vr_field_access = vr_fields[j].get_access();\
        if(vr_field_name.substr(0,3) == "rsv_") begin \
            `uvm_info("", $sformatf("Register \"%s\" has a reserved field", regs[i].get_full_name()), UVM_LOW); \
        end \
        else begin \
            reg_field_property.push_back(vr_field_access);\
        end\
    end\

`define EXCLUDE_ACCESS_REG(__name)\
    begin\
        string      vr_reg_name;\
        string      vr_reg_name_a;\
        uvm_reg     regs_q[$]   ;\
        regs_q  = regs;\
        for(int i=1; i<=regs_q.size; i++) begin\
            vr_reg_name = regs_q[i-1].get_name;\
            if(vr_reg_name ==``__name)begin\
                exclude_address.push_back(regs_q[i-1].get_address());\
                regs_q.delete(i-1);\
                i--;\
            end\
            else begin\
                vr_reg_name_a = "";\
                for(int j=0; j<vr_reg_name.len(); j++) \
                    if(vr_reg_name[j] == "[") \
                        break;\
                    else \
                        vr_reg_name_a = {vr_reg_name_a, vr_reg_name[j]};\
                if(vr_reg_name_a == ``__name) begin\
                    exclude_address.push_back(regs_q[i-1].get_address());\
                    regs_q.delete(i-1);\
                    i--;\
                end\
            end\
        end\
        regs =regs_q;\
    end

`define SET_VLD_ADDR(__first_addr,__last_addr)\
    begin\
        bit [31:0]  vr_reg_addr;\
        uvm_reg     regs_q[$]   ;\
        regs_q  = regs;\
        if( __first_addr != 32'h0 )begin\
            for(int i=1; i<=regs_q.size; i++) begin\
                vr_reg_addr = regs_q[i-1].get_address();\
                if(vr_reg_addr < __first_addr )begin\
                    exclude_address.push_back(vr_reg_addr);\
                    regs_q.delete(i-1);\
                    i--;\
                end\
            end\
        end\
        if( __last_addr != 32'hffff_ffff )begin\
            for(int i=1; i<=regs_q.size; i++) begin\
                vr_reg_addr = regs_q[i-1].get_address();\
                if(vr_reg_addr > __last_addr )begin\
                    exclude_address.push_back(vr_reg_addr);\
                    regs_q.delete(i-1);\
                    i--;\
                end\
            end\
        end\
        regs =regs_q;\
    end
    
`define EXCLUDE_ACCESS_ADDR(__first_addr = 32'h0,__last_addr = 32'h0)\
    begin\
        bit [31:0]  vr_reg_addr;\
        uvm_reg     regs_q[$]   ;\
        regs_q  = regs;\
        if( __first_addr < __last_addr )begin\
            for(int i=1; i<=regs_q.size; i++) begin\
                vr_reg_addr = regs_q[i-1].get_address();\
                if(vr_reg_addr >= __first_addr && vr_reg_addr <= __last_addr)begin\
                    exclude_address.push_back(vr_reg_addr);\
                    regs_q.delete(i-1);\
                    i--;\
                end\
            end\
        end\
        else begin\
            for(int i=1; i<=regs_q.size; i++) begin\
                vr_reg_addr = regs_q[i-1].get_address();\
                if(vr_reg_addr == __first_addr )begin\
                    exclude_address.push_back(vr_reg_addr);\
                    regs_q.delete(i-1);\
                    i--;\
                end\
            end\
        end\
        regs =regs_q;\
    end

`endif
