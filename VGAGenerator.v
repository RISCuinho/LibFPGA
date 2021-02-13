
module VGAGenerator
#(
   parameter DEEP_COLOR = 1,
   // resoluÃ§Ã£o X * Y tamanho da memÃ³ria de exibiÃ§Ã£o
   parameter RES_X = 640,
   parameter RES_Y = 480
)
(
  input clk, // tem que ser 25.175 (25mhz aproximadamente)
  input [31:0] pixel, // pixel a ser exibido naquele clock
                      // a cada clock pula para o prÃ³ximo pixel exibivel
                      // [31-24] ignorado, [23-16]Red, [15-8]Green, [7-0]Blue
  output reg [DEEP_COLOR - 1: 0]R, 
  output reg [DEEP_COLOR - 1: 0]G, 
  output reg [DEEP_COLOR - 1: 0]B, 
  output VS, output HS,
	output reg inDisplayArea,
  output reg [9:0]COL, output reg [8:0]LINE
);

wire [9:0]local_col;
wire [8:0]local_line;
wire local_inDisplayArea;

assign local_col = COL;
assign local_line = LINE;
assign local_InDisplayArea = inDisplayArea;

VGASync #(.RES_X(RES_X), .RES_Y(RES_Y)) sync(.clk(clk), .COL(local_col), .LINE(local_line), .VS(VS), .HS(HS), .inDisplayArea(local_inDisplayArea));

always @(posedge clk)
begin
	if(VS && HS)
	begin
		R <= pixel[7:0];
		G <= pixel[15:8];
		B <= pixel[23:16];
	end 
end
endmodule

/**
 * Gera o sinal de sincronismo
 *
http://martin.hinner.info/vga/timing.html

Horizonal Timing
Horizonal Dots         640        
Vertical Scan Lines    480
Horiz. Sync Polarity   NEG
A (us)                 31.77     Scanline time
B (us)                 3.77      Sync pulse lenght 
C (us)                 1.89      Back porch
D (us)                 25.17     Active video time
E (us)                 0.94      Front porch
         ....... pixels .......
         ______________________          ________
________|        VIDEO         |________| VIDEO (next line)
    |-C-|----------D-----------|-E-|
__   ______________________________   ___________
  |_|                              |_|
  |B|
  |---------------A----------------|


Vertical Timing
Horizonal Dots         640
Vertical Scan Lines    480
Vert. Sync Polarity    NEG      
Vertical Frequency     60Hz
O (ms)                 16.68     Total frame time
P (ms)                 0.06      Sync length
Q (ms)                 1.02      Back porch
R (ms)                 15.25     Active video time
S (ms)                 0.35      Front porch
         ______________________          ________
________|        VIDEO         |________|  VIDEO (next frame)
    |-Q-|----------R-----------|-S-|
__   ______________________________   ___________
  |_|                              |_|
  |P|
  |---------------O----------------|


"VGA industry standard"
Clock frequency 25.175 MHz
Line  frequency 31469 Hz
Field frequency 59.94 Hz

One line:
  8 pixels front porch
 96 pixels horizontal sync
 40 pixels back porch
  8 pixels left border
640 pixels video
  8 pixels right border
---
800 pixels total per line  


One field:
  2 lines front porch
  2 lines vertical sync
 25 lines back porch
  8 lines top border
480 lines video
  8 lines bottom border
---
525 lines total per field
            
Sync polarity: H negative,
               V negative
Scan type: non interlaced.    
*/
module VGASync
#(
  parameter RES_X = 640,
  parameter RES_Y = 480
)
(
  input clk, 
  output reg [9:0] COL, 
  output reg [8:0] LINE,
  output VS,
  output HS,
  output reg inDisplayArea
  );

wire MAX_COL = (COL == 767); // tentando entender porque 767 (9'h2FF) 
                              // nÃ£o deveria ser 799 (800)
reg local_HS, local_VS;

always @(posedge clk)
begin: COUNT_COL
if(MAX_COL)
  COL <= 0;
else
  COL <= COL + 1;
end

always @(posedge clk)
begin: COUNT_LINE
if(MAX_COL)
    LINE <= LINE + 1;  
end

always @(posedge clk)
begin: SYNC
  local_HS <= (COL[9:4] == 6'h2D);// active for 16 clocks  - 6'h2D - 9'h168 - 360 
  local_VS <= (LINE == 500);    // active for 768 clocks - 500
end

assign HS = ~local_HS;
assign VS = ~local_VS;

always @(posedge clk)
begin: DISPLAY_AREA
if(inDisplayArea == 0)
	inDisplayArea <= (MAX_COL) && (LINE < RES_Y);
else
	inDisplayArea <= !(COL == RES_X - 1);  
end


endmodule
