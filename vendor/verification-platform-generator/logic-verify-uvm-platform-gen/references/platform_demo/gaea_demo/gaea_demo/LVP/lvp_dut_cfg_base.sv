//Description   :   this class is the basic logic verification property of dut_cfg

`ifndef LVP_DUT_CFG_BASE__SV
`define LVP_DUT_CFG_BASE__SV

class lvp_dut_cfg_base extends uvm_object;

    uvm_status_e    status                  ;
    uvm_path_e      path = UVM_FRONTDOOR    ;
    static uvm_reg  test_reg[$]             ;

    `uvm_object_utils_begin(lvp_dut_cfg_base)
    `uvm_object_utils_end

    extern         function         new(string name = "lvp_dut_cfg_base") ; 
    extern virtual task             hw_reset()                            ; 
    extern virtual task             sw_reset()                            ; 
    extern virtual task             cfg_dut()                             ; 
    extern virtual task             cfg_ram_init()                        ; 
    extern virtual task             ncfg_ram_init()                       ; 
    extern virtual task             check_alm(bit chk_en = 1)             ; 
    extern virtual function void    load_test_reg()                       ; 

    //the tasks called by cfg_dut
    extern virtual task             set_cfg()                             ; 
    extern virtual task             cfg_reg()                             ; 
    extern virtual task             cfg_mem()                             ; 
    extern virtual task             cfg_clk()                             ; 
    
    //the tasks called by check_alm
    extern virtual task             chk_int(bit chk_en = 1)               ; //to check interrupt regs
    extern virtual task             chk_cnt(bit chk_en = 1)               ; //to check counter regs
    extern virtual task             chk_sta(bit chk_en = 1)               ; //to check status regs

endclass : lvp_dut_cfg_base

function lvp_dut_cfg_base::new(string name = "lvp_dut_cfg_base");
    super.new(name);
endfunction

task lvp_dut_cfg_base::hw_reset();
endtask

task lvp_dut_cfg_base::sw_reset();
endtask

//BT should override cfg_dut only if the call-task-flow not match BT's requirements!
task lvp_dut_cfg_base::cfg_dut();
    `uvm_info(get_type_name(), "cfg_dut begin", UVM_NONE);
    this.set_cfg(); 
    this.cfg_reg(); 
    this.cfg_mem(); 
    this.cfg_clk(); 
    `uvm_info(get_type_name(), "cfg_dut end", UVM_NONE);
endtask

//BT should override check_alm only if the call-task-flow not match BT's requirements!
task lvp_dut_cfg_base::check_alm(bit chk_en = 1);
    `uvm_info(get_type_name(), $psprintf("check_alm(%0d) begin",chk_en), UVM_NONE);
    this.chk_int(chk_en); 
    this.chk_cnt(chk_en); 
    this.chk_sta(chk_en); 
    `uvm_info(get_type_name(), $psprintf("check_alm(%0d) end",chk_en), UVM_NONE);
endtask

task lvp_dut_cfg_base::cfg_ram_init();
endtask

task lvp_dut_cfg_base::ncfg_ram_init();
endtask

//BT should override load_test_reg to push selected test rw res for IT/subST/ST into this.test_reg[$]
function void lvp_dut_cfg_base::load_test_reg();
    `uvm_error(get_type_name(), "load_test_reg function not implemented !");
endfunction

task lvp_dut_cfg_base::set_cfg();
endtask 

task lvp_dut_cfg_base::cfg_reg();
endtask 

task lvp_dut_cfg_base::cfg_mem();
endtask 

task lvp_dut_cfg_base::cfg_clk();
endtask 

task lvp_dut_cfg_base::chk_int(bit chk_en = 1);
endtask 

task lvp_dut_cfg_base::chk_cnt(bit chk_en = 1);
endtask 

task lvp_dut_cfg_base::chk_sta(bit chk_en = 1);
endtask 

`endif
