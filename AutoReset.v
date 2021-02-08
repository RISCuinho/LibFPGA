module AutoReset (
input clk,
input [31:0] count,
input clr,
output reg rst = 1'b1
);

reg [32:0] clk_count = 1'b1;


always @(negedge clk)
	if (clr) 
	begin
		clk_count <= 1'b1;
		rst <= 1'b1;
	end
	else if (clk_count > count) rst <= 1'b0;
	else 
	begin 
		clk_count <= clk_count + 1;
		rst <= 1'b1;
	end
endmodule
