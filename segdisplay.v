`timescale 1ns / 1ps
module segdisplay(input segclk, input rst, input[2:0] start_counter,
	output reg[6:0] seg, output reg[3:0] an);

	// Constants for displaying letters on display
	parameter empty = 7'b1111111;
	parameter three = 7'b0110000;
	parameter two = 7'b0100100;
	parameter one = 7'b1111001;
	parameter G = 7'b1000010;
	parameter O = 7'b1000000;

	// Finite State Machine (FSM) states
	parameter left = 2'b00;
	parameter midleft = 2'b01;
	parameter midright = 2'b10;
	parameter right = 2'b11;

	// State register
	reg[1:0] state;

	always @(posedge segclk or posedge rst) begin
		if (rst) begin
			seg <= empty;
			an <= 7'b1111;
			state <= left;
		end
		else case (state)
			left: begin
				seg <= empty;
				an <= 4'b0111;
				state <= midleft;
			end
			midleft: begin
				seg <= start_counter == 3 ? G : empty;
				an <= 4'b1011;
				state <= midright;
			end
			midright: begin
				case (start_counter)
					3: seg <= O;
					2: seg <= one;
					1: seg <= two;
					0: seg <= three;
					default: seg <= empty;
				endcase
				an <= 4'b1101;
				state <= right;
			end
			right: begin
				seg <= empty;
				an <= 4'b1110;
				state <= left;
			end
		endcase
	end

endmodule
