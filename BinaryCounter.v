/*
 The CB*CLED component naming convention is
  - Counter  
  - Binary                  
  - 4/2-bit
  - C (asynchronous reset/Clear)   
  - Load        
  - E (chip Enable)     
  - D (up/Down)

  https://www.vicilogic.com/vicilearn/run_step/?c_id=22&c_pos=286
*/
module BinaryCounter #(
   parameter WIDTH = 4
) (
   input                   clk, rst,
   output reg [WIDTH-1:0]  loadData, counter,
   input                   E, D, load,
   output reg              tc, ceo
);

   always @(posedge rst) begin
      counter <= {WIDTH{1'b0}};
   end

   always @(posedge clk) begin
      if(!rst && E && !load)
      begin
        counter <= D ? counter + 1 : counter - 1;
        tc <= (D && counter == {WIDTH{1'b1}}) || (!D && counter == {WIDTH{1'b0}});
        ceo <= tc && E;
      end
      else if(!rst && load)
         counter <= loadData;      
         
   end
endmodule
