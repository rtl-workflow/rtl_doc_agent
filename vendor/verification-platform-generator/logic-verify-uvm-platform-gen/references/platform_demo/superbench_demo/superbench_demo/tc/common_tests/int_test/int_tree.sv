// **********************************************************************
// Copyright(c) 2018, Huawei Technologies Co., Ltd, All right reserved 
//
// Project Name   :
// Filename       : int_tree.sv
// Author         : wenzheng/w00580166
// Date           : 2021/05/20
// Version        : 1.0
// Company        : Huawei Technologies Co., Ltd
//
// Description    : 
//
// Modification History
// Date By Revision Change Description
// -----------------------------------------------------------------------
// 2021/05/20 wenzheng  1.00 Create
// 2022/10/10 yangyang  1.1 Modify
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
`ifndef INT_TEST__SV
`define INT_TEST__SV

class int_tree extends uvm_object                                                                   ;
    static int_tree base                                                                            ;
    static int_item root                                                                            ;
    extern        function new(string name="int_tree")                                              ;
    extern static function void set_root(string root_name)                                          ;
    extern static function void def_int(string name,string signal,uvm_reg_field enbreg,hisreg,almreg,frcreg,
                                        int en_bits=-1,his_bits=-1,alm_bits=-1,frc_bits=-1)         ;
    extern static task          check_tree()                                                        ;
    extern static task          clear_all_alarm()                                                   ;
    extern static function void print_int_tree(string root="",int level=2)                          ;
endclass:int_tree
//==================================================================================================
//
//==================================================================================================
function int_tree::new(string name="int_tree")                                                      ;
    super.new(name)                                                                                 ;
    if(base==null) base=this                                                                        ;
endfunction
//==================================================================================================
//
//==================================================================================================
static function void int_tree::set_root(string root_name)                                           ;
    root=new(root_name)                                                                             ;
    `uvm_info("root",$psprintf("root %s",base.root.name),UVM_NONE)
endfunction:set_root
//==================================================================================================
//
//==================================================================================================
static function void int_tree::def_int(string name,string signal,uvm_reg_field enbreg,hisreg,almreg,frcreg,
    int en_bits=-1,his_bits=-1,alm_bits=-1,frc_bits=-1);
    string split_val[$],parent                                                                      ;
    int_item m_int_item                                                                             ;
    if(base==null) base=new("int_tree")                                                             ;
    uvm_split_string(name, ".", split_val)                                                          ;
    for(int i=0;i<split_val.size();i++)
        `uvm_info("int",$psprintf("%d : split_val %s",i,split_val[i]),UVM_NONE)
    if(base.root.name!=split_val[0]) `uvm_error("int",$psprintf("root is not %s",base.root.name))
    else base.root.configure(split_val.pop_front(),split_val,signal,enbreg,hisreg,almreg,frcreg,en_bits,his_bits,alm_bits,frc_bits);
endfunction
//==================================================================================================
//
//==================================================================================================
static function void  int_tree::print_int_tree(string root="",int level=2)                          ;
    if(base==null) base=new("int_tree")                                                             ;
    if(root=="") `uvm_info("int",$psprintf("null root"),UVM_LOW)
    else begin
        //base.root.print()                                                                           ;

        int     int_max_level = 8;
        string  table_head       ;
        for(int i=0; i<int_max_level; i++) begin
            table_head = $psprintf("%sclass%0d enb\tclass%0d alm\t",table_head,i+1,i+1);
        end
        $display("%s",table_head);

        base.root.print_int(level);
    end
endfunction:print_int_tree
//==================================================================================================
//
//==================================================================================================
task int_tree::check_tree()                                                                         ;
    int_item item=base.root                                                                         ;
    `uvm_info("check_tree_before: ",$psprintf("0: %s %s",base.root.name,base.root.signal),UVM_NONE)
     base.root.int_test()                                                                            ;
    `uvm_info("check_tree_after: ",$psprintf("0: %s %s",base.root.name,base.root.signal),UVM_NONE)
endtask:check_tree
//==================================================================================================
//
//==================================================================================================
task int_tree::clear_all_alarm()                                                                    ;
    int_item item=base.root                                                                         ;
    `uvm_info("alarm",$psprintf("1: %s %s",base.root.name,base.root.signal),UVM_NONE)
    base.root.clear_all_alarm()                                                                     ;
    `uvm_info("alarm",$psprintf("2: %s %s",base.root.name,base.root.signal),UVM_NONE)
endtask:clear_all_alarm
//==================================================================================================
//
//==================================================================================================
`endif //INT_TEST__SV
