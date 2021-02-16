
module VGAGenerator
#(
  parameter INVERTED_SYNC   = 1,
  parameter C_SYNC_ON_GREEN = 1,
  parameter DEEP_COLOR      = 1,
  // resoluÃƒÂ§ÃƒÂ£o X * Y * 32bits tamanho da memÃƒÂ³ria de exibiÃƒÂ§ÃƒÂ£o
  parameter RES_X           = 640,
  parameter RES_Y           = 480
)
(
  input clk, // tem que ser 25.175 (25mhz aproximadamente)
  input [31:0] pixel, // pixel a ser exibido naquele clock
                      // a cada clock pula para o prÃƒÂ³ximo pixel exibivel
                      // [31-24] ignorado, [23-16]Red, [15-8]Green, [7-0]Blue
                      // para saber qual pixel a ser obtido usar COL, LINE e inDisplayArea
  output reg [DEEP_COLOR - 1: 0]R = {DEEP_COLOR{1'b0}}, 
  output reg [DEEP_COLOR - 1: 0]G = {DEEP_COLOR{1'b0}}, 
  output reg [DEEP_COLOR - 1: 0]B = {DEEP_COLOR{1'b0}}, 
  output VS, output HS,
  output [9:0]COL, output [9:0]LINE,
  output inDisplayArea
);

wire local_HS;
wire local_VS;

// Gera os sinais de sincronismo
VGASync #(.RES_X(RES_X), .RES_Y(RES_Y)) sync(.clk(clk), 
													.COL(COL), .LINE(LINE), 
													.VS(local_VS), .HS(local_HS), 
													.inDisplayArea(inDisplayArea));

assign HS = INVERTED_SYNC? ~local_HS : local_HS;
assign VS = INVERTED_SYNC? ~local_VS : local_HS;

// mapea o byte a sua respectiva cor, confrome a profundida de cores (DEEP_COLOR)
always @(posedge clk)
begin: RGB_GENERATOR
	if(inDisplayArea)
	begin
    // ainda a ser implementado
		R <= pixel[7:0];
    if(C_SYNC_ON_GREEN)
    begin
      // aqui ele deve fazer um xor com VS e HS (C) e G
      // só que G pode estar dividido em diversos pinos normalmente 3
      // com isso pode ser melhor fazer um circuito externo como o proposto no link:
      // https://www.raphnet.net/electronique/sync-on-green/sync-on-green_en.php 
      // link sugerido por @darklive
      //          100 uF
      //           ! !
      // Green ----! !---------------------------------
      //          -! !+                                !
      //                                               !
      //                                     680E      !
      //                      BC548                    !
      // HSync -------------      __---------/\/\------o---------  CSync on Green
      //                     \     /!
      //                      \   /
      //                    ---------
      //                        !
      //            1k          !
      // VSync ----/\/\----------
        
      G <= pixel[15:8];
    end
    else
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
)(
  input clk, 
  output reg [9:0] COL = 10'b0, 
  output reg [9:0] LINE = 9'b0,
  output reg inDisplayArea = 1'b0,
  output reg VS = 1'b0,
  output reg HS = 1'b0
  );

localparam SIZE_HS = 96;
localparam FRONT_COL = 8 + 8;
localparam BACK_COL = 40 + 8;
localparam SIZE_COL = FRONT_COL + RES_X + SIZE_HS + BACK_COL;
// 640 pixels video
//  8 pixels left border
//  8 pixels front porch
// 96 pixels horizontal sync
// 40 pixels back porch
//  8 pixels right border
//===============================
// 800 pixels 
localparam SIZE_VS = 2;
localparam FRONT_LINE = 2 + 8;
localparam BACK_LINE = 25 + 8;
localparam SIZE_LINE = FRONT_LINE + RES_Y + SIZE_VS + BACK_LINE;
//  8 lines top border
//  2 lines front porch
//  2 lines vertical sync
// 25 lines back porch
//480 lines video
//  8 lines bottom border
//---
//525 lines total per field

initial begin
  $display("Iniciado VGA Sync Generator! %T", $time);
  $display("VGAGenerator Sync: LIMIT_MAX_COL: %D, Limit Max Line: %D, Size HS: %D, Size VS: %D", SIZE_COL, SIZE_LINE, SIZE_HS, SIZE_VS);
  $display("VGAGenerator Sync: Col: Front Porch %D, Back Porch, %D", FRONT_COL, BACK_COL);
  $display("VGAGenerator Sync: Line: Front Porch %D, Back Porch, %D", FRONT_LINE, BACK_LINE);
  //$monitor("VGAGenerator Sync: Col: %D, Limit Front: %D, Limit Back: %D, Line: %D, Limit Front: %D, Limit Back: %D", COL, SIZE_COL  - SIZE_HS, SIZE_COL, LINE, SIZE_LINE - SIZE_VS, SIZE_LINE);

//  $monitor("VGAGenerator Sync: HS: %D, VS: %D", HS, VS);
//  $monitor("Line: %D, HS: %D, VS: %D", LINE, HS, VS);
  //$stop();
end

wire MAX_COL  = (COL  == SIZE_COL);
wire MAX_LINE = (LINE == SIZE_LINE);

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
  if(MAX_LINE)
      LINE <= 0;  
end

always @(posedge clk)
begin: SYNC
  HS <= (COL  > (SIZE_COL  - SIZE_HS)) && (COL  <  SIZE_COL); 
  VS <= (LINE > (SIZE_LINE - SIZE_VS)) && (LINE <  SIZE_LINE);    
end

always @(posedge clk)
begin: DISPLAY_AREA
	inDisplayArea <= (COL  > FRONT_COL)  && (COL  < SIZE_COL  - SIZE_HS - BACK_COL)
                && (LINE > FRONT_LINE) && (LINE < SIZE_LINE - SIZE_VS - BACK_LINE);  
end


endmodule
