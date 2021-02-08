# FPGA-MyLIB

Minha biblioteca de módulos útil a qualquer projeto com FPGA, de PLL, Gerador de números pseudo aleatórios, controladores externos, entre outros.


## LFSR

Um gerador parametrizavel de números pseudoelatórios baseado em um Linear Feedback Shift Register, futuramente este módulo terá seu nome trocado para LFSR_Random ou algo mais relacionado a números randômicos.

Este gerador foi baseado no tutorial: //https://www.fpga4fun.com/Counters3.html

#### Parametros

* SIZE valor padrão 8 bits, permite mudar o tamanho do word usado para geração de números.
 
#### Sinais

* clk, clock a ser usado no gerador, use um clock diferente do clock padrão para que a geração funciona de forma assincrona ao restante do circuito;
* rst, reseta o gerador de números rertornando a contagem ao seed;
* tap, indica os bits que serão conectados a lógica XOR para geração de números aleatórios, veja que o primeiro e ultimo bit são descartados;
* seed, semente para iniciar a geração de números aleatórios, a cada reset retorna a contagem a este número;
* LFSR retorna o número gerado a quantidade de bits na word é definida pelo size.

## MyPLL

Um módulo que permite gerar clocks fracionados com base no clock master, também parametrizável o parametro `#fator` representa o potênciação que irá fraconar o clock, sendo **2^fator**.

## Autoreset

Um gerador de pulso de reset, similar a um WatchDog, 

* clk, Clock para sincronização do circuito, use o clock principal, matenha sincronizado ao hardware principal;
* clr, Reseta a contagem de ticks;
* count, número de ticks a serem contado valor máximo 2^31
* rst, Sinal de reset gerado, logica inversa, portando sempre 1'b1, quando gera o pulso de reset vai a 1'b0;
