`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/04/27 15:06:57
// Design Name: UART I/O example for Arty
// Module Name: lab4
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx,
  
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [1:0] S_MAIN_INIT = 0, S_MAIN_STAY = 1,
                 S_MAIN_PROMPT = 2;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
                 
// declare system variables
wire print_enable, print_done;
reg [9:0] send_counter;
reg [1:0] P, P_next;
reg [1:0] Q, Q_next;
reg [23:0] init_counter;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

localparam [2:0] S_MAIN_INIT1 = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT = 3'b010, S_MAIN_READ = 3'b011,
                 S_MAIN_TAG = 3'b100,
                 S_MAIN_COMPUTE = 3'b101, S_MAIN_SHOW = 3'b110;

wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [2:0] P1, P1_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

//Declare count the number of "the"
reg matxtag, countdone;
reg [6:0] read_data;
reg computedone;
reg [6:0] mulcnt;
reg [4:0] anscnt;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level)
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);


always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) P1 <= S_MAIN_INIT1;
  else P1 <= P1_next;
end

always @(*) begin // FSM next-state logic
  case (P1)
    S_MAIN_INIT1: // wait for SD card initialization
      if (init_finished == 1) P1_next = S_MAIN_IDLE;
      else P1_next = S_MAIN_INIT1;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P1_next = S_MAIN_WAIT;
      else P1_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      P1_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512) P1_next = S_MAIN_TAG;
      else P1_next = S_MAIN_READ;
    S_MAIN_TAG:  //look for tag
      if(countdone == 1 && matxtag == 0) P1_next = S_MAIN_WAIT;
      else if(anscnt) P1_next = S_MAIN_COMPUTE;
      else P1_next = S_MAIN_TAG;
    S_MAIN_COMPUTE:
      if(computedone) P1_next = S_MAIN_SHOW;
      else P1_next = S_MAIN_COMPUTE;
    S_MAIN_SHOW: // read byte 0 of the superblock from sram[]
      P1_next = S_MAIN_SHOW;
    default:
      P1_next = S_MAIN_INIT1;
  endcase
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P1 == S_MAIN_WAIT);
  rd_addr = blk_addr;
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;//8192
  else if(countdone == 1)
     blk_addr <= blk_addr + 1;
  else
     blk_addr <= blk_addr;
end

always @(posedge clk) begin
  if (~reset_n || countdone == 1) countdone <= 0;
  else if (P1 == S_MAIN_TAG && sd_counter == 512) countdone <= 1;
  else countdone <= countdone;
end

always @(posedge clk) begin
  if(~reset_n) computedone <= 0;
  else if(matxtag)computedone <= 1;
  else computedone <= computedone;
end


// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
//count to 512 : 1.read a block in  2.check the existence of ''the''
always @(posedge clk) begin
  if (~reset_n ||(P1 == S_MAIN_WAIT && P1_next == S_MAIN_READ) || (P1 == S_MAIN_READ && P1_next == S_MAIN_TAG))
    sd_counter <= 0;
  else if ((P1 == S_MAIN_READ && sd_valid) || (P1 == S_MAIN_TAG && P1_next == S_MAIN_TAG))
    sd_counter <= sd_counter + 1;
  else
    sd_counter <= sd_counter;
end

// FSM ouput logic: Retrieves the content of sram[] for display
always @(posedge clk) begin
  if (~reset_n) data_byte <= 8'b0;
  else if (sram_en && P1 == S_MAIN_TAG) data_byte <= data_out;
  else  data_byte <= data_byte;
end


always @(posedge clk) begin
  if(~reset_n) matxtag <= 0;
  else if(read_data == 7 && data_byte == "G") matxtag <= 1;
  else matxtag <= matxtag;
end

reg [8:0] mark;
always @(posedge clk) begin
  if(~reset_n) mark <= 0;
  else if(P1 == S_MAIN_COMPUTE) mark <= sd_counter[8:0];
  else mark <= mark;
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

always @(posedge clk) begin
  if(~reset_n) read_data <= 1;
  else if(read_data == 0 && data_byte == "M") read_data <= 1;
  else if(read_data == 1 && data_byte == "A") read_data <= 2;
  else if(read_data == 2 && data_byte == "T") read_data <= 3;
  else if(read_data == 3 && data_byte == "X") read_data <= 4;
  else if(read_data == 4 && data_byte == "_") read_data <= 5;
  else if(read_data == 5 && data_byte == "T") read_data <= 6;
  else if(read_data == 6 && data_byte == "A") read_data <= 7;
  else if(read_data == 7 && data_byte == "G") read_data <= 8;
  else if(read_data >= 8 && read_data < 75)begin
    if((data_byte <= "Z" && data_byte >= "A")||(data_byte <= "9" && data_byte >= "0"))read_data <= read_data + 1;
  end
  else if(read_data == 75) read_data <= read_data;
  else read_data <= 1;
end

reg [7:0] ele16;
always @(posedge clk) begin
if(~reset_n) ele16 <= 8'b0;
else if(read_data == 8) ele16[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 9) ele16[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele16 <= ele16;
end

reg [7:0] ele17;
always @(posedge clk) begin
if(~reset_n) ele17 <= 8'b0;
else if(read_data == 10) ele17[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 11) ele17[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele17 <= ele17;
end

reg [7:0] ele18;
always @(posedge clk) begin
if(~reset_n) ele18 <= 8'b0;
else if(read_data == 12) ele18[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 13) ele18[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele18 <= ele18;
end

reg [7:0] ele19;
always @(posedge clk) begin
if(~reset_n) ele19 <= 8'b0;
else if(read_data == 14) ele19[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 15) ele19[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele19 <= ele19;
end

reg [7:0] ele20;
always @(posedge clk) begin
if(~reset_n) ele20 <= 8'b0;
else if(read_data == 16) ele20[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 17) ele20[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele20 <= ele20;
end

reg [7:0] ele21;
always @(posedge clk) begin
if(~reset_n) ele21 <= 8'b0;
else if(read_data == 18) ele21[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 19) ele21[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele21 <= ele21;
end

reg [7:0] ele22;
always @(posedge clk) begin
if(~reset_n) ele22 <= 8'b0;
else if(read_data == 20) ele22[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 21) ele22[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele22 <= ele22;
end

reg [7:0] ele23;
always @(posedge clk) begin
if(~reset_n) ele23 <= 8'b0;
else if(read_data == 22) ele23[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 23) ele23[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele23 <= ele23;
end

reg [7:0] ele24;
always @(posedge clk) begin
if(~reset_n) ele24 <= 8'b0;
else if(read_data == 24) ele24[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 25) ele24[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele24 <= ele24;
end

reg [7:0] ele25;
always @(posedge clk) begin
if(~reset_n) ele25 <= 8'b0;
else if(read_data == 26) ele25[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 27) ele25[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele25 <= ele25;
end

reg [7:0] ele26;
always @(posedge clk) begin
if(~reset_n) ele26 <= 8'b0;
else if(read_data == 28) ele26[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 29) ele26[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele26 <= ele26;
end

reg [7:0] ele27;
always @(posedge clk) begin
if(~reset_n) ele27 <= 8'b0;
else if(read_data == 30) ele27[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 31) ele27[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele27 <= ele27;
end

reg [7:0] ele28;
always @(posedge clk) begin
if(~reset_n) ele28 <= 8'b0;
else if(read_data == 32) ele28[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 33) ele28[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele28 <= ele28;
end

reg [7:0] ele29;
always @(posedge clk) begin
if(~reset_n) ele29 <= 8'b0;
else if(read_data == 34) ele29[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 35) ele29[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele29 <= ele29;
end

reg [7:0] ele30;
always @(posedge clk) begin
if(~reset_n) ele30 <= 8'b0;
else if(read_data == 36) ele30[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 37) ele30[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele30 <= ele30;
end

reg [7:0] ele31;
always @(posedge clk) begin
if(~reset_n) ele31 <= 8'b0;
else if(read_data == 38) ele31[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 39) ele31[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele31 <= ele31;
end

reg [7:0] ele;
always @(posedge clk) begin
if(~reset_n) ele <= 8'b0;
else if(read_data == 40) ele[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 41) ele[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele <= ele;
end

reg [7:0] ele1;
always @(posedge clk) begin
if(~reset_n) ele1 <= 8'b0;
else if(read_data == 42) ele1[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 43) ele1[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele1 <= ele1;
end

reg [7:0] ele2;
always @(posedge clk) begin
if(~reset_n) ele2 <= 8'b0;
else if(read_data == 44) ele2[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 45) ele2[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele2 <= ele2;
end

reg [7:0] ele3;
always @(posedge clk) begin
if(~reset_n) ele3 <= 8'b0;
else if(read_data == 46) ele3[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 47) ele3[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele3 <= ele3;
end

reg [7:0] ele4;
always @(posedge clk) begin
if(~reset_n) ele4 <= 8'b0;
else if(read_data == 48) ele4[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 49) ele4[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele4 <= ele4;
end

reg [7:0] ele5;
always @(posedge clk) begin
if(~reset_n) ele5 <= 8'b0;
else if(read_data == 50) ele5[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 51) ele5[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele5 <= ele5;
end

reg [7:0] ele6;
always @(posedge clk) begin
if(~reset_n) ele6 <= 8'b0;
else if(read_data == 52) ele6[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 53) ele6[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele6 <= ele6;
end

reg [7:0] ele7;
always @(posedge clk) begin
if(~reset_n) ele7 <= 8'b0;
else if(read_data == 54) ele7[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 55) ele7[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele7 <= ele7;
end

reg [7:0] ele8;
always @(posedge clk) begin
if(~reset_n) ele8 <= 8'b0;
else if(read_data == 56) ele8[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 57) ele8[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele8 <= ele8;
end

reg [7:0] ele9;
always @(posedge clk) begin
if(~reset_n) ele9 <= 8'b0;
else if(read_data == 58) ele9[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 59) ele9[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele9 <= ele9;
end

reg [7:0] ele10;
always @(posedge clk) begin
if(~reset_n) ele10 <= 8'b0;
else if(read_data == 60) ele10[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 61) ele10[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele10 <= ele10;
end

reg [7:0] ele11;
always @(posedge clk) begin
if(~reset_n) ele11 <= 8'b0;
else if(read_data == 62) ele11[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 63) ele11[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele11 <= ele11;
end

reg [7:0] ele12;
always @(posedge clk) begin
if(~reset_n) ele12 <= 8'b0;
else if(read_data == 64) ele12[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 65) ele12[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele12 <= ele12;
end

reg [7:0] ele13;
always @(posedge clk) begin
if(~reset_n) ele13 <= 8'b0;
else if(read_data == 66) ele13[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 67) ele13[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele13 <= ele13;
end

reg [7:0] ele14;
always @(posedge clk) begin
if(~reset_n) ele14 <= 8'b0;
else if(read_data == 68) ele14[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 69) ele14[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele14 <= ele14;
end

reg [7:0] ele15;
always @(posedge clk) begin
if(~reset_n) ele15 <= 8'b0;
else if(read_data == 70) ele15[7:4] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else if(read_data == 71) ele15[3:0] <= (data_byte > "9")? data_byte - "7" : data_byte - "0";
else ele15 <= ele15;
end

always @(posedge clk) begin
  if(~reset_n) mulcnt <= 0;
  else if(read_data >= 71 && mulcnt <= 64) mulcnt <= mulcnt + 1;
  else if(mulcnt == 65) mulcnt <= mulcnt;
  else mulcnt <= mulcnt;
end


reg [15:0] mul, mul1, mul2, mul3, mul4, mul5, mul6, mul7, 
           mul8, mul9, mul10, mul11, mul12, mul13, mul14, mul15, 
           mul16, mul17, mul18, mul19, mul20, mul21, mul22, mul23,
           mul24, mul25, mul26, mul27, mul28, mul29, mul30, mul31,
           mul32, mul33, mul34, mul35, mul36, mul37, mul38, mul39, 
           mul40, mul41, mul42, mul43, mul44, mul45, mul46, mul47, 
           mul48, mul49, mul50, mul51, mul52, mul53, mul54, mul55, 
           mul56, mul57, mul58, mul59, mul60, mul61, mul62, mul63;

always @(posedge clk)begin
  if(~reset_n)
    mul <= 16'b0;
  else if(mulcnt == 1)
    mul <= ele * ele16;
  else 
    mul <= mul;
end

always @(posedge clk)begin
  if(~reset_n)
    mul1 <= 16'b0;
  else if(mulcnt == 2)
    mul1 <= ele * ele17;
  else 
    mul1 <= mul1;
end

always @(posedge clk)begin
  if(~reset_n)
    mul2 <= 16'b0;
  else if(mulcnt == 3)
    mul2 <= ele * ele18;
  else 
    mul2 <= mul2;
end

always @(posedge clk)begin
  if(~reset_n)
    mul3 <= 16'b0;
  else if(mulcnt == 4)
    mul3 <= ele * ele19;
  else 
    mul3 <= mul3;
end

always @(posedge clk)begin
  if(~reset_n)
    mul4 <= 16'b0;
  else if(mulcnt == 5)
    mul4 <= ele1 * ele20;
  else 
    mul4 <= mul4;
end

always @(posedge clk)begin
  if(~reset_n)
    mul5 <= 16'b0;
  else if(mulcnt == 6)
    mul5 <= ele1 * ele21;
  else 
    mul5 <= mul5;
end

always @(posedge clk)begin
  if(~reset_n)
    mul6 <= 16'b0;
  else if(mulcnt == 7)
    mul6 <= ele1 * ele22;
  else 
    mul6 <= mul6;
end

always @(posedge clk)begin
  if(~reset_n)
    mul7 <= 16'b0;
  else if(mulcnt == 8)
    mul7 <= ele1 * ele23;
  else 
    mul7 <= mul7;
end

always @(posedge clk)begin
  if(~reset_n)
    mul8 <= 16'b0;
  else if(mulcnt == 9)
    mul8 <= ele2 * ele24;
  else 
    mul8 <= mul8;
end

always @(posedge clk)begin
  if(~reset_n)
    mul9 <= 16'b0;
  else if(mulcnt == 10)
    mul9 <= ele2 * ele25;
  else 
    mul9 <= mul9;
end

always @(posedge clk)begin
  if(~reset_n)
    mul10 <= 16'b0;
  else if(mulcnt == 11)
    mul10 <= ele2 * ele26;
  else 
    mul10 <= mul10;
end

always @(posedge clk)begin
  if(~reset_n)
    mul11 <= 16'b0;
  else if(mulcnt == 12)
    mul11 <= ele2 * ele27;
  else 
    mul11 <= mul11;
end

always @(posedge clk)begin
  if(~reset_n)
    mul12 <= 16'b0;
  else if(mulcnt == 13)
    mul12 <= ele3 * ele28;
  else 
    mul12 <= mul12;
end

always @(posedge clk)begin
  if(~reset_n)
    mul13 <= 16'b0;
  else if(mulcnt == 14)
    mul13 <= ele3 * ele29;
  else 
    mul13 <= mul13;
end

always @(posedge clk)begin
  if(~reset_n)
    mul14 <= 16'b0;
  else if(mulcnt == 15)
    mul14 <= ele3 * ele30;
  else 
    mul14 <= mul14;
end

always @(posedge clk)begin
  if(~reset_n)
    mul15 <= 16'b0;
  else if(mulcnt == 16)
    mul15 <= ele3 * ele31;
  else 
    mul15 <= mul15;
end

always @(posedge clk)begin
  if(~reset_n)
    mul16 <= 16'b0;
  else if(mulcnt == 17)
    mul16 <= ele4 * ele16;
  else 
    mul16 <= mul16;
end

always @(posedge clk)begin
  if(~reset_n)
    mul17 <= 16'b0;
  else if(mulcnt == 18)
    mul17 <= ele4 * ele17;
  else 
    mul17 <= mul17;
end

always @(posedge clk)begin
  if(~reset_n)
    mul18 <= 16'b0;
  else if(mulcnt == 19)
    mul18 <= ele4 * ele18;
  else 
    mul18 <= mul18;
end

always @(posedge clk)begin
  if(~reset_n)
    mul19 <= 16'b0;
  else if(mulcnt == 20)
    mul19 <= ele4 * ele19;
  else 
    mul19 <= mul19;
end

always @(posedge clk)begin
  if(~reset_n)
    mul20 <= 16'b0;
  else if(mulcnt == 21)
    mul20 <= ele5 * ele20;
  else 
    mul20 <= mul20;
end

always @(posedge clk)begin
  if(~reset_n)
    mul21 <= 16'b0;
  else if(mulcnt == 22)
    mul21 <= ele5 * ele21;
  else 
    mul21 <= mul21;
end

always @(posedge clk)begin
  if(~reset_n)
    mul22 <= 16'b0;
  else if(mulcnt == 23)
    mul22 <= ele5 * ele22;
  else 
    mul22 <= mul22;
end

always @(posedge clk)begin
  if(~reset_n)
    mul23 <= 16'b0;
  else if(mulcnt == 24)
    mul23 <= ele5 * ele23;
  else 
    mul23 <= mul23;
end

always @(posedge clk)begin
  if(~reset_n)
    mul24 <= 16'b0;
  else if(mulcnt == 25)
    mul24 <= ele6 * ele24;
  else 
    mul24 <= mul24;
end

always @(posedge clk)begin
  if(~reset_n)
    mul25 <= 16'b0;
  else if(mulcnt == 26)
    mul25 <= ele6 * ele25;
  else 
    mul25 <= mul25;
end

always @(posedge clk)begin
  if(~reset_n)
    mul26 <= 16'b0;
  else if(mulcnt == 27)
    mul26 <= ele6 * ele26;
  else 
    mul26 <= mul26;
end

always @(posedge clk)begin
  if(~reset_n)
    mul27 <= 16'b0;
  else if(mulcnt == 28)
    mul27 <= ele6 * ele27;
  else 
    mul27 <= mul27;
end

always @(posedge clk)begin
  if(~reset_n)
    mul28 <= 16'b0;
  else if(mulcnt == 29)
    mul28 <= ele7 * ele28;
  else 
    mul28 <= mul28;
end

always @(posedge clk)begin
  if(~reset_n)
    mul29 <= 16'b0;
  else if(mulcnt == 30)
    mul29 <= ele7 * ele29;
  else 
    mul29 <= mul29;
end

always @(posedge clk)begin
  if(~reset_n)
    mul30 <= 16'b0;
  else if(mulcnt == 31)
    mul30 <= ele7 * ele30;
  else 
    mul30 <= mul30;
end

always @(posedge clk)begin
  if(~reset_n)
    mul31 <= 16'b0;
  else if(mulcnt == 32)
    mul31 <= ele7 * ele31;
  else 
    mul31 <= mul31;
end

always @(posedge clk)begin
  if(~reset_n)
    mul32 <= 16'b0;
  else if(mulcnt == 33)
    mul32 <= ele8 * ele16;
  else 
    mul32 <= mul32;
end

always @(posedge clk)begin
  if(~reset_n)
    mul33 <= 16'b0;
  else if(mulcnt == 34)
    mul33 <= ele8 * ele17;
  else 
    mul33 <= mul33;
end

always @(posedge clk)begin
  if(~reset_n)
    mul34 <= 16'b0;
  else if(mulcnt == 35)
    mul34 <= ele8 * ele18;
  else 
    mul34 <= mul34;
end

always @(posedge clk)begin
  if(~reset_n)
    mul35 <= 16'b0;
  else if(mulcnt == 36)
    mul35 <= ele8 * ele19;
  else 
    mul35 <= mul35;
end

always @(posedge clk)begin
  if(~reset_n)
    mul36 <= 16'b0;
  else if(mulcnt == 37)
    mul36 <= ele9 * ele20;
  else 
    mul36 <= mul36;
end

always @(posedge clk)begin
  if(~reset_n)
    mul37 <= 16'b0;
  else if(mulcnt == 38)
    mul37 <= ele9 * ele21;
  else 
    mul37 <= mul37;
end

always @(posedge clk)begin
  if(~reset_n)
    mul38 <= 16'b0;
  else if(mulcnt == 39)
    mul38 <= ele9 * ele22;
  else 
    mul38 <= mul38;
end

always @(posedge clk)begin
  if(~reset_n)
    mul39 <= 16'b0;
  else if(mulcnt == 40)
    mul39 <= ele9 * ele23;
  else 
    mul39 <= mul39;
end

always @(posedge clk)begin
  if(~reset_n)
    mul40 <= 16'b0;
  else if(mulcnt == 41)
    mul40 <= ele10 * ele24;
  else 
    mul40 <= mul40;
end

always @(posedge clk)begin
  if(~reset_n)
    mul41 <= 16'b0;
  else if(mulcnt == 42)
    mul41 <= ele10 * ele25;
  else 
    mul41 <= mul41;
end

always @(posedge clk)begin
  if(~reset_n)
    mul42 <= 16'b0;
  else if(mulcnt == 43)
    mul42 <= ele10 * ele26;
  else 
    mul42 <= mul42;
end

always @(posedge clk)begin
  if(~reset_n)
    mul43 <= 16'b0;
  else if(mulcnt == 44)
    mul43 <= ele10 * ele27;
  else 
    mul43 <= mul43;
end

always @(posedge clk)begin
  if(~reset_n)
    mul44 <= 16'b0;
  else if(mulcnt == 45)
    mul44 <= ele11 * ele28;
  else 
    mul44 <= mul44;
end

always @(posedge clk)begin
  if(~reset_n)
    mul45 <= 16'b0;
  else if(mulcnt == 46)
    mul45 <= ele11 * ele29;
  else 
    mul45 <= mul45;
end

always @(posedge clk)begin
  if(~reset_n)
    mul46 <= 16'b0;
  else if(mulcnt == 47)
    mul46 <= ele11 * ele30;
  else 
    mul46 <= mul46;
end

always @(posedge clk)begin
  if(~reset_n)
    mul47 <= 16'b0;
  else if(mulcnt == 48)
    mul47 <= ele11 * ele31;
  else 
    mul47 <= mul47;
end

always @(posedge clk)begin
  if(~reset_n)
    mul48 <= 16'b0;
  else if(mulcnt == 49)
    mul48 <= ele12 * ele16;
  else 
    mul48 <= mul48;
end

always @(posedge clk)begin
  if(~reset_n)
    mul49 <= 16'b0;
  else if(mulcnt == 50)
    mul49 <= ele12 * ele17;
  else 
    mul49 <= mul49;
end

always @(posedge clk)begin
  if(~reset_n)
    mul50 <= 16'b0;
  else if(mulcnt == 51)
    mul50 <= ele12 * ele18;
  else 
    mul50 <= mul50;
end

always @(posedge clk)begin
  if(~reset_n)
    mul51 <= 16'b0;
  else if(mulcnt == 52)
    mul51 <= ele12 * ele19;
  else 
    mul51 <= mul51;
end

always @(posedge clk)begin
  if(~reset_n)
    mul52 <= 16'b0;
  else if(mulcnt == 53)
    mul52 <= ele13 * ele20;
  else 
    mul52 <= mul52;
end

always @(posedge clk)begin
  if(~reset_n)
    mul53 <= 16'b0;
  else if(mulcnt == 54)
    mul53 <= ele13 * ele21;
  else 
    mul53 <= mul53;
end

always @(posedge clk)begin
  if(~reset_n)
    mul54 <= 16'b0;
  else if(mulcnt == 55)
    mul54 <= ele13 * ele22;
  else 
    mul54 <= mul54;
end

always @(posedge clk)begin
  if(~reset_n)
    mul55 <= 16'b0;
  else if(mulcnt == 56)
    mul55 <= ele13 * ele23;
  else 
    mul55 <= mul55;
end

always @(posedge clk)begin
  if(~reset_n)
    mul56 <= 16'b0;
  else if(mulcnt == 57)
    mul56 <= ele14 * ele24;
  else 
    mul56 <= mul56;
end

always @(posedge clk)begin
  if(~reset_n)
    mul57 <= 16'b0;
  else if(mulcnt == 58)
    mul57 <= ele14 * ele25;
  else 
    mul57 <= mul57;
end

always @(posedge clk)begin
  if(~reset_n)
    mul58 <= 16'b0;
  else if(mulcnt == 59)
    mul58 <= ele14 * ele26;
  else 
    mul58 <= mul58;
end

always @(posedge clk)begin
  if(~reset_n)
    mul59 <= 16'b0;
  else if(mulcnt == 60)
    mul59 <= ele14 * ele27;
  else 
    mul59 <= mul59;
end

always @(posedge clk)begin
  if(~reset_n)
    mul60 <= 16'b0;
  else if(mulcnt == 61)
    mul60 <= ele15 * ele28;
  else 
    mul60 <= mul60;
end

always @(posedge clk)begin
  if(~reset_n)
    mul61 <= 16'b0;
  else if(mulcnt == 62)
    mul61 <= ele15 * ele29;
  else 
    mul61 <= mul61;
end

always @(posedge clk)begin
  if(~reset_n)
    mul62<= 16'b0;
  else if(mulcnt == 63)
    mul62 <= ele15 * ele30;
  else 
    mul62 <= mul62;
end

always @(posedge clk)begin
  if(~reset_n)
    mul63 <= 16'b0;
  else if(mulcnt == 64)
    mul63 <= ele15 * ele31;
  else 
    mul63 <= mul63;
end



always @(posedge clk) begin
  if(~reset_n) anscnt <= 0;
  else if(mulcnt == 64) anscnt <= 1;
  else if(anscnt > 0 && anscnt != 17) anscnt <= anscnt + 1;
  else if(anscnt == 17) anscnt <= anscnt;
  else anscnt <= anscnt;
end

reg [17:0] ans, ans1, ans2, ans3, ans4, ans5, ans6, ans7, 
           ans8, ans9, ans10, ans11, ans12, ans13, ans14, ans15;
           
always @(posedge clk) begin
  if(~reset_n) ans <= 8'b0;
  else if(anscnt == 1) ans <= mul + mul4 + mul8 + mul12;
  else ans <= ans;
end

always @(posedge clk) begin
  if(~reset_n) ans1 <= 8'b0;
  else if(anscnt == 2) ans1 <= mul1 + mul5 + mul9 + mul13;
  else ans1 <= ans1;
end

always @(posedge clk) begin
  if(~reset_n) ans2 <= 8'b0;
  else if(anscnt == 3) ans2 <= mul2 + mul6 + mul10 + mul14;
  else ans2 <= ans2;
end

always @(posedge clk) begin
  if(~reset_n) ans3 <= 8'b0;
  else if(anscnt == 4) ans3 <= mul3 + mul7 + mul11 + mul15;
  else ans3 <= ans3;
end

always @(posedge clk) begin
  if(~reset_n) ans4 <= 8'b0;
  else if(anscnt == 5) ans4 <= mul16 + mul20 + mul24 + mul28;
  else ans4 <= ans4;
end

always @(posedge clk) begin
  if(~reset_n) ans5 <= 8'b0;
  else if(anscnt == 6) ans5 <= mul17 + mul21 + mul25 + mul29;
  else ans5 <= ans5;
end

always @(posedge clk) begin
  if(~reset_n) ans6 <= 8'b0;
  else if(anscnt == 7) ans6 <= mul18 + mul22 + mul26 + mul30;
  else ans6 <= ans6;
end

always @(posedge clk) begin
  if(~reset_n) ans7 <= 8'b0;
  else if(anscnt == 8) ans7 <= mul19 + mul23 + mul27 + mul31;
  else ans7 <= ans7;
end

always @(posedge clk) begin
  if(~reset_n) ans8 <= 8'b0;
  else if(anscnt == 9) ans8 <= mul32 + mul36 + mul40 + mul44;
  else ans8 <= ans8;
end

always @(posedge clk) begin
  if(~reset_n) ans9 <= 8'b0;
  else if(anscnt == 10) ans9 <= mul33 + mul37 + mul41 + mul45;
  else ans9 <= ans9;
end

always @(posedge clk) begin
  if(~reset_n) ans10 <= 8'b0;
  else if(anscnt == 11) ans10 <= mul34 + mul38 + mul42 + mul46;
  else ans10 <= ans10;
end

always @(posedge clk) begin
  if(~reset_n) ans11 <= 8'b0;
  else if(anscnt == 12) ans11 <= mul35 + mul39 + mul43 + mul47;
  else ans11 <= ans11;
end

always @(posedge clk) begin
  if(~reset_n) ans12 <= 8'b0;
  else if(anscnt == 13) ans12 <= mul48 + mul52 + mul56 + mul60;
  else ans12 <= ans12;
end

always @(posedge clk) begin
  if(~reset_n) ans13 <= 8'b0;
  else if(anscnt == 14) ans13 <= mul49 + mul53 + mul57 + mul61;
  else ans13 <= ans13;
end

always @(posedge clk) begin
  if(~reset_n) ans14 <= 8'b0;
  else if(anscnt == 15) ans14 <= mul50 + mul54 + mul58 + mul62;
  else ans14 <= ans14;
end

always @(posedge clk) begin
  if(~reset_n) ans15 <= 8'b0;
  else if(anscnt == 16) ans15 <= mul51 + mul55 + mul59 + mul63;
  else ans15 <= ans15;
end

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end else if (P1 == S_MAIN_IDLE) begin
      row_A <= "Hit BTN1 to read";
      row_B <= "data from sdcard";
  end else if (P1 == S_MAIN_READ) begin
      row_A <= "Wait for        ";
      row_B <= "counting        ";
  end else if (P1 == S_MAIN_SHOW) begin
     row_A <= "I have show the ";
     row_B <= "answer in Tera. ";
  end  
end
// End of the LCD display function
// ------------------------------------------------------------------------


// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2005 :(
//
localparam MEM_SIZE = 147;
localparam PROMPT_STR = 0;
localparam HELLO_STR = 16;
reg [7:0] data[0:MEM_SIZE-1];

initial begin
  { data[ 0], data[ 1], data[ 2], data[ 3], data[ 4], data[ 5], data[ 6], data[ 7],
    data[ 8], data[ 9], data[10], data[11], data[12], data[13], data[14], data[15],
    data[16], data[17], data[18], data[19], data[20], data[21], data[22], data[23],
    data[24], data[25], data[26], data[27], data[28], data[29], data[30], data[31],
    data[32], data[33], data[34], data[35], data[36], data[37], data[38], data[39],
    data[40], data[41], data[42], data[43], data[44], data[45], data[46], data[47],
    data[48], data[49], data[50], data[51], data[52], data[53], data[54], data[55],
    data[56], data[57], data[58], data[59], data[60], data[61], data[62], data[63],
    data[64], data[65], data[66], data[67], data[68], data[69], data[70], data[71],
    data[72], data[73], data[74], data[75], data[76], data[77], data[78], data[79],
    data[80], data[81], data[82], data[83], data[84], data[85], data[86], data[87],
    data[88], data[89], data[90], data[91], data[92], data[93], data[94], data[95],
    data[96], data[97], data[98], data[99], data[100], data[101], data[102], data[103],
    data[104], data[105], data[106], data[107], data[108], data[109], data[110], data[111],
    data[112], data[113], data[114], data[115], data[116], data[117], data[118], data[119],
    data[120], data[121], data[122], data[123], data[124], data[125], data[126], data[127],
    data[128], data[129], data[130], data[131], data[132], data[133], data[134], data[135], 
    data[136], data[137], data[138], data[139], data[140], data[141], data[142], data[143], 
    data[144], data[145], data[146]
    }
  <= { 8'h0D, 8'h0A, "The result is:", //16
       8'h0D, 8'h0A, "[      ,      ,      ,       ]",//32   48
       8'h0D, 8'h0A, "[      ,      ,      ,       ]",//32   80
       8'h0D, 8'h0A, "[      ,      ,      ,       ]",//32   112
       8'h0D, 8'h0A, "[      ,      ,      ,       ]",//32   144
       8'h0D, 8'h0A, 8'h00 };//3   147
end

reg [7:0] datacnt;

// Combinational I/O logics
assign enter_pressed = (rx_temp == 8'h0D);
assign tx_byte = data[send_counter];
assign print_done = (tx_byte == 8'h0);

/*always @(posedge clk)begin
  if(~reset_n) datacnt <= 0;
  else if(P == S_MAIN_INIT && P_next == S_MAIN_PROMPT) datacnt <= 1;
  else if(datacnt > 0 && datacnt < 148) datacnt <= datacnt + 1;
  else if(datacnt == 148) datacnt <= datacnt;
  else datacnt <= datacnt;  
end*/


// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Delay 10 us.
	   if(P1 == S_MAIN_SHOW) P_next = S_MAIN_PROMPT;
	   else P_next = S_MAIN_INIT;    
    S_MAIN_PROMPT: // Print the prompt message.
      if(print_done) P_next = S_MAIN_STAY;
      else P_next = S_MAIN_PROMPT;
    S_MAIN_STAY:
       P_next = S_MAIN_STAY;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_PROMPT && P_next == S_MAIN_PROMPT);                 

// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller to send a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics
assign transmit = (Q_next == S_UART_WAIT);

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= PROMPT_STR;
    S_MAIN_PROMPT: send_counter <= send_counter + (Q_next == S_UART_INCR);
    //default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end


always @(posedge clk) 
begin
   data[20] <= ans[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans[15:12] > 9)
     data[21] <= ans[15:12] + "7";
   else
     data[21] <= ans[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans[11: 8] > 9)
     data[22] <= ans[11: 8] + "7";
   else
     data[22] <= ans[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans[ 7: 4] > 9)
     data[23] <= ans[ 7: 4] + "7";
   else
     data[23] <= ans[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans[ 3: 0] > 9)
     data[24] <= ans[ 3: 0] + "7";
   else
     data[24] <= ans[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[27] <= ans4[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans4[15:12] > 9)
     data[28] <= ans4[15:12] + "7";
   else
     data[28] <= ans4[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans4[11: 8] > 9)
     data[29] <= ans4[11: 8] + "7";
   else
     data[29] <= ans4[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans4[ 7: 4] > 9)
     data[30] <= ans4[ 7: 4] + "7";
   else
     data[30] <= ans4[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans4[ 3: 0] > 9)
     data[31] <= ans4[ 3: 0] + "7";
   else
     data[31] <= ans4[ 3: 0] + "0";
end


always @(posedge clk) 
begin
   data[34] <= ans8[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans8[15:12] > 9)
     data[35] <= ans8[15:12] + "7";
   else
     data[35] <= ans8[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans8[11: 8] > 9)
     data[36] <= ans8[11: 8] + "7";
   else
     data[36] <= ans8[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans8[ 7: 4] > 9)
     data[37] <= ans8[ 7: 4] + "7";
   else
     data[37] <= ans8[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans8[ 3: 0] > 9)
     data[38] <= ans8[ 3: 0] + "7";
   else
     data[38] <= ans8[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[41] <= ans12[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans12[15:12] > 9)
     data[42] <= ans12[15:12] + "7";
   else
     data[42] <= ans12[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans12[11: 8] > 9)
     data[43] <= ans12[11: 8] + "7";
   else
     data[43] <= ans12[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans12[ 7: 4] > 9)
     data[44] <= ans12[ 7: 4] + "7";
   else
     data[44] <= ans12[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans12[ 3: 0] > 9)
     data[45] <= ans12[ 3: 0] + "7";
   else
     data[45] <= ans12[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[52] <= ans1[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans1[15:12] > 9)
     data[53] <= ans1[15:12] + "7";
   else
     data[53] <= ans1[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans1[11: 8] > 9)
     data[54] <= ans1[11: 8] + "7";
   else
     data[54] <= ans1[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans1[ 7: 4] > 9)
     data[55] <= ans1[ 7: 4] + "7";
   else
     data[55] <= ans1[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans1[ 3: 0] > 9)
     data[56] <= ans1[ 3: 0] + "7";
   else
     data[56] <= ans1[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[59] <= ans5[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans5[15:12] > 9)
     data[60] <= ans5[15:12] + "7";
   else
     data[60] <= ans5[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans5[11: 8] > 9)
     data[61] <= ans5[11: 8] + "7";
   else
     data[61] <= ans5[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans5[ 7: 4] > 9)
     data[62] <= ans5[ 7: 4] + "7";
   else
     data[62] <= ans5[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans5[ 3: 0] > 9)
     data[63] <= ans5[ 3: 0] + "7";
   else
     data[63] <= ans5[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[66] <= ans9[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans9[15:12] > 9)
     data[67] <= ans9[15:12] + "7";
   else
     data[67] <= ans9[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans9[11: 8] > 9)
     data[68] <= ans9[11: 8] + "7";
   else
     data[68] <= ans9[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans9[ 7: 4] > 9)
     data[69] <= ans9[ 7: 4] + "7";
   else
     data[69] <= ans9[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans9[ 3: 0] > 9)
     data[70] <= ans9[ 3: 0] + "7";
   else
     data[70] <= ans9[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[73] <= ans13[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans13[15:12] > 9)
     data[74] <= ans13[15:12] + "7";
   else
     data[74] <= ans13[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans13[11: 8] > 9)
     data[75] <= ans13[11: 8] + "7";
   else
     data[75] <= ans13[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans13[ 7: 4] > 9)
     data[76] <= ans13[ 7: 4] + "7";
   else
     data[76] <= ans13[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans13[ 3: 0] > 9)
     data[77] <= ans13[ 3: 0] + "7";
   else
     data[77] <= ans13[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[84] <= ans2[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans2[15:12] > 9)
     data[85] <= ans2[15:12] + "7";
   else
     data[85] <= ans2[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans2[11: 8] > 9)
     data[86] <= ans2[11: 8] + "7";
   else
     data[86] <= ans2[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans2[ 7: 4] > 9)
     data[87] <= ans2[ 7: 4] + "7";
   else
     data[87] <= ans2[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans2[ 3: 0] > 9)
     data[88] <= ans2[ 3: 0] + "7";
   else
     data[88] <= ans2[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[91] <= ans6[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans6[15:12] > 9)
     data[92] <= ans6[15:12] + "7";
   else
     data[92] <= ans6[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans6[11: 8] > 9)
     data[93] <= ans6[11: 8] + "7";
   else
     data[93] <= ans6[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans6[ 7: 4] > 9)
     data[94] <= ans6[ 7: 4] + "7";
   else
     data[94] <= ans6[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans6[ 3: 0] > 9)
     data[95] <= ans6[ 3: 0] + "7";
   else
     data[95] <= ans6[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[98] <= ans10[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans10[15:12] > 9)
     data[99] <= ans10[15:12] + "7";
   else
     data[99] <= ans10[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans10[11: 8] > 9)
     data[100] <= ans10[11: 8] + "7";
   else
     data[100] <= ans10[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans10[ 7: 4] > 9)
     data[101] <= ans10[ 7: 4] + "7";
   else
     data[101] <= ans10[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans10[ 3: 0] > 9)
     data[102] <= ans10[ 3: 0] + "7";
   else
     data[102] <= ans10[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[105] <= ans14[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans14[15:12] > 9)
     data[106] <= ans14[15:12] + "7";
   else
     data[106] <= ans14[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans14[11: 8] > 9)
     data[107] <= ans14[11: 8] + "7";
   else
     data[107] <= ans14[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans14[ 7: 4] > 9)
     data[108] <= ans14[ 7: 4] + "7";
   else
     data[108] <= ans14[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans14[ 3: 0] > 9)
     data[109] <= ans14[ 3: 0] + "7";
   else
     data[109] <= ans14[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[116] <= ans3[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans3[15:12] > 9)
     data[117] <= ans3[15:12] + "7";
   else
     data[117] <= ans3[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans3[11: 8] > 9)
     data[118] <= ans3[11: 8] + "7";
   else
     data[118] <= ans3[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans3[ 7: 4] > 9)
     data[119] <= ans3[ 7: 4] + "7";
   else
     data[119] <= ans3[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans3[ 3: 0] > 9)
     data[120] <= ans3[ 3: 0] + "7";
   else
     data[120] <= ans3[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[123] <= ans7[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans7[15:12] > 9)
     data[124] <= ans7[15:12] + "7";
   else
     data[124] <= ans7[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans7[11: 8] > 9)
     data[125] <= ans7[11: 8] + "7";
   else
     data[125] <= ans7[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans7[ 7: 4] > 9)
     data[126] <= ans7[ 7: 4] + "7";
   else
     data[126] <= ans7[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans7[ 3: 0] > 9)
     data[127] <= ans7[ 3: 0] + "7";
   else
     data[127] <= ans7[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[130] <= ans11[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans11[15:12] > 9)
     data[131] <= ans11[15:12] + "7";
   else
     data[131] <= ans11[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans11[11: 8] > 9)
     data[132] <= ans11[11: 8] + "7";
   else
     data[132] <= ans11[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans11[ 7: 4] > 9)
     data[133] <= ans11[ 7: 4] + "7";
   else
     data[133] <= ans11[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans11[ 3: 0] > 9)
     data[134] <= ans11[ 3: 0] + "7";
   else
     data[134] <= ans11[ 3: 0] + "0";
end

always @(posedge clk) 
begin
   data[137] <= ans15[17:16] + "0";
end

always @(posedge clk) 
begin
   if(ans15[15:12] > 9)
     data[138] <= ans15[15:12] + "7";
   else
     data[138] <= ans15[15:12] + "0";
end

always @(posedge clk) 
begin
   if(ans15[11: 8] > 9)
     data[139] <= ans15[11: 8] + "7";
   else
     data[139] <= ans15[11: 8] + "0";
end

always @(posedge clk) 
begin
   if(ans15[ 7: 4] > 9)
     data[140] <= ans15[ 7: 4] + "7";
   else
     data[140] <= ans15[ 7: 4] + "0";
end

always @(posedge clk) 
begin
   if(ans15[ 3: 0] > 9)
     data[141] <= ans15[ 3: 0] + "7";
   else
     data[141] <= ans15[ 3: 0] + "0";
end



endmodule
