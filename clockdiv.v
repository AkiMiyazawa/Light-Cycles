`timescale 1ns / 1ps
module clockdiv(input clk, input rst, output gclk, output reg segclk,
	output dclk, output reg secclk);

	reg[23:0] counter;
	reg[26:0] counter_1Hz;
	reg[18:0] counter_300Hz;
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter <= 0;
			counter_1Hz <= 0;
			counter_300Hz <= 0;
			secclk <= 0;
			segclk <= 0;
		end
		else begin
			counter <= counter + 1;
			if (counter_1Hz == 99_999_999) begin
				counter_1Hz <= 0;
				secclk <= 1;
			end
			else begin
				counter_1Hz <= counter_1Hz + 1;
				secclk <= 0;
			end
			if (counter_300Hz == 333_333) begin
				counter_300Hz <= 0;
				segclk <= 1;
			end
			else begin
				counter_300Hz <= counter_300Hz + 1;
				segclk <= 0;
			end
		end
	end

	// 100 Mhz / 2^24 = 5.96 Hz
	assign gclk = counter == 0;

	// 100 MHz / 2^2 = 25 MHz (50% duty cycle)
	assign dclk = counter[1];

endmodule
