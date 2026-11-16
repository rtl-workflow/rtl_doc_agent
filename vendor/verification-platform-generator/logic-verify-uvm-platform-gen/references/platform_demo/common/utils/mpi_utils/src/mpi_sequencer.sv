//******************************************************************************
// Copyright(c) 2013, Hisilicon Technologies Co, Ltd.
// All rights reserved.
//
// PROJECT NAME  : LVP_TEST
// FILENAME      : mpi_sequencer.sv
// AUTHOR        : x00508178
// EMAIL         : 
// CREATION TIME : 2023-05-31
// VERSION       : 5.0
// ABSTRACT      : Sequencer for mpi_agent
//
//******************************************************************************

`ifndef MPI_SEQUENCER__SV
`define MPI_SEQUENCER__SV

/** /brief mpi_sequencer
    Sequencer for mpi_agent.
*/
class mpi_sequencer extends uvm_sequencer #(uvm_sequence_item);

    `uvm_component_utils(mpi_sequencer)

    /** \brief Constructor
    Call super.new();
    */
    extern function new(string name,
                        uvm_component parent
                        );

    /** \brief build_phase
    Calls super.build_phase(phase) to enable automatic get config and create object 
    */
    extern function void build_phase(uvm_phase phase);

endclass: mpi_sequencer

function mpi_sequencer::new(string        name,
                           uvm_component  parent
                           );
                         
    super.new(name, parent);

endfunction: new

function void mpi_sequencer::build_phase(uvm_phase phase);

    super.build_phase(phase);
    `uvm_info(get_type_name(), "build_phase(): mpi_sequencer build_phase is done", UVM_HIGH);

endfunction

`endif

