//*********************************************************************
//
// Copyright(c) 2009-2010, Huawei Technologies Co, Ltd
// All rights reserved.
//
// Author       :  liudingjie/00127937
// Email        :  liudingjie@huawei.com
//
//---------------------------------------------------------------------
//
// File Name    :  bfm_cbus.sv
// Abstract     :  apply task:CBUS_WR(),CBUS_RD()
//
//Description   :   this class inmplement CBUS write and read task
//----------------------Modification history---------------------------
//Date        By               Rev.    Prj.         Change Description
//---------------------------------------------------------------------
//2010-04-01  liudingjie       1.00    TD232/TD234  create
//2010-04-13  shenyue/00159590 1.01    TD232/TD234  pramerterized address and data bus width
//2014-06-30  shenyue/00159590 1.02    TD280        Modify for vmm
//2020-10-09  lidongbo/381975  1.1     LD8052       Add name of write_task and read_task fork_join threads
//*********************************************************************
`ifndef BFM_CBUS
`define BFM_CBUS

class bfm_cbus #( // GAEA_PLATFORM::CLASSNAME
 int    AWIDTH = 22, // GAEA_PLATFORM::PARAMETER
 int    DWIDTH = 32, // GAEA_PLATFORM::PARAMETER
 type  DATA_TYPE=uvm_sequence_item // no use
    )extends uvm_driver#(cpu_transaction);// GAEA_PLATFORM::TYPE

    semaphore    m_access;
    virtual bfm_cbus_intf #(.AWIDTH(AWIDTH),.DWIDTH(DWIDTH)) bus;

    bfm_cbus_cfg    cfg;

    `uvm_component_param_utils(bfm_cbus#(AWIDTH, DWIDTH))
    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    //extern virtual task main_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task drive_one_pkt(cpu_transaction tr);
    extern   task        write(bit [AWIDTH-1:0] addr,       bit [DWIDTH-1:0] data);
    extern   task        read(bit [AWIDTH-1:0] addr,output bit [DWIDTH-1:0] data);

endclass


function bfm_cbus::new(string name, uvm_component parent);
    super.new(name, parent);
//    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    //Below variables initial process are copied from orignal class
    this.bus = bus;
    m_access = new(1);


    //Add your custom codes here:

endfunction:new

function void bfm_cbus::build_phase(uvm_phase phase);
//    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    //get interface 
    if (!uvm_config_db#(virtual bfm_cbus_intf #(.AWIDTH(AWIDTH),.DWIDTH(DWIDTH)))::get(this,"","bus",this.bus))
    begin
        `uvm_fatal(get_type_name(),"no virtual interface is assigned")
    end    

    //Add interface config::
    //if(!uvm_config_db#(virtual bfm_cbus_intf)::get(this, "","bus", bus))
    //`uvm_fatal("CFGERR", " is not configured!!!");

    //Add channel object creation::

    //Add your custom codes here:

endfunction:build_phase


task bfm_cbus::run_phase(uvm_phase phase);
//    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    forever begin
        this.seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        this.seq_item_port.item_done();
    end

endtask:run_phase

//task bfm_cbus::main_phase(uvm_phase phase);
//    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
//
//    forever begin
//        this.seq_item_port.get_next_item(req);
//        drive_one_pkt(req);
//        this.seq_item_port.item_done();
//    end
//
//endtask:main_phase

task bfm_cbus::drive_one_pkt(cpu_transaction tr);
//    `uvm_info("drive_one_pkt","Start Drive pkt~",UVM_HIGH);
    if(tr.cpu_op == cpu_transaction::WRITE)begin
        write(tr.addr,tr.wr_data);
    end
    else if(tr.cpu_op == cpu_transaction::READ)begin
        read(tr.addr,tr.rd_data);
    end
    else begin
        `uvm_warning("drive_one_pkt","Receive a IDLE transaction!");
    end
endtask:drive_one_pkt

task bfm_cbus::write(bit [AWIDTH-1:0] addr,bit [DWIDTH-1:0] data);
    begin
        this.m_access.get(1);

        @(posedge bus.cbus_clk);
        #1;
        bus.cbus_addr  = addr;
        bus.cbus_wdata = data;
        bus.cbus_rw    = 1'b0;
        bus.cbus_req   = 1'b1;

        fork:cbus_write_threads
            begin
                wait(bus.cbus_ack == 1'b1);
            end
            begin
                repeat(20) @(posedge bus.cbus_clk);
                `uvm_error("CBUS WRITE FAILED", "wait for ack timeout!!")
            end
        join_any
        disable cbus_write_threads;

        @(posedge bus.cbus_clk);
        #1;
        bus.cbus_addr  = {AWIDTH{1'b0}};
        bus.cbus_wdata = {DWIDTH{1'b0}};
        bus.cbus_rw    = 1'b1          ;
        bus.cbus_req   = 1'b0          ;
//        `uvm_info("CBUS WRITE SUCCESS", $sformatf("addr = 0x%h, data =0x%h", addr, data),UVM_LOW);

        #70;
        this.m_access.put(1);
    end
endtask

task bfm_cbus::read(bit [AWIDTH-1:0] addr,output bit [DWIDTH-1:0] data);
    begin
        this.m_access.get(1);

        @(posedge bus.cbus_clk);
        #1;
        bus.cbus_addr = addr;
        bus.cbus_rw   = 1'b1;
        bus.cbus_req  = 1'b1;

        fork:cbus_read_threads
            begin
                wait(bus.cbus_ack == 1'b1);
            end
            begin
                repeat(20) @(posedge bus.cbus_clk);
                `uvm_error("CBUS READ FAILED", "wait for ack timeout!!")
            end
        join_any
        disable cbus_read_threads;

        @(posedge bus.cbus_clk);
        data = bus.cbus_rdata;
        #1;
        bus.cbus_addr = {AWIDTH{1'b0}};
        bus.cbus_rw   = 1'b1;
        bus.cbus_req  = 1'b0;
        #5;
//        `uvm_info("CBUS READ SUCCESS", $sformatf("addr = 0x%h, data =0x%h @ %t", addr, data, $time),UVM_LOW);

        #70;

        this.m_access.put(1);
    end
endtask
`endif // _C_CBUS_BFM
