module AutoReset #(
   parameter INVERT_RST = 1'b0
)(
input clk,
input [31:0] count,
input clr,
output reg rst = 1'b1
);

reg [32:0] clk_count = 1'b0;


always @(negedge clk)
	if (clr) 
	begin
		clk_count <= 1'b0;
		rst <= !INVERT_RST;
	end
	else if (clk_count > count) rst <= INVERT_RST;
	else 
	begin 
		clk_count <= clk_count + 1;
		rst <= !INVERT_RST;
	end
endmodule
