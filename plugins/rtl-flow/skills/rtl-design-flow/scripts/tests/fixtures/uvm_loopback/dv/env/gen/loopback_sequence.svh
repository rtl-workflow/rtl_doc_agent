class loopback_sequence extends uvm_sequence#(loopback_item);
  `uvm_object_utils(loopback_sequence)
  int unsigned count = 4;
  function new(string name = "loopback_sequence");
    super.new(name);
  endfunction
  task body();
    loopback_item item;
    for (int i = 0; i < count; i++) begin
      item = loopback_item::type_id::create("item");
      start_item(item);
      item.data = i == 0 ? 8'h00 : i == 1 ? 8'hff : 8'(i - 1);
      finish_item(item);
    end
  endtask
endclass
