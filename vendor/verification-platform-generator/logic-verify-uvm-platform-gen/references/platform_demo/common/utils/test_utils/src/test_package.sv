`ifndef TEST_PACKAGE__SV
`define TEST_PACKAGE__SV

`include "test_utils/src/test_dec.sv"
`include "test_utils/src/test_interface.sv"

package test_package;

    import uvm_pkg::*;
    import stb_basic_class_pkg::*;

    `include "test_utils/src/test_xaction.sv"
    `include "test_utils/src/test_sequence_library.svp"
    `include "test_utils/src/test_sequencer.sv"
    `include "test_utils/src/test_driver_cfg.sv"
    `include "test_utils/src/test_driver.sv"
    `include "test_utils/src/test_monitor_cfg.sv"
    `include "test_utils/src/test_monitor.sv"
    `include "test_utils/src/test_monitor_cov.sv"
    `include "test_utils/src/test_interface_agent_cfg.sv"
    `include "test_utils/src/test_interface_agent.sv"

endpackage: test_package

`endif

import test_package::*;

