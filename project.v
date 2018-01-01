// Part 2 skeleton

module project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire ld_0, ld_1, ld_2, ld_3;
	wire lshift, rshift;
	
	assign lshift = KEY[2];
	assign rshift = KEY[1];
	
	eggscontrol c(.resetn(resetn), .clock(CLOCK_50), .ld_0(ld_0), .ld_1(ld_1), .ld_2(ld_2), .ld_3(ld_3));
	eggsdatapath d(.resetn(resetn), .clock(CLOCK_50), .ld_0(ld_0), .ld_1(ld_1), .ld_2(ld_2), .ld_3(ld_3),
		.lshift(lshift), .rshift(rshift), .x(x), .y(y), .colour(colour), .writeEn(writeEn));
	
endmodule

module eggscontrol(resetn, clock, ld_0, ld_1, ld_2, ld_3);
	input resetn, clock;
	output reg ld_0, ld_1, ld_2, ld_3;
	
	wire [3:0] out;
	
	lfsr l(.out(out), .clock(clock), .resetn(resetn));
	
	always @(posedge clock) begin
		if (!resetn) begin // active high resetn
			ld_0 <= 1'b0;
			ld_1 <= 1'b0;
			ld_2 <= 1'b0;
			ld_3 <= 1'b0;
		end else begin
			ld_0 = (out % 4'd15 == 4'd1); // 1 when divisible by 4
			ld_1 = (out % 4'd15 == 4'd2); // 1 when divisible by 1 mod 4
			ld_2 = (out % 4'd15 == 4'd11); // 1 when divisible by 2 mod 4
			ld_3 = (out % 4'd15 == 4'd3); // 1 when divisible by 3 mod 4
		end
	end

endmodule

module eggsdatapath(resetn, clock, ld_0, ld_1, ld_2, ld_3, lshift, rshift, x, y, colour, writeEn);
	input resetn, clock;
	input ld_0, ld_1, ld_2, ld_3;
	input lshift, rshift;
	
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] colour;
	output reg writeEn;
	
	wire [29:0] q;
	wire enclock;
	
	wire not_lost; // wire for the collision effect.

	ratedivider r(.d(30'd9_999_999), .clock(clock), .resetn(resetn), .q(q)); // change this during VGA simulation to 5,000,000

	assign enclock = ( q == 0 ) ? 1 : 0 ;
	
	reg [119:0] reg0, reg1, reg2, reg3;
	
	always @(posedge enclock) 
 	begin 
    	if (!resetn || !not_lost) 
      		reg0 = 120'd0;
    	else if (ld_0)
        	reg0 = {1'd1, reg0[119:1]};
      	else
			reg0 = {1'd0, reg0[119:1]};
  	end
	
	always @(posedge enclock) 
 	begin 
    	if (!resetn || !not_lost) 
      		reg1 = 120'd0;
    	else if (ld_1)
        	reg1 = {1'd1, reg1[119:1]};
      	else
			reg1 = {1'd0, reg1[119:1]};
  	end
	
	always @(posedge enclock) 
 	begin 
    	if (!resetn || !not_lost) 
      		reg2 = 120'd0;
    	else if (ld_2)
        	reg2 = {1'd1, reg2[119:1]};
      	else
			reg2 = {1'd0, reg2[119:1]};
  	end
	
	always @(posedge enclock) 
 	begin 
    	if (!resetn || !not_lost) 
      		reg3 = 120'd0;
    	else if (ld_3)
        	reg3 = {1'd1, reg3[119:1]};
      	else
			reg3 = {1'd0, reg3[119:1]};
  	end
	
	reg [7:0] basket_pos;
	reg [2:0] bas_pos; // for detecting the position of the basket.
	
	always @(posedge lshift) 
 	begin 
    	if (!resetn) begin
      	basket_pos <= 8'd0;
			bas_pos <= 3'b100;
		end
    	else
			if (basket_pos == 8'd80) begin
				basket_pos <= 8'd0;
				bas_pos <= 3'b100;
			end
			else begin
				basket_pos <= basket_pos + 8'd40;
				bas_pos <= {bas_pos[0], bas_pos[2:1]};
			end
  	end
	
	wire [8:0] datacounter; // for writing from different registers and y-locations.
	wire [1:0] which_reg; // for determining which register to write from.
	wire [6:0] reg_location; // for writing a y-location with a different register.
	
	datapathcounter d(.out(datacounter), .clock(clock), .resetn(resetn));
	
	assign which_reg = datacounter[8:7];
	assign reg_location = datacounter[6:0] % 120;
	
	reg [7:0] x_val;
	reg [119:0] cur_reg;
	
	always @(*)
	begin
		case (which_reg) // we write in different x-values for each register
			2'b00: begin
				x_val = 8'd40;
				cur_reg = reg0;
			end
			2'b01: begin
				x_val = 8'd80;
				cur_reg = reg1;
			end
			2'b10: begin
				x_val = 8'd120;
				cur_reg = reg2;
			end
			2'b11: begin
				x_val = 8'd0;
				cur_reg = reg3;
			end
			default: ;
		endcase
	end
	
	wire [1:0] bcounter; // for drawing the basket
	
	basketcounter d0(.out(bcounter), .clock(clock), .resetn(resetn));
	
	always @ (posedge clock) begin
			if (which_reg == 2'b11) begin
					colour <= 3'b100;
					x <= basket_pos + 8'd40;
					y <= 7'd119;
					writeEn <= 1'b1;
			end
			else if (cur_reg[reg_location]) begin
				colour <= 3'b111;
				x <= x_val;
				y <= 7'd119 - reg_location;
				writeEn <= 1'b1;
			end
			 else begin
				colour <= 3'b000;
				x <= x_val;
				y <= 7'd119 - reg_location;
				writeEn <= 1'b1;
			end
    end
	 
	 wire [2:0] egg_collision, or_handle;

	 assign egg_collision = {reg0[0], reg1[0], reg2[0]};
	 assign or_handle = (egg_collision | bas_pos);
	 
	 assign not_lost = (or_handle == bas_pos);
endmodule

module basketcounter (out, clock, resetn);
output reg [1:0] out;
input clock, resetn;

wire [29:0] q;
wire enable, enclock;

ratedivider r(.d(30'd49), .clock(clock), .resetn(resetn), .q(q));

assign enclock = ( q == 0 ) ? 1 : 0 ;

always @(posedge enclock) begin
	if (!resetn) begin // active high resetn
		out <= 2'd0;
	end else begin
		if (out == 2'd2)
			out <= 2'd0;
		else
			out <= out + 2'd1;
	end
end
endmodule 

module datapathcounter (
out      ,  // Output of the counter
clock      ,  // clock input
resetn       // resetn input
);

output reg [8:0] out;
input clock, resetn;

wire [29:0] q;
wire enable;

always @(posedge clock) begin
	if (!resetn) begin // active high resetn
		out <= 9'd0;
	end else begin
		if (out == 9'b1111_11111)
			out <= 9'd0;
		else
			out <= out + 9'd1;
	end
end
endmodule 

module resetcounter (
out      ,  // Output of the counter
clock      ,  // clock input
resetn       // resetn input
);
//----------Output Ports--------------
output reg [13:0] out;
//------------Input Ports-------------- 
input clock, resetn;
//------------Internal Variables--------
//-------------Code Starts Here-------
always @(posedge clock) begin
	if (!resetn) begin // active high resetn
		out <= 14'd0;
	end else begin
		if (out == 14'b11111_11111_1111)
			out <= 14'd0;
		else
			out <= out + 14'd1;
	end
end
endmodule 

//-----------------------------------------------------
// Design Name : lfsr
// File Name   : lfsr.v
// Function    : Linear feedback shift register
// Coder       : Deepak Kumar Tala (modified for Project)
//-----------------------------------------------------
module lfsr    (
out             ,  // Output of the counter
clock             ,  // clock input
resetn              // resetn input
);

//----------Output Ports--------------
output [3:0] out;
//------------Input Ports--------------
input clock, resetn;
//------------Internal Variables--------
reg [3:0] out;
wire        l3, l2, l1, l0;
// wire enable;
wire [29:0] q;

wire enable;

ratedivider r(.d(30'd9_999_999), .clock(clock), .resetn(resetn), .q(q)); // change this during VGA simulation to 5,000,000

assign enable = ( q == 0 ) ? 1 : 0 ;

//-------------Code Starts Here-------
assign l3 = !(out[3] ^ out[0]);
assign l2 = !(out[2] ^ l3);
assign l1 = !(out[1] ^ l2);
assign l0 = !(out[0] ^ l1);

always @(posedge clock)
if (!resetn) begin // active high resetn
  out <= 4'b0 ;
end else if (enable) begin
  out <= {l3, l2, l1, l0};
end 

endmodule // End Of Module counter

module ratedivider(d, clock, resetn, q);
	
	input wire [29:0] d; // Declare d
	input wire clock; // Declare c l o c k
	input wire resetn; // Declare r e s e t n
	
	output reg [29:0] q; // Declare q
	
	always @(posedge clock)
	begin
		if (!resetn)
			q <= 0 ;
		else begin
			if ( q == 0 ) // When q is 0
				q <= d ; // resetn q into d
			else // When q i s not the maximum v a lue
				q <= q - 1'd1 ; // Increment q
		end
	end
	
endmodule
