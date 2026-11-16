/**********************************************************************************
    Copyright(c) 2025 Huawei Technologies Co., Ltd, All right reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   tcl_cmd_program.sv
    Author       :   Gaea
    ===============================================================================
    Description  :   1, module example
    ===============================================================================
    Modification History:
    Date        By                      Rev.    Prj.    Change Description
    -------------------------------------------------------------------------------
    2025-11-12  Gaea  1.0     Gaea_VP 3.2  Create
    ===============================================================================
    Called by    :  xxxxxx.v,xxxxxx.v,*
    File tree    :  xxxxxx.v
                       +---xxxxxx.v
                       +---xxxxx.v
**********************************************************************************/
`define tcl_cmd_register(tcl_cmd,path_func)\
task ``tcl_cmd;\
    ``path_func;\
endtask\

`ifndef MAX_RAL_HEIR_BLOCK_NUM
`define MAX_RAL_HEIR_BLOCK_NUM 1
`endif

//==================================================================================================
//
//==================================================================================================
module TCL_CMD;
    bit[31:0] return_value;
    reg return_valid;
    string tcl_args[$];
    uvm_reg_block st_blks[$];

    function void append_tcl_args(bit[10*8-1:0] arg);
        tcl_args.push_back(arg);
    endfunction:append_tcl_args

    function void reset_tcl_args();
        tcl_args.delete();
    endfunction:reset_tcl_args

    function void tcl_uvm_error(bit[100*8-1:0] error_info);
        fork
        `uvm_error("TCL_REPORT",$psprintf("%s",error_info))
        join_none
    endfunction:tcl_uvm_error
    
    function void tcl_uvm_ok(bit[100*8-1:0] ok_info);
        fork
        `uvm_info("TCL_INFO",$psprintf("%s",ok_info),UVM_NONE)
        join_none
    endfunction:tcl_uvm_ok

    task tcl_cpu_ral_rw(bit[8*100-1:0] ral_path,int wr_cmd,int value);
        fork ral_access_by_name(ral_path,wr_cmd,value);join_none
        stb_realtime.delay(1)                    ;
        wait(return_valid==1)                    ;
    endtask:tcl_cpu_ral_rw

    function set_report_level(bit[100*8-1:0] path,int level);
       uvm_root root;
       uvm_component component;
       root=uvm_root::get();
       component=root.find(path);
       if(component!=null) component.set_report_verbosity_level(level);
    endfunction:set_report_level

    task ral_access_by_name(string ral_path,int wr_cmd,int value);//0:read 1:write 2:get 3:predict 4 mirror
        uvm_reg_block blks[$],vr_uvm_block,lst_uvm_block;
        uvm_reg vr_reg;
        uvm_reg_field vr_field;
        uvm_status_e  status  ;
        string split_val[$],lst_block;

        uvm_reg_block::get_root_blocks(blks);
        uvm_split_string(ral_path, ".", split_val);
        
        `ifdef V_ST_RAL 
        vr_uvm_block = st_blks[0];
        `else
        vr_uvm_block = blks[0];
        `endif
        for(int i=0;i<`MAX_RAL_HEIR_BLOCK_NUM;i++)begin
            lst_uvm_block = vr_uvm_block;
            if(vr_uvm_block!=null)begin
                vr_uvm_block=vr_uvm_block.get_block_by_name(split_val[0]);
                if(vr_uvm_block==null)begin
                    vr_uvm_block = lst_uvm_block            ;
                    //$display("NO.%0d not get %s",i,split_val[0]);
                    if(i!=0) split_val.push_front(lst_block);
                    break;
                end
                else begin
                    //$display("NO.%0d get %s",i,split_val[0]);
                end
            end
            if(i < (`MAX_RAL_HEIR_BLOCK_NUM -1))  lst_block=split_val.pop_front();
        end

        if(vr_uvm_block!=null) vr_reg=vr_uvm_block.get_reg_by_name(split_val[1]);

        if(vr_reg!=null)begin 
            if(split_val.size()==2)begin
               case(wr_cmd)
                   4: vr_reg.mirror(status,UVM_CHECK);
                   3: vr_reg.predict(value);
                   2: value=vr_reg.get()        ;
                   1: vr_reg.write(status,value);
                   0: vr_reg.read(status,value) ;
               endcase
            end else begin
                vr_field=vr_reg.get_field_by_name(split_val[2]);
                if(vr_field!=null)begin 
                    case(wr_cmd)
                        4: vr_field.mirror(status,UVM_CHECK);
                        3: vr_field.predict(value);
                        2: value=vr_field.get();
                        1: vr_field.write(status,value) ;
                        0: vr_field.read(status,value);
                    endcase
                end
                else `uvm_error("CPU_TCL",$psprintf("can't find %s",ral_path))
            end
            `uvm_info("CPU_TCL",$psprintf("%s,%d",vr_reg.get_full_name(),value),UVM_LOW)
        end
        else `uvm_error("CPU_TCL",$psprintf("can't find %s",ral_path))
        return_value=value; return_valid=1    ;
    endtask:ral_access_by_name

endmodule
