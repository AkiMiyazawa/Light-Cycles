`timescale 1ns / 1ps
module vga640x480(input dclk, input rst, input[767:0] trace_1,
	input[767:0] trace_2, output hsync, output vsync, output reg[2:0] red,
	output reg[2:0] green, output reg[1:0] blue);

	// Video structure constants
	// Active horizontal video: 784 - 144 = 640
	// Active vertical video: 511 - 31 = 480
	parameter hpixels = 800;  // horizontal pixels per line
	parameter vlines = 521;   // vertical lines per frame
	parameter hpulse = 96;    // hsync pulse length
	parameter vpulse = 2;     // vsync pulse length
	parameter hbp = 144;      // end of horizontal back porch
	parameter hfp = 784;      // beginning of horizontal front porch
	parameter vbp = 31;       // end of vertical back porch
	parameter vfp = 511;      // beginning of vertical front porch

	// Horizontal & vertical counters and corresponding game_state index
	reg[9:0] hc;
	reg[9:0] vc;
	wire[5:0] h2 = (hc - hbp) >> 4;
	wire[5:0] v2 = (vc - vbp) >> 4;
	wire[10:0] idx = v2 * 32 + h2;

	// Incrementing horizontal & vertical counters
	always @(posedge dclk or posedge rst)
	begin
		if (rst) begin
			hc <= 0;
			vc <= 0;
		end
		else begin
			if (hc < hpixels - 1) begin
				hc <= hc + 1;
			end
			else begin
				// When we hit the end of the line, reset the horizontal
				// counter and increment the vertical counter.
				// If vertical counter is at the end of the frame, then
				// reset that one too.
				hc <= 0;
				vc <= vc < vlines - 1 ? vc + 1 : 0;
			end
		end
	end

	// Generate sync pulses (active low)
	assign hsync = hc < hpulse ? 0 : 1;
	assign vsync = vc < vpulse ? 0 : 1;

	// Display content
	always @* begin
		//if (vc < vbp || vc >= vfp || hc < hbp || hc >= hfp) begin
		if (vc < vbp || vc >= vbp + 384 || hc < hbp || hc >= hbp + 512) begin
			// We're outside active range so display black
			red = 0;
			green = 0;
			blue = 0;
		end
		else begin
			if (trace_1[idx]) begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b00;
			end
			else if (trace_2[idx]) begin
				red = 3'b000;
				green = 3'b111;
				blue = 2'b11;
			end
			else begin
				red = 3'b001;
				green = 3'b001;
				blue = 2'b10;
			end
		end
	end

endmodule
