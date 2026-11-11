module uvm_loopback_tb;
  timeunit 1ns;
  timeprecision 1ps;
  import uvm_pkg::*;
  import loopback_env_pkg::*;
  bit clk = 0;
  always #5ns clk = ~clk;
  loopback_if bus(clk);
  uvm_loopback U_dut(.clk(clk), .rst_n(bus.rst_n), .in_valid(bus.in_valid),
                    .in_data(bus.in_data), .out_valid(bus.out_valid), .out_data(bus.out_data));
  initial begin
    repeat (3) @(negedge clk);
    #2ns bus.rst_n = 1;
  end
  initial begin
    uvm_config_db#(virtual loopback_if)::set(null, "*", "vif", bus);
    run_test();
  end
endmodule
