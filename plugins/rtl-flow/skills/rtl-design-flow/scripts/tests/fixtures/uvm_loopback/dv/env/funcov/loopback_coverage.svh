class loopback_coverage extends uvm_subscriber#(loopback_item);
  `uvm_component_utils(loopback_coverage)
  int unsigned hits, zero_hits, max_hits;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void write(loopback_item t);
    hits++;
    if (t.data == 0) zero_hits++;
    if (t.data == 255) max_hits++;
  endfunction
endclass
