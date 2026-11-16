//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_interface_agent.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : agent top  
//
//******************************************************************************

`ifndef MPI_INTERFACE_AGENT__SV
`define MPI_INTERFACE_AGENT__SV

/** \brief interface agent
    Define by user, extend mpi_interface_agent , to wrap the agent component     
*/
class mpi_interface_agent extends stb_interface_agent #(virtual mpi_interface);

    mpi_xaction                                     mpi_proto;                    ///< The proto for stb_reg_adapter
    stb_reg_adapter                                 mpi_reg_adapter;              ///< The adapter for reg model
    mpi_interface_agent_cfg                         cfg;                          ///< Define mpi_interface_agent configure
    mpi_sequencer                                   mpi_sqr;                      ///< Define mpi sequencer
    mpi_driver                                      mpi_drv;                      ///< Define mpi driver

    `uvm_component_utils_begin(mpi_interface_agent)
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

endclass:mpi_interface_agent 

function mpi_interface_agent::new(string        name,
                                 uvm_component  parent
                                 );
    super.new(name, parent);

endfunction: new

function void mpi_interface_agent::build_phase(uvm_phase phase);

	super.build_phase(phase);

    if(this.cfg == null) begin
        this.cfg = mpi_interface_agent_cfg::type_id::create("cfg", this);
        `uvm_info(get_type_name(), "build_phase(): Randomizing mpi_interface_agent configuration object", UVM_MEDIUM);
        if (!this.cfg.randomize()) begin
            `uvm_fatal(get_type_name(),"build_phase(): cfg.randomize() call failed!");
        end
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): cfg.sprint(): \n%s", cfg.sprint()), UVM_HIGH);

    if(this.sqr_sw == stb_dec::ON) begin
        this.mpi_sqr = mpi_sequencer::type_id::create("mpi_sqr", this);
        if(!$cast(this.sqr, this.mpi_sqr)) begin
            `uvm_fatal(get_type_name(), "new(): mpi_sqr is not a uvm_sequencer type or its extension");
        end
    end

    if(this.adapter == null && this.adapter_sw == stb_dec::ON) begin
        this.mpi_proto = mpi_xaction::type_id::create("mpi_proto", this);
        this.mpi_reg_adapter = stb_reg_adapter::type_id::create("mpi_reg_adapter", this);
        if(!$cast(this.adapter, this.mpi_reg_adapter)) begin
            `uvm_fatal(get_type_name(), $sformatf("build_phase(): The mpi_reg_adapter type name is %s, not uvm_reg_adapter extension", this.mpi_reg_adapter.get_type_name));
        end
        this.mpi_reg_adapter.proto = this.mpi_proto;
        `uvm_info(get_type_name(), "build_phase(): Use stb_reg_adapter to adapter uvm_reg_item to stb_rw_sequence_item", UVM_HIGH);
    end

    if(this.drv_sw == stb_dec::ON) begin
        this.mpi_drv = mpi_driver::type_id::create("mpi_drv", this);
        this.mpi_drv.cfg = this.cfg.mpi_drv_cfg;
        if(!$cast(this.drv, this.mpi_drv)) begin
            `uvm_fatal(get_type_name(), "new(): mpi_drv is not a stb_driver type or its extension");
        end
    end


endfunction: build_phase

`endif

