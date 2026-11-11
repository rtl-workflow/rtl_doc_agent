class loopback_env extends uvm_env;
  `uvm_component_utils(loopback_env)
  loopback_env_cfg cfg;
  loopback_agent agent;
  loopback_model model;
  loopback_scoreboard scoreboard;
  loopback_coverage coverage;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = loopback_env_cfg::type_id::create("cfg");
    agent = loopback_agent::type_id::create("agent", this);
    model = loopback_model::type_id::create("model", this);
    scoreboard = loopback_scoreboard::type_id::create("scoreboard", this);
    coverage = loopback_coverage::type_id::create("coverage", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.input_ap.connect(model.analysis_export);
    model.expected_ap.connect(scoreboard.expected_fifo.analysis_export);
    agent.monitor.output_ap.connect(scoreboard.actual_fifo.analysis_export);
    agent.monitor.output_ap.connect(coverage.analysis_export);
  endfunction
endclass
