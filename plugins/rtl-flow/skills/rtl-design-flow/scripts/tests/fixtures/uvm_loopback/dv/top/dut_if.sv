interface loopback_if(input logic clk);
  timeunit 1ns;
  timeprecision 1ps;
  logic rst_n = 0;
  logic in_valid = 0;
  logic [7:0] in_data = 0;
  wire out_valid;
  wire [7:0] out_data;
  clocking drv_cb @(negedge clk);
    default input #1step output #1ns;
    output in_valid, in_data;
  endclocking
  clocking mon_cb @(negedge clk);
    default input #1step;
    input rst_n, in_valid, in_data, out_valid, out_data;
  endclocking
endinterface
