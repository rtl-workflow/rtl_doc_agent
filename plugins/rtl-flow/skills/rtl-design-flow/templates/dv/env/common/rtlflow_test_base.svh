`ifndef RTLFLOW_TEST_BASE_SVH
`define RTLFLOW_TEST_BASE_SVH

// Include inside env_pkg after importing uvm_pkg and uvm_macros.svh.
// Test classes override execute_test(), create their env in build_phase(),
// and export real functional hit counters from report_coverage().
class rtlflow_test_base extends uvm_test;
  `uvm_component_utils(rtlflow_test_base)

  string flow_test;
  string flow_class;
  int flow_seed;
  time watchdog = 1ms;

  function new(string name = "rtlflow_test_base", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    uvm_root root;
    super.build_phase(phase);
    if (!$value$plusargs("TEST=%s", flow_test) ||
        !$value$plusargs("SEED=%d", flow_seed) ||
        !$value$plusargs("UVM_TESTNAME=%s", flow_class))
      `uvm_fatal("FLOW_ARGS", "Run via run_regress.py with TEST, SEED and UVM_TESTNAME")
    root = uvm_root::get();
    root.set_timeout(watchdog, 0);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    $display("RTL_FLOW_UVM_STARTED %s SEED %0d CLASS %s", flow_test, flow_seed, flow_class);
    `uvm_info("FLOW_TYPE", $sformatf("Selected %s, actual factory type %s", flow_class, get_type_name()), UVM_LOW)
  endfunction

  virtual task execute_test();
    `uvm_fatal("UNIMPLEMENTED", "Derived test must implement stimulus and completion checks")
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    execute_test();
    phase.drop_objection(this);
  endtask

  virtual function void report_coverage();
    // Derived test exports COVER <point>=<real hit count> using $display.
    // A real UVM regression with no counters fails in run_regress.py.
  endfunction

  function void final_phase(uvm_phase phase);
    uvm_report_server server;
    int errors;
    super.final_phase(phase);
    report_coverage();
    server = uvm_report_server::get_server();
    errors = server.get_severity_count(UVM_ERROR) + server.get_severity_count(UVM_FATAL);
    $display("RTL_FLOW_UVM_COMPLETED %s SEED %0d CLASS %s", flow_test, flow_seed, flow_class);
    $display("TEST %s SEED %0d %s errors=%0d", flow_test, flow_seed,
             errors == 0 ? "PASSED" : "FAILED", errors);
  endfunction
endclass
`endif
