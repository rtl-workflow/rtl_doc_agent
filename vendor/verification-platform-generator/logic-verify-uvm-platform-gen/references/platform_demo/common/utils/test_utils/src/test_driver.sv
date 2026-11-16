//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_driver.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : DUT driver  
//
//******************************************************************************

`ifndef TEST_DRIVER__SV
`define TEST_DRIVER__SV

/** \brief DUT driver
    DUT driver gets transaction from input transaction queue and drives it onto the     
    DUT interface.                                                
*/
class test_driver extends stb_driver #(virtual test_interface);

    test_driver_cfg                           cfg;          ///< Driver configutation
    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//
 
    `uvm_component_utils_begin(test_driver)
        `uvm_field_object(cfg, UVM_ALL_ON)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//        
    `uvm_component_utils_end

    /** \brief new() 
     Constructor
    */  
    extern function new(string              name,
                        uvm_component       parent            
                        );

    /** \brief build_phase
    Calls super.build_phase(phase) to enable automatic get config and create object 
    */    
    extern virtual function void build_phase(uvm_phase phase);

    /** \brief run_phase
    Components implement behavior that is exhibited for the entire run-time, across the various run-time phases
    */
    extern virtual task run_phase(uvm_phase phase);

    /** \brief reset
    Reset test_interface input signals
    */
    extern virtual task reset();

    /** \brief task send_stimulus_data
    Get stimulus data from transation queue, drive stimulus data to DUT interface
    */
    extern virtual task send_stimulus_data();

    /** \brief task drv_random
    Drive random value to DUT interface when driver can't get transaction from input transaction queue
    */
    extern virtual task drv_random();

    //------------------------------------------------------------------------//
    // Define the member task/function base on project requirement            //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass:test_driver

function test_driver::new(string        name,
                         uvm_component  parent
                         );

    super.new(name, parent);

endfunction: new

function void test_driver::build_phase(uvm_phase phase);

    super.build_phase(phase);
    
    if(this.cfg == null) begin
        this.cfg = test_driver_cfg::type_id::create("cfg", this);
        `uvm_info(get_type_name(), "build_phase(): Randomizing test_driver configuration object", UVM_MEDIUM);
        if (!this.cfg.randomize()) begin
            `uvm_fatal(get_type_name(),"build_phase(): cfg.randomize() call failed!");
        end
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): cfg.sprint(): \n%s", this.cfg.sprint()), UVM_HIGH);

endfunction: build_phase

task test_driver::reset();

    //------------------------------------------------------------------------//
    //  Extend reset() base on project requirement                            //
    //------------------------------------------------------------------------//    
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endtask: reset

task test_driver::run_phase(uvm_phase phase);

    super.run_phase(phase);

    `uvm_info(get_type_name(), "run_phase(): test_driver run_phase is running", UVM_MEDIUM);
    this.reset();
    this.send_stimulus_data();
    
endtask: run_phase

task test_driver::send_stimulus_data(); 

    test_xaction drv_tr;
    test_xaction out_tr; 

    while(1) begin

        uvm_wait_for_nba_region();
        if(this.seq_item_port.has_do_available()) begin
            this.seq_item_port.get_next_item(req);
            if(!$cast(drv_tr, req)) begin
                `uvm_fatal(get_type_name(), "send_stimulus_data(): req is not a test_xactions type or its extension");
            end

            //----------------------------------------------------------------//
            // 1. If this VIP support MASTER_NO_MONITOR work mode, user should// 
            //    write transaction in out_port; User can decide when and     // 
            //    where write trasaction                                      //
            // 2. If this VIP don't support MASTER_NO_MONITOR work mode,      //
            //    user can delete code which write trasaction in out_port;    //
            //    But for utils_unit_test environment which use the           //
            //    VIP MASTER_NO_MONITOR work mode, so this VIP can't run      //
            //    utils_unit_test environment.                                //
            //----------------------------------------------------------------//
            assert($cast(out_tr, drv_tr.clone())); 
            this.out_port.write(out_tr);          

            //----------------------------------------------------------------//
            // User decide which pack to select base on project requirement   //
            //----------------------------------------------------------------//
            //-------------------------Coding begin---------------------------//
            // byte unsigned pkt_data[];/ int unsigned pkt_data[];/ bit pkt_data[]; 
            // void'(drv_tr.pack_bytes(pkt_data)); / void'(drv_tr.pack_ints(pkt_data)); /
            // void'(drv_tr.pack(pkt_data));
            //-------------------------Coding end-----------------------------//
            
            //----------------------------------------------------------------//
            // Drive stimulus to DUT interface base on project requirement    //
            //----------------------------------------------------------------//
            //-------------------------Coding begin---------------------------//
            // User transfer drv_tr to DUT
            // @bus.drv_mp.drv_cb;
            // bus.drv_mp.drv_cb.sop <= #DLY 1'b1;
            #10ns;       // Add the time only for environment run, user can delete it
            //-------------------------Coding end-----------------------------//

            this.seq_item_port.item_done();
            `uvm_info(get_type_name(), $sformatf("send_stimulus_data(): Output the drv_tr: \n%s ", drv_tr.sprint()), UVM_DEBUG);        
        end
        else begin
            drv_random();
        end
    end

endtask: send_stimulus_data

task test_driver::drv_random();

    //------------------------------------------------------------------------//
    // User define which bus signals give random value                        //
    // and which bus signals give fixed value                                 //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // @bus.drv_mp.drv_cb;
    // bus.drv_mp.drv_cb.sop <= 1'b0;    
    #10ns;       // Add the time only for environment run, user can delete it
    //-----------------------------Coding end---------------------------------//

endtask:drv_random

`endif

