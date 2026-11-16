`ifndef MPI_PACKAGE__SV
`define MPI_PACKAGE__SV

`include "mpi_utils/src/mpi_dec.sv"
`include "mpi_utils/src/mpi_interface.sv"

package mpi_package;

    import uvm_pkg::*;
    import stb_basic_class_pkg::*;

    `include "mpi_utils/src/mpi_xaction.sv"
    `include "mpi_utils/src/mpi_sequence_library.svp"
    `include "mpi_utils/src/mpi_sequencer.sv"
    `include "mpi_utils/src/mpi_driver_cfg.sv"
    `include "mpi_utils/src/mpi_driver.sv"
    `include "mpi_utils/src/mpi_interface_agent_cfg.sv"
    `include "mpi_utils/src/mpi_interface_agent.sv"

endpackage: mpi_package

`endif

import mpi_package::*;

