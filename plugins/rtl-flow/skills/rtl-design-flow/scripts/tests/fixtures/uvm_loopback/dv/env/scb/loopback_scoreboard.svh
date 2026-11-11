class loopback_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(loopback_scoreboard)
  uvm_tlm_analysis_fifo#(loopback_item) expected_fifo, actual_fifo;
  int unsigned compared;
  bit pending_expected;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_fifo = new("expected_fifo", this);
    actual_fifo = new("actual_fifo", this);
  endfunction
  task run_phase(uvm_phase phase);
    loopback_item expected, actual;
    forever begin
      expected_fifo.get(expected);
      pending_expected = 1;
      actual_fifo.get(actual);
      pending_expected = 0;
      if (actual.data !== expected.data)
        `uvm_error("MISMATCH", $sformatf("expected=%02h actual=%02h", expected.data, actual.data))
      compared++;
    end
  endtask
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (pending_expected || expected_fifo.used() != 0 || actual_fifo.used() != 0)
      `uvm_error("UNDRAINED", "unmatched transactions remain at end of test")
  endfunction
endclass
