class loopback_driver extends uvm_driver#(loopback_item);
  `uvm_component_utils(loopback_driver)
  virtual loopback_if vif;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual loopback_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "driver interface missing")
  endfunction
  task run_phase(uvm_phase phase);
    loopback_item item;
    wait (vif.rst_n === 1'b1);
    forever begin
      seq_item_port.get_next_item(item);
      @(vif.drv_cb);
      vif.drv_cb.in_valid <= 1;
      vif.drv_cb.in_data <= item.data;
      @(vif.drv_cb);
      vif.drv_cb.in_valid <= 0;
      seq_item_port.item_done();
    end
  endtask
endclass

class loopback_monitor extends uvm_monitor;
  `uvm_component_utils(loopback_monitor)
  virtual loopback_if vif;
  uvm_analysis_port#(loopback_item) input_ap, output_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    input_ap = new("input_ap", this);
    output_ap = new("output_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual loopback_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "monitor interface missing")
  endfunction
  task run_phase(uvm_phase phase);
    loopback_item item;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst_n === 1'b1) begin
        if (vif.mon_cb.in_valid === 1'b1) begin
          item = loopback_item::type_id::create("input_item");
          item.data = vif.mon_cb.in_data;
          input_ap.write(item);
        end
        if ($isunknown(vif.mon_cb.out_valid))
          `uvm_error("X_VALID", "output valid is unknown after reset")
        if (vif.mon_cb.out_valid === 1'b1) begin
          if ($isunknown(vif.mon_cb.out_data))
            `uvm_error("X_DATA", "valid output data is unknown")
          item = loopback_item::type_id::create("output_item");
          item.data = vif.mon_cb.out_data;
          output_ap.write(item);
        end
      end
    end
  endtask
endclass

class loopback_agent extends uvm_agent;
  `uvm_component_utils(loopback_agent)
  uvm_sequencer#(loopback_item) sequencer;
  loopback_driver driver;
  loopback_monitor monitor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer#(loopback_item)::type_id::create("sequencer", this);
    driver = loopback_driver::type_id::create("driver", this);
    monitor = loopback_monitor::type_id::create("monitor", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
