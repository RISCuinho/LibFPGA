// https://www.fpga4fun.com/TextLCDmodule.html
// https://www.cin.ufpe.br/~svc/ese/Manuais%20e%20Datasheets/LCD%2016X2.pdf
// https://web.archive.org/web/20130615003407/http://www.geocities.com/dinceraydin/lcd/commands.htm
//      INSTRUCTION                                         | Dec | Hex 
// Clear Screen	                                          |   1 |  01
// Home (move cursor to top/left character position)	      |   2 |  02
// Blank the display (without clearing)	                  |   8 |  08
// Make cursor invisible	                                 |  12 |  0C
// Restore the display (with cursor hidden)	               |  12 |  0C
// Turn on visible underline cursor	                        |  14 |  0E
// Turn on visible blinking-block cursor	                  |  15 |  0F
// Move cursor one character left	                        |  16 |  10
// Move cursor one character right	                        |  20 |  14
// Scroll display one character left (all lines)	         |  24 |  18
// Scroll display one character right (all lines)	         |  28 |  1E
// Function set (4-bit interface, 1 line, 5*7 Pixels)	      |  32 |  20 
// Function set (4-bit interface, 2 lines, 5*7 Pixels)	   |  40 |  28 
// Function set (8-bit interface, 1 line, 5*7 Pixels)       |  48 |  30 
// Function set (8-bit interface, 2 lines, 5*7 Pixels)      |  56 |  38 
// Entry mode set	
// Set cursor position (DDRAM address)                      | 128 + addr | 80+ addr
// Set pointer in character-generator RAM (CG RAM address)	|  64 + addr | 40+ addr
// -----------------
// entry mode set command
// * h04 - Decrement Address - Display Shift off 
// * h05 - Decrement Address - Display Shift on
// * h06 - Increment Address - Display Shift off
// * h07 - Increment Address - Display Shift on
// https://web.archive.org/web/20091028161528/http://www.geocities.com/dinceraydin/djlcdsim/djlcdsim.html
module LCDControler(
   // clock de 25mhz para o algoritmo funcionar
   input clk,
   // reseta o display
   // sempre 1'b1, quando muda para 1'b0 no clock reseta.
   // leva o tempo somado de todas as instrução de reset
   // h01, h18, h08, h06  
   input rst,
   // Dado a ser exibido, pode ser comando também
   // Se enviar 00 entra no modo de envio de caracteres a serem exibidos, 
   // se enviar mais caracteres que o display pode exibir, ele sobreescreve
   // ou seja ele funciona com um buffer ring, vai escrevendo até o fim do display
   // e continua no inicio. 
   // posso mudar tal comportamento no futuro por um comando especial que faz um tipo de scrool.
   // Se enviar 00 de novo volta ao modo comando de novo
   // no modo comando repassa o comando para o lcd, conforme a tabela acima.
   // o dado deve ser mantido no barramento até BUSY volte voltar a 0 
   input [7:0] DATA, 
   // Instrução/Dado pronto, deve ser mantido 1 até que Busy volte a 0
   input DATA_READY,
   // Indica que o controlador ou o lcd está ocupado, típicamente igual a LCD_E
   output BUSY,
   // Portas de controle do LCD
   output LCD_RS, 
   output reg LCD_RW          = 1'b0, 
   output reg LCD_E           = 1'b0,
   inout [3:0] LCD_DataBus_0,
   inout [7:4] LCD_DataBus_1
);
/*
   localparam fsmStarting     = 0; // antes do reset
   localparam fsmStarted      = 1; // depois do reset
   localparam fsmInstruction  = 2; // aguardando instrução
   localparam fsmBusy         = 3; // ocupada com a instrução
   localparam fsmData         = 4; // aguardando dados
   localparam fsmDataBusy     = 5; // processando dados
*/

   integer LCDCMDtime [0:11];
   initial begin
      $readmemh("lcd_cmd_time.mem", LCDCMDtime);
   end

   wire localRst  = ~rst;

   wire receivedEscape   = DATA_READY & (DATA === 8'h00);
   wire receivedData     = DATA_READY & (DATA !== 8'h00);
   wire receivedForceCmd = DATA_READY & (DATA === 8'hFF);

   // Inverte o estado do modo comando a cada novo receivedEscape no clock
   // se receber 
   reg modeCommand = 1'b0;
   always @(negedge clk) begin
      modeCommand = receivedSWReset || (receivedEscape && !modeCommand);
   end

   // contagem de clock para gerar timing de 240ns
   reg [3:0] countBusy = 0;
   always @(negedge clk) 
   begin
      if(!localRst && (receivedData | (countBusy!=0))) 
      begin
         countBusy = countBusy + 1;
         if(countBusy > 7) countBusy = 0;
      end
   end

   // activate LCD_E for 6 clocks, so at 25MHz, that's 6x40ns=240ns
   always @(negedge clk)
   begin
      if(!localRst && !LCD_E)
         LCD_E <= receivedData;
      else
         LCD_E <= (countBusy != 6);
   end

//   wire localBusy = (countBusy != 0);
   assign { LCD_DataBus_1, LCD_DataBus_0} = receivedData ? {DATA[7:4], DATA[3:0]} : 8'bz;
   assign LCD_RS = ~modeCommand;
   assign BUSY = (countBusy != 0);

endmodule
