module MyPLL #(parameter fator = 31)
				  (input i_clock, output o_clock);

reg [fator-1:0] count = 0;
assign o_clock = count[fator-1];

always @(posedge i_clock) 
begin
	count <= count + 1'b1; 
end
				  
endmodule