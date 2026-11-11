class tc_loopback_smoke extends rtlflow_test_base;
  `uvm_component_utils(tc_loopback_smoke)
  loopback_env env;
  virtual loopback_if vif;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = loopback_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual loopback_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "test interface missing")
  endfunction
  task execute_test();
    loopback_sequence seq = loopback_sequence::type_id::create("seq");
    seq.count = env.cfg.count;
    seq.start(env.agent.sequencer);
    repeat (10) @(vif.mon_cb);
  endtask
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (env.scoreboard.compared != env.cfg.count)
      `uvm_error("COUNT", $sformatf("expected %0d comparisons, got %0d", env.cfg.count, env.scoreboard.compared))
  endfunction
  function void report_coverage();
    $display("COVER compared=%0d", env.scoreboard.compared);
    $display("COVER output=%0d", env.coverage.hits);
    $display("COVER zero=%0d", env.coverage.zero_hits);
    $display("COVER maximum=%0d", env.coverage.max_hits);
  endfunction
endclass
