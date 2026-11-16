//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_monitor.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Extract signals from the DUT 
//
//******************************************************************************

`ifndef TEST_MONITOR__SV
`define TEST_MONITOR__SV

/** \brief DUT monitor
    The DUT monitor extracts the transaction from the DUT interface
    and transfer it through the packet port 
*/
class test_monitor extends stb_monitor #(virtual test_interface);
 
    test_monitor_cfg                          cfg;     ///< Monitor configuration

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//   

    `uvm_component_utils_begin(test_monitor)
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
    extern function new(string            name,
                        uvm_component     parent
                       );

    /** \brief build_phase
    Calls super.build_phase(phase) to enable automatic get config and create object 
    */    
    extern virtual function void build_phase(uvm_phase phase);

    /** \brief run_phase
    Components implement behavior that is exhibited for the entire run-time, across the various run-time phases
    */
    extern virtual task run_phase (uvm_phase phase);

    /** \brief sample_stimulus_data()
    Sample stimulus data from DUT interface, puts them into output transaction queue
    */
    extern virtual task sample_stimulus_data(); 

    //------------------------------------------------------------------------//
    // Define the member task/function base on project requirement            //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

endclass: test_monitor

function test_monitor::new(string        name,
                          uvm_component  parent
                          );

    super.new(name, parent);

endfunction: new

function void test_monitor::build_phase(uvm_phase phase);

    super.build_phase(phase);
    
    if(this.cfg == null) begin
        this.cfg = test_monitor_cfg::type_id::create("cfg", this);
        `uvm_info(get_type_name(), "build_phase(): Randomizing test_monitor configuration object", UVM_MEDIUM);
        if (!this.cfg.randomize()) begin
            `uvm_fatal(get_type_name(), "build_phase(): cfg.randomize() call failed!");
        end
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): cfg.sprint(): \n%s", this.cfg.sprint()), UVM_HIGH);

endfunction: build_phase

task test_monitor::run_phase(uvm_phase phase);

    super.run_phase(phase);
    this.sample_stimulus_data();

endtask: run_phase

task  test_monitor::sample_stimulus_data();

    //------------------------------------------------------------------------//
    // Implement sample_stimulus_data() task base on project requirement      //
    //------------------------------------------------------------------------//
    //-----------------------------Coding begin-------------------------------//
    // User sample the cpu data and assign to before_response_tr/after_response_tr
    //-----------------------------Coding end---------------------------------//
    test_xaction     mon_tr;        ///< The transaction to sample stimulus and be sent rm/checker component
    `uvm_info(get_type_name(), "sample_stimulus_data(): Start", UVM_HIGH); 

    if(this.proto.get_type_name() == "uvm_sequence_item") begin
        this.proto = test_xaction::type_id::create("proto", this);
        `uvm_info(get_type_name(), "sample_stimulus_data(): Proto be created in test_monitor", UVM_MEDIUM);
    end

    while(1) begin

        if(!$cast(mon_tr, this.proto.create())) begin
            `uvm_fatal(get_type_name(), "sample_stimulus_data(): proto is not a test_xaction type or its extension");
        end
        
        //--------------------------------------------------------------------//
        // Add the timing handle base on project requirement                  //
        //--------------------------------------------------------------------//
        //---------------------------Coding begin-----------------------------//
        // Sample stimulus from DUT
        // bit pkt_data[];
        // ......

        #10ns;    // Add the time only for environment run, user can delete it
        
        // void'(mon_tr.unpack(pkt_data));
        // this.out_port.write(mon_tr);
        // `uvm_info(get_type_name(), $sformatf("sample_stimulus_data(): Finish: %s", mon_tr.sprint()), UVM_HIGH);
        //---------------------------Coding end-------------------------------//
        
    end

endtask: sample_stimulus_data

`endif

