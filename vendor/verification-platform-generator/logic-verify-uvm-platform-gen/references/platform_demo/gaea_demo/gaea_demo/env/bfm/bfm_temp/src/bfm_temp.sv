//##################################################################
//Copyright(c) 2017,Huawei Technologies Co.,Ltd.
//All rights reserved
//Project name    :
//File name       :
//Author          : c00800326
//Initial-Date    : 2025-11-04 11:41:32
//Abstract        : bfm_temp
//Called by       :
//##################################################################
//Modification History
//--------------------------
//Revision 1.0  ( 2025-11-04 11:41:32, by c00800326)
//  ... version info ... 
//
//##################################################################

/*
 * Attention: Make your modification within the sections makred with "EDITABLE SECTION" only. Or you may get unpredictable results.
 */

`ifndef _bfm_temp_CLASS_
`define _bfm_temp_CLASS_

class bfm_temp #(             // GAEA_PLATFORM::CLASSNAME
    type DATA_TYPE = uvm_sequence_item, // GAEA_PLATFORM::PARAMETER
    int  DAT_WIDTH = 32                 // GAEA_PLATFORM::PARAMETER
    ) extends uvm_component;               // GAEA_PLATFORM::TYPE

    //!GAEA_BLOCK_BEGIN_CHANNELDECL
    base_put_port  outport_of_drv;  // GAEA_PLATFORM::OUTPORT 
    base_put_port  outport;  // GAEA_PLATFORM::OUTPORT 
    base_peek_port  inport;  // GAEA_PLATFORM::INPORT 
    //!GAEA_BLOCK_END_CHANNELDECL                                                

    bfm_temp_cfg      cfg;    				// NOTICE:configure instance is cfg
    virtual bfm_temp_intf #(.DAT_WIDTH(DAT_WIDTH)) intf;   // NOTICE:interface instance is bus
    glb_dec::if_vip_work_mode      work_mode = glb_dec::NORMAL;         // NOTICE:work_mode type should be NORMAL,NORMAL_WITH_MONITOR,DRIVER,DRIVER_WITH_MONITOR,MONITOR 

    bfm_temp_driver   #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))         driver;
    bfm_temp_monitor  #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))         monitor;
    bfm_temp_receiver #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))         receiver;

    // BEGIN: EDITABLE SECTION
    // Declare your variables here

    // END: EDITABLE SECTION

    extern   function new (string name, uvm_component parent);
    extern   virtual function void build_phase(uvm_phase phase);
    extern   virtual function void connect_phase(uvm_phase phase);
    extern   virtual task run_phase(uvm_phase phase);

    `uvm_component_param_utils(bfm_temp #(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH)))

    // BEGIN: EDITABLE SECTION
    // Declare/define your functions/tasks here

    // END: EDITABLE SECTION
endclass:bfm_temp

function bfm_temp::new (string name, uvm_component parent);
    super.new(name, parent);

    // BEGIN: EDITABLE SECTION
    // END: EDITABLE SECTION
endfunction:new

function void bfm_temp::build_phase(uvm_phase phase);
    //get interface 
    if (!uvm_config_db#(virtual bfm_temp_intf#(.DAT_WIDTH(DAT_WIDTH)))::get(this,"","bus",this.intf))
    begin
        `uvm_fatal(get_type_name(),"no virtual interface is assigned")
    end

    work_mode = cfg.work_mode;

    // BEGIN: EDITABLE SECTION
    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::NORMAL || work_mode == glb_dec::DRIVER || work_mode == glb_dec::DRIVER_WITH_MONITOR)
    begin
        driver         = bfm_temp_driver#(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))::type_id::create("drv",this);
        driver.drv_bus = intf.drv_bus;
        driver.cfg     = cfg;
    end

    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::NORMAL || work_mode == glb_dec::RECEIVER)
    begin
        receiver         = bfm_temp_receiver#(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))::type_id::create("rcvr",this);
        receiver.rcv_bus = intf.rcv_bus;
        receiver.cfg     = cfg;
    end

    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::MONITOR || work_mode == glb_dec::DRIVER_WITH_MONITOR)
    begin
        monitor         = bfm_temp_monitor#(.DATA_TYPE(DATA_TYPE),.DAT_WIDTH(DAT_WIDTH))::type_id::create("mon_of_drv",this);
        monitor.mon_bus = intf.mon_bus; //the receiver same as the monitor;
        monitor.cfg     = cfg;
    end    
    // END: EDITABLE SECTION

endfunction

function void bfm_temp::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // BEGIN: EDITABLE SECTION
    `uvm_info(get_type_name(),"connect_phase is called",UVM_MEDIUM)
    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::NORMAL || work_mode == glb_dec::DRIVER || work_mode == glb_dec::DRIVER_WITH_MONITOR)
    begin
        inport = driver.inport;   
    end

    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::NORMAL || work_mode == glb_dec::RECEIVER)
    begin
        outport = receiver.outport;    
    end

    if (work_mode == glb_dec::NORMAL_WITH_MONITOR || work_mode == glb_dec::DRIVER_WITH_MONITOR)
    begin
        outport_of_drv = monitor.outport;
    end


    //!GAEA_BLOCK_BEGIN_CHANNELINST
    //!GAEA_BLOCK_END_CHANNELINST

    `uvm_info(get_type_name(),"connect_phase is done",UVM_MEDIUM)
    // END: EDITABLE SECTION

endfunction

task bfm_temp::run_phase(uvm_phase phase) ;

    super.run_phase(phase);
    `uvm_info("TRACE:bfm top ", $sformatf("%m"), UVM_HIGH);
    
endtask:run_phase

`endif
