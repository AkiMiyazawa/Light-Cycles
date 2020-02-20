`timescale 1ns / 1ps
module main(input clk, input btnS, input btn1, input btn2, input btn3,
	input btnR, output[7:0] seg, output[3:0] an,
	output[2:0] red, output[2:0] green, output[1:0] blue,
	output hsync, output vsync);

	// Parameters
	parameter fill_screen = ~768'b0;

	// Rename wires
	wire rst = btnS;
	wire L1 = btn1;
	wire L2 = btn3;
	wire R1 = btn2;
	wire R2 = btnR;

	// Button debouncing
	reg[2:0] L1_mem = 0;
	reg[2:0] L2_mem = 0;
	reg[2:0] R1_mem = 0;
	reg[2:0] R2_mem = 0;
	wire L1_posedge = ~L1_mem[0] & L1_mem[1] & L1_mem[2];
	wire L2_posedge = ~L2_mem[0] & L2_mem[1] & L2_mem[2];
	wire R1_posedge = ~R1_mem[0] & R1_mem[1] & R1_mem[2];
	wire R2_posedge = ~R2_mem[0] & R2_mem[1] & R2_mem[2];

	// Disable the 7-segment decimal points
	assign seg[7] = 1;

	// Clocks
	wire gclk;	// 2.98 Hz (for game)
	wire segclk;  // 381.47 Hz (for 7-segment display)
	wire dclk;	// 25 MHz (for VGA, 50% duty cycle)
	wire secclk;  // 1 Hz (for 3, 2, 1, GO)

	// Board state
	reg[3:0] cur_direction_1;  // encoded: LURD
	reg[3:0] cur_direction_2;
	reg[767:0] trace_1;
	reg[767:0] trace_2;
	reg[7:0] coord_1[1:0];
	reg[7:0] coord_2[1:0];
	wire[15:0] idx1 = coord_1[1] * 32 + coord_1[0];
	wire[15:0] idx2 = coord_2[1] * 32 + coord_2[0];
	reg[2:0] start_counter;

	// Submodules
	clockdiv clockdiv(clk, rst, gclk, segclk, dclk, secclk);
	segdisplay segdisplay(segclk, rst, start_counter, seg[6:0], an);
	vga640x480 vga640x480(
		dclk, rst, trace_1, trace_2, hsync, vsync, red, green, blue);

	// Game logic
	reg ovf;
	always @(posedge clk or posedge rst) begin
		// Update coordinates and traces
		if (rst) begin
			trace_1 = 0;
			trace_2 = 0;
			coord_1[0] = 2;
			coord_1[1] = 2;
			coord_2[0] = 29;
			coord_2[1] = 21;
		end
		else if (gclk && start_counter >= 3) begin
			case (cur_direction_1)
				4'b1000: begin  // left
					if (coord_1[0] != 0)
						coord_1[0] = coord_1[0] - 1;
				end
				4'b0100: begin  // up
					if (coord_1[1] != 0)
						coord_1[1] = coord_1[1] - 1;
				end
				4'b0010: begin  // right
					if (coord_1[0] != 31)
						coord_1[0] = coord_1[0] + 1;
				end
				4'b0001: begin  // down
					if (coord_1[1] != 23)
						coord_1[1] = coord_1[1] + 1;
				end
			endcase
			case (cur_direction_2)
				4'b1000: begin  // left
					if (coord_2[0] != 0)
						coord_2[0] = coord_2[0] - 1;
				end
				4'b0100: begin  // up
					if (coord_2[1] != 0)
						coord_2[1] = coord_2[1] - 1;
				end
				4'b0010: begin  // right
					if (coord_2[0] != 31)
						coord_2[0] = coord_2[0] + 1;
				end
				4'b0001: begin  // down
					if (coord_2[1] != 23)
						coord_2[1] = coord_2[1] + 1;
				end
			endcase

			// Fill screen with trace of winner
			if (trace_1[idx2]) begin
				trace_1 = fill_screen;
				trace_2 = 0;
			end
			else if (trace_2[idx1]) begin
				trace_1 = 0;
				trace_2 = fill_screen;
			end
			else if (trace_2[idx2]) begin
				trace_1 = fill_screen;
				trace_2 = 0;
			end
			else if (trace_1[idx1]) begin
				trace_1 = 0;
				trace_2 = fill_screen;
			end
			else begin
				trace_1[idx1] = 1;
				trace_2[idx2] = 1;
			end
		end

		// Update current directions
		if (rst) begin
			cur_direction_1 = 4'b0001;  // down
			cur_direction_2 = 4'b0100;  // up
		end
		else if (segclk) begin
			L1_mem = {L1, L1_mem[2:1]};
			L2_mem = {L2, L2_mem[2:1]};
			R1_mem = {R1, R1_mem[2:1]};
			R2_mem = {R2, R2_mem[2:1]};
			if (L1_posedge) begin
				cur_direction_1 = cur_direction_1 << 1;
				cur_direction_1[0] = !cur_direction_1;
			end
			else if (R1_posedge) begin
				cur_direction_1 = cur_direction_1 >> 1;
				cur_direction_1[3] = !cur_direction_1;
			end
			if (L2_posedge) begin
				cur_direction_2 = cur_direction_2 << 1;
				cur_direction_2[0] = !cur_direction_2;
			end
			else if (R2_posedge) begin
				cur_direction_2 = cur_direction_2 >> 1;
				cur_direction_2[3] = !cur_direction_2;
			end
		end

		// Update 7-segment display
		if (rst) begin
			start_counter = 0;
		end
		else if (secclk) begin
			start_counter =
				start_counter == 4 ? start_counter : start_counter + 1;
		end
	end
endmodule
