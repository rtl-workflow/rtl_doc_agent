class loopback_model extends uvm_subscriber#(loopback_item);
  `uvm_component_utils(loopback_model)
  uvm_analysis_port#(loopback_item) expected_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
  endfunction
  function void write(loopback_item t);
    loopback_item expected = loopback_item::type_id::create("expected");
    // Specification: preserve the accepted byte value and transaction order.
    expected.data = t.data;
    expected_ap.write(expected);
  endfunction
endclass
