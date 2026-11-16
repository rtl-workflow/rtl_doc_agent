// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : reg_test_task.sv
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
`ifndef REG_TEST_TASK__SV
`define REG_TEST_TASK__SV
class reg_test_task extends uvm_object;
    
    task reg_write(uvm_reg regs[], bit[31:0] wdata, reg_test_dec::access_order_e order, uvm_path_e path, reg_test_dec::wdata_type_e wdata_type);
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_write begin, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW);

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY
            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", 
                                regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                if(wdata_type == reg_test_dec::W_RANDOM) begin
                    wdata = $urandom ;
                end
                else if (wdata_type == reg_test_dec::W_REVER) begin
                end

                regs[i].write(vr_status, wdata, path);

                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                            vr_status.name(), regs[i].get_full_name(), vr_domains[j]));
                end
            end
        end
        `uvm_info("", $sformatf("|--reg_write end, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)
    endtask:reg_write

    task reg_read(uvm_reg regs[], reg_test_dec::access_order_e order);

        bit                 vr_exp_reg      ;
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_read begin, access_order =%s.", order), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY
            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", 
                                regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                if(vr_reg_access != "RC") begin
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                end
                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                            vr_status.name(), regs[i].get_full_name()));
                end
            end
        end
        `uvm_info("", $sformatf("|--reg_read end, access_order =%s.", order), UVM_LOW)
    endtask:reg_read

    task reg_read_write(uvm_reg regs[], bit[31:0] wdata, reg_test_dec::access_order_e order, uvm_path_e path, reg_test_dec::wdata_type_e wdata_type);
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_read_write begin, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY

            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                            vr_status.name(), regs[i].get_full_name()));
                end
            end

            foreach (vr_domains[j]) begin
                if(wdata_type == reg_test_dec::W_RANDOM) begin
                    wdata = $urandom ;
                end
                else if (wdata_type == reg_test_dec::W_REVER) begin
                end

                regs[i].write(vr_status, wdata, path);

                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                            vr_status.name(), regs[i].get_full_name(), vr_domains[j]));
                end
            end
        end
        `uvm_info("", $sformatf("|--reg_read_write end, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)
    endtask:reg_read_write

    task reg_write_read(uvm_reg regs[], bit[31:0] wdata, reg_test_dec::access_order_e order, uvm_path_e path, reg_test_dec::wdata_type_e wdata_type);
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_write_read begin, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY

            foreach (vr_domains[j]) begin
                if(wdata_type == reg_test_dec::W_RANDOM) begin
                    wdata = $urandom ;
                end
                else if (wdata_type == reg_test_dec::W_REVER) begin
                end

                regs[i].write(vr_status, wdata, path);

                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                            vr_status.name(), regs[i].get_full_name(), vr_domains[j]));
                end
            end

            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                            vr_status.name(), regs[i].get_full_name()));
                end
            end

        end
        `uvm_info("", $sformatf("|--reg_write_read end, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)
    endtask:reg_write_read

    task reg_rw_write_read(uvm_reg regs[], bit[31:0] wdata, reg_test_dec::access_order_e order, uvm_path_e path, reg_test_dec::wdata_type_e wdata_type);
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_rw_write_read begin, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY

            foreach (vr_domains[j]) begin
                if(wdata_type == reg_test_dec::W_RANDOM) begin
                    wdata = $urandom ;
                end
                else if (wdata_type == reg_test_dec::W_REVER) begin
                end

                if(vr_reg_access == "RW") begin
                    regs[i].write(vr_status, wdata, path);

                    if(vr_status != UVM_IS_OK) begin
                        `uvm_error("", $sformatf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                            vr_status.name(), regs[i].get_full_name(), vr_domains[j]));
                    end
                end
            end

            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                if(vr_reg_access == "RW") begin
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);        //add
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);        //add
                end
                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                        vr_status.name(), regs[i].get_full_name()));
                end
            end

        end
        `uvm_info("", $sformatf("|--reg_rw_write_read end, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)
    endtask:reg_rw_write_read

    task reg_rw_read_write(uvm_reg regs[], bit[31:0] wdata, reg_test_dec::access_order_e order, uvm_path_e path, reg_test_dec::wdata_type_e wdata_type);
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_rw_read_write begin, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY

            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                if(vr_reg_access == "RW") begin
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    if(vr_status != UVM_IS_OK) begin
                        `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                            vr_status.name(), regs[i].get_full_name()));
                    end
                end
            end

            foreach (vr_domains[j]) begin
                if(wdata_type == reg_test_dec::W_RANDOM) begin
                    wdata = $urandom ;
                end
                else if (wdata_type == reg_test_dec::W_REVER) begin
                end
                
                if(vr_reg_access == "RW")begin
                    regs[i].write(vr_status, wdata, path);

                    if(vr_status != UVM_IS_OK) begin
                        `uvm_error("", $sformatf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                            vr_status.name(), regs[i].get_full_name(), vr_domains[j]));
                    end
               end
            end
        end
        `uvm_info("", $sformatf("|--reg_rw_read_write end, access_order =%s, access_way =%s, wdata_type =%s, wdata =%32h(H).", order,path,wdata_type,wdata), UVM_LOW)
    endtask:reg_rw_read_write

    task reg_rw_read(uvm_reg regs[], reg_test_dec::access_order_e order);

        bit                 vr_exp_reg      ;
        uvm_status_e        vr_status       ;
        string              vr_reg_access   ;
        string              vr_reg_name     ;
        uvm_reg             vr_regs[]       ;
        int unsigned        vr_size         ;

        randcrange          vr_rr           ;
        `uvm_info("", $sformatf("|--reg_rw_read begin, access_order =%s.", order), UVM_LOW)

        `SET_ACCESS_ORDER

        foreach (regs[i]) begin

            `GET_REGS_PROPERTY
            foreach (vr_domains[j]) begin
                `uvm_info("", $sformatf("Verifying access of register %s in domain \"%s\"...", 
                                regs[i].get_full_name(), vr_domains[j]), UVM_DEBUG);
                if(vr_reg_access == "RW" ) begin
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                    regs[i].mirror(vr_status, UVM_CHECK, UVM_FRONTDOOR);
                end
                if(vr_status != UVM_IS_OK) begin
                    `uvm_error("", $sformatf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                            vr_status.name(), regs[i].get_full_name()));
                end
            end
        end
        `uvm_info("", $sformatf("|--reg_rw_read end, access_order =%s.", order), UVM_LOW)
    endtask:reg_rw_read

    task bit_glue_chk(uvm_reg regs[],bit[31:0] wdata);
        uvm_status_e vr_status;
        string       vr_reg_access;
        string       vr_reg_name;
        uvm_reg      vr_regs[];
        int unsigned vr_size;
        randcrange   vr_rr;

        `uvm_info(get_type_name(),$psprintf("|--bit_glue_chk begin."),UVM_NONE);
        foreach(regs[i])begin
            `GET_REGS_PROPERTY
            foreach(vr_domains[j])begin
                uvm_status_e vr_status;
                int          vr_len;

                `uvm_info(get_type_name(),$psprintf("Verifying access of register %s in domain \"%s\"...",
                                        regs[i].get_full_name(),vr_domains[j]),UVM_DEBUG);
                vr_len = vr_reg_name.len();
                if(vr_reg_access == "RW")begin
                    bit[31:0] vr_wdata = wdata;
                    for(int k=0;k<32;k++) begin 
                        //regs[i].write(vr_status,vr_wdata,UVM_FRONTDOOR,vr_domains[j]);
                        regs[i].write(vr_status,vr_wdata,UVM_FRONTDOOR);

                        if(vr_status != UVM_IS_OK)begin
                            `uvm_error(get_type_name(),$psprintf("vr_status was %s when writing \"%s\" through domain \"%s\".",
                                                       vr_status.name(),regs[i].get_full_name(),vr_domains[j]));
                        end

                        //reg[i].mirror(vr_status,UVM_CHECK,UVM_FRONTDOOR,vr_domains[j]);
                        regs[i].mirror(vr_status,UVM_CHECK,UVM_FRONTDOOR);
                        if(vr_status != UVM_IS_OK)begin
                            `uvm_error(get_type_name(),$psprintf("vr_status was %s when reading value of register \"%s\" through frontdoor.",
                                                        vr_status.name(),regs[i].get_full_name()));
                        end
                        vr_wdata = {vr_wdata[30:0],vr_wdata[31]};
                    end
                end
            end
        end
        `uvm_info(get_type_name(),$psprintf("|--bit_glue_chk end."),UVM_NONE);
    endtask:bit_glue_chk
endclass:reg_test_task
`endif
