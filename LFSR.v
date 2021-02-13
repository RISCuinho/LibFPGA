//https://www.fpga4fun.com/Counters3.html
module LFSR 
#(
parameter SIZE = 8
)
(
  input clk,
  input rst,
  input [SIZE-1:0] tap,
  input [SIZE-1:0] seed,
  output reg [SIZE-1:0] LFSR
);

initial begin
	LFSR <= seed;
end
//wire [SIZE - 1:0] max       = (2 ** SIZE) -1;
//wire [SIZE - 1:0] min       = max + 1;
//wire [SIZE - 1:0] local_tap = tap == min || tap == max ? min + 2'b10 : tap;
wire [SIZE - 1:0] local_tap = tap == {SIZE{1'b0}} || tap == {SIZE{1'b1}} ? {{SIZE-2{1'b0}},2'b10} : tap;

wire feedback = LFSR[SIZE - 1] ^ (LFSR[SIZE - 2:0] == {SIZE{1'b0}});

initial 
begin
	$display("LFSR SIZE %d:",SIZE);
	$display("LFSR: CLK RST SEED     LFSR     Feedback");
end

initial
	$monitor("LFSR:  %b  %b  %d      %b     %b", clk, rst, seed, LFSR, feedback);

integer b;
always @(posedge clk)
begin
	if(rst)
		LFSR <= seed;
	else
	begin
	  LFSR[0] <= feedback;
	  for ( b = 1; b < SIZE; b = b + 1 )
		  LFSR[b] <= local_tap[b] ? LFSR[b - 1] ^ feedback: LFSR[b - 1];		  
		 // LFSR[b] <= LFSR[b - 1];		  
	end
end
endmodule
