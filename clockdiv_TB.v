`timescale 1ms / 1ns
module clockdiv_TB;
	reg clk;
	reg rst;
	wire gclk;
	wire dclk;
	wire segclk;
	wire secclk;
	clockdiv clockdiv(clk, rst, gclk, segclk, dclk, secclk);

	initial begin
		clk = 0;
		rst = 1;
		#1 rst = 0;
		#2600 $finish;
	end

	always begin
		#0.000_005 clk = ~clk;  // 100 MHz
	end
endmodule
