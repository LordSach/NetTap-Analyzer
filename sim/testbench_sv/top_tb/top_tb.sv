`timescale 1ns/1ps
module top_tb;
logic clk = 0;
logic rst_n = 0;


always #5 clk = ~clk;


initial begin
rst_n = 0;
#100;
rst_n = 1;
end


initial begin
$dumpfile("top_tb.vcd");
$dumpvars(0, top_tb);
#10000;
$finish;
end
endmodule
