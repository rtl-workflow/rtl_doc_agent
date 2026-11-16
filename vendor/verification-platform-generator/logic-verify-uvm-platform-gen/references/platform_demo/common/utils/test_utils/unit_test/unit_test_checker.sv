//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : unit_test_checker.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : checker
//
//******************************************************************************

`ifndef UNIT_TEST_CHECKER__SV
`define UNIT_TEST_CHECKER__SV

/** \brief  Checker class
 This checker class provide the following default  behaviour:
 -get data output which before handled by dut through monitor to checker port
 -get data output which after handled by dut through monitor to checker port
 -complete data checking automatically using scoreboard 
*/
class unit_test_checker extends stb_function_component #(2, 0);

    `uvm_component_utils(unit_test_checker)

    bit                                        chk_predicted_port; ///< This varible is to check the out_port in driver has been written
    stb_basic_scoreboard                       order_sb;
    stb_basic_checker                          basic_chk;
    uvm_blocking_put_port #(uvm_sequence_item) sb_predicted_port;
    uvm_blocking_put_port #(uvm_sequence_item) sb_observed_port;
    uvm_tlm_analysis_fifo #(uvm_sequence_item) analysis_fifo[2];

    //------------------------------------------------------------------------//
    // Define the member variables base on project requirement                //
    //------------------------------------------------------------------------//    
    //-----------------------------Coding begin-------------------------------//

    //-----------------------------Coding end---------------------------------//

    /** \brief new
    Constructor
    */
    extern function new(string        name,
                        uvm_component parent
                        );  
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);

    /** \brief sim_predicted_process
    Transction get from predicted in port, judge if the address has been written before. Do as slave driver 
    */  
    extern virtual task sim_predicted_process(); 

    /** \brief sim_observed_process
    Transction get from observed in port 
    */ 
    extern virtual task sim_observed_process();

endclass: unit_test_checker

function unit_test_checker::new(string        name,
                                uvm_component parent
                               );

    super.new(name, parent);

    this.chk_predicted_port = 1'b0;

endfunction: new

function void unit_test_checker:: build_phase(uvm_phase phase);

    super.build_phase(phase);
    
    this.order_sb = stb_basic_scoreboard::type_id::create("order_sb", this);

    this.basic_chk = stb_basic_checker::type_id::create("basic_chk", this);
    this.sb_predicted_port = new("sb_predicted_port", this);
    this.sb_observed_port = new("sb_observed_port", this);
    foreach(this.analysis_fifo[i]) begin
        this.analysis_fifo[i] = new($sformatf("analysis_fifo[%0d]", i), this);
    end
    uvm_config_db #(stb_basic_scoreboard)::set(this, "basic_chk", "scoreboard", this.order_sb);

endfunction

function void unit_test_checker::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    this.sb_predicted_port.connect(this.analysis_fifo[0].blocking_put_export);
    this.basic_chk.in_port[0].connect(this.analysis_fifo[0].blocking_get_export);

    this.sb_observed_port.connect(this.analysis_fifo[1].blocking_put_export);
    this.basic_chk.in_port[1].connect(this.analysis_fifo[1].blocking_get_export);

endfunction: connect_phase

task unit_test_checker::run_phase(uvm_phase phase);
    
    super.run_phase(phase);
    
    fork
        begin
            this.sim_predicted_process();
        end
   
        begin
            this.sim_observed_process();
        end
    join

endtask: run_phase

task unit_test_checker::sim_observed_process(); 

    while(1) begin

        uvm_sequence_item obs_tr;
        test_xaction        observed_tr;
        this.in_port[1].get(obs_tr);
        if(this.chk_predicted_port == 1'b0) begin
            `uvm_fatal(get_type_name(), "sim_observed_process(): Please checking the out_port in driver has been written");
        end
        `uvm_info(get_type_name(), $sformatf("sim_observed_process(): in_port get obs_tr: \n%s", obs_tr.sprint()), UVM_DEBUG);
        if(!$cast(observed_tr, obs_tr)) begin
            `uvm_fatal(get_type_name(), "sim_observed_process(): Checker received packet is not a test_xaction type or its extension");
        end

        #10ns;    // Add some time to make sure predicted data to scoreboard is before observed data

        this.sb_observed_port.put(observed_tr);
    end

endtask: sim_observed_process

task unit_test_checker::sim_predicted_process();

    while (1) begin

        uvm_sequence_item  pre_tr;
        test_xaction         predicted_tr;
        this.in_port[0].get(pre_tr);
        this.chk_predicted_port = 1'b1;
        `uvm_info(get_type_name(), $sformatf("sim_predicted_process(): in_port get pre_tr: \n%s", pre_tr.sprint()), UVM_DEBUG);
        if(!$cast(predicted_tr, pre_tr)) begin
            `uvm_fatal(get_type_name(), "sim_predicted_process(): checker received packet is not a test_xaction type or its extension");
        end
     
        //--------------------------------------------------------------------//
        //  Add predicted data process base on project requirement            //
        //--------------------------------------------------------------------//      
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//
        
        this.sb_predicted_port.put(predicted_tr);
    end

endtask: sim_predicted_process

`endif

