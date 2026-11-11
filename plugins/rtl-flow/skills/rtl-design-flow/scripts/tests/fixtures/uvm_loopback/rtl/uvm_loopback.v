module uvm_loopback (
    input clk,
    input rst_n,
    input in_valid,
    input [7:0] in_data,
    output reg out_valid,
    output reg [7:0] out_data
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 1'b0;
    else out_valid <= in_valid;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out_data <= 8'b0;
    else if (in_valid) out_data <= in_data;
end
endmodule
