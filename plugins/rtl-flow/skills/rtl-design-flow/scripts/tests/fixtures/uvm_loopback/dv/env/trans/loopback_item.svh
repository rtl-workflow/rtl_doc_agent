class loopback_item extends uvm_sequence_item;
  rand bit [7:0] data;
  `uvm_object_utils_begin(loopback_item)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end
  function new(string name = "loopback_item");
    super.new(name);
  endfunction
endclass
