//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : test_interface_agent.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : agent top  
//
//******************************************************************************

`ifndef TEST_INTERFACE_AGENT__SV
`define TEST_INTERFACE_AGENT__SV

/** \brief interface agent
    Define by user, extend stb_interface_agent , to wrap the agent component     
*/
class test_interface_agent extends stb_interface_agent #(virtual test_interface);

    test_interface_agent_cfg                        cfg;                          ///< Define test_interface_agent configure
    test_sequencer                                  test_sqr;                     ///< Define test sequencer
    test_driver                                     test_drv;                     ///< Define test driver
    test_monitor                                    test_mon;                     ///< Define test monitor
    test_monitor_cov                                test_mon_cov;                 ///< Define test monitor coverage model

    `uvm_component_utils_begin(test_interface_agent)
        `uvm_field_object(cfg, UVM_ALL_ON)

        //--------------------------------------------------------------------//
        // Add variables into field-automation base on project requirement    //
        //--------------------------------------------------------------------//
        //-------------------------Coding begin-------------------------------//

        //-------------------------Coding end---------------------------------//         
    `uvm_component_utils_end

    /** \brief new
    Constructor
    */
    extern function new(string        name,
                        uvm_component parent
                       ); 

    /** \brief build_phase
    Calls super.build_phase(phase) to enable automatic get config and create object 
    */  
    extern virtual function void build_phase(uvm_phase phase);

endclass:test_interface_agent 

function test_interface_agent::new(string        name,
                                  uvm_component  parent
                                  );
    super.new(name, parent);
    this.mon_cov_sw = stb_dec::ON;

endfunction: new

function void test_interface_agent::build_phase(uvm_phase phase);

	super.build_phase(phase);

    if(this.cfg == null) begin
        this.cfg = test_interface_agent_cfg::type_id::create("cfg", this);
        `uvm_info(get_type_name(), "build_phase(): Randomizing test_interface_agent configuration object", UVM_MEDIUM);
        if (!this.cfg.randomize()) begin
            `uvm_fatal(get_type_name(),"build_phase(): cfg.randomize() call failed!");
        end
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): cfg.sprint(): \n%s", this.cfg.sprint()), UVM_HIGH);

    if(this.sqr_sw == stb_dec::ON) begin
        this.test_sqr = test_sequencer::type_id::create("test_sqr", this);
        if(!$cast(this.sqr, this.test_sqr)) begin
            `uvm_fatal(get_type_name(), "new(): test_sqr is not a uvm_sequencer type or its extension");
        end
    end

    if(this.drv_sw == stb_dec::ON) begin
        this.test_drv = test_driver::type_id::create("test_drv", this);
        this.test_drv.cfg = this.cfg.test_drv_cfg;
        if(!$cast(this.drv, this.test_drv)) begin
            `uvm_fatal(get_type_name(), "new(): test_drv is not a stb_driver type or its extension");
        end
    end

    if(this.mon_sw == stb_dec::ON) begin
        this.test_mon = test_monitor::type_id::create("test_mon", this);
        this.test_mon.cfg = this.cfg.test_mon_cfg;
        if(!$cast(this.mon, this.test_mon)) begin
            `uvm_fatal(get_type_name(), "new(): test_mon is not a stb_monitor type or its extension");
        end
    end
    else begin
        this.mon_cov_sw = stb_dec::OFF;
    end

    if(mon_cov_sw == stb_dec::ON) begin
        this.test_mon_cov = test_monitor_cov::type_id::create("test_mon_cov", this);
        if(!$cast(this.mon_cov, this.test_mon_cov)) begin
            `uvm_fatal(get_type_name(), "new(): test_mon_cov is not a uvm_subscriber type or its extension");
        end
    end


endfunction: build_phase

`endif

