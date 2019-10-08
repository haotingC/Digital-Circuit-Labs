`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/12/06 20:44:08
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab9(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_SHOW = 3'b010, S_MAIN_CONT = 3'b011,
                 S_MAIN_WAIT = 3'b100, S_MAIN_PRINT = 3'b101;
                 

// declare system variables
wire [1:0]        btn_level, btn_pressed;
reg  [1:0]        prev_btn_level;
reg  [2:0]        P, P_next;
reg  [11:0]       sample_addr;
reg  signed [7:0] sample_data;
wire [7:0]        abs_data;

reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;

reg [10:0] i;

assign usr_led = P;

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
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores an 1024+64 8-bit signed data samples.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = i-1;
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

reg cont;


always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
      P_next = S_MAIN_READ;
    S_MAIN_READ: // fetch the sample from the SRAM
      P_next = S_MAIN_SHOW;
    S_MAIN_SHOW:
      if(i < 1088) P_next = S_MAIN_ADDR;
      else P_next = S_MAIN_CONT;
    S_MAIN_CONT:
      if(cont == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_CONT;
    S_MAIN_WAIT: // wait for a button click
      if (btn_pressed == 1) P_next = S_MAIN_PRINT;
      else P_next = S_MAIN_WAIT;
    S_MAIN_PRINT:
      P_next = S_MAIN_PRINT;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display

// End of the main controller
// ------------------------------------------------------------------------
reg signed [7:0] f[0:1023];
reg signed [7:0] g[0:  63];

reg [9:0] x;
reg [6:0] k;
reg signed [23:0] sum, max;
wire signed [23:0] print;
reg [9:0] maxpos;

always @(posedge clk) begin
  if (~reset_n)
    i <= 0;
  else if (P == S_MAIN_ADDR)
    i <= i + 1;
end

always @(posedge clk) begin
  if (P == S_MAIN_SHOW && i <= 1024) begin
    f[i - 1] <=  data_out[7:0];
  end
end

always @(posedge clk) begin
  if (P == S_MAIN_SHOW && i > 1024 && i <= 1088) begin
    g[i - 1025] <=  data_out[7:0];
  end
end


always @(posedge clk) begin
  if(~reset_n && P != S_MAIN_CONT)
    x <= 0;
  else if(x != 959 && k == 64 && x != 960)
    x <= x + 1;
  else if(x == 959 && k == 64)
    x <= 960;
  else
    x <= x;
end

always @(posedge clk) begin
  if(~reset_n)
    cont <= 0;
  else if(x == 960)
    cont <= 1;
  else 
    cont <= cont;
end
      
always @(posedge clk) begin
  if(~reset_n && P != S_MAIN_CONT)
    k <= 0;
  else if(k == 64)
    k <= 0;
  else 
    k <= k + 1;      
end

always @(posedge clk) begin
  if(~reset_n || k == 64)
    sum <= 0;
  else if(P == S_MAIN_CONT)
    sum <= sum + f[k+x] * g[k];
end

assign print = (max < 0)? -max : max;

always @(posedge clk)begin
  if(~reset_n) begin
    max = 0;
    maxpos = 0;
  end
  else if(k == 64) begin
    if(sum > max)begin
      max = sum;
      maxpos= x;
    end
    else begin
      max = max;
      maxpos = maxpos;
    end
  end
end
// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Max value       ";//01C44D
  end
  else if (P == S_MAIN_WAIT) begin
    row_A <= "Press BTN0 to do";
  end
  else if (P == S_MAIN_PRINT) begin
    row_A <= "Max value       ";//01C44D
    row_A[47:40] <= ((print[23:20] > 9)? "7" : "0") + print[23:20];
    row_A[39:32] <= ((print[19:16] > 9)? "7" : "0") + print[19:16];
    row_A[31:24] <= ((print[15:12] > 9)? "7" : "0") + print[15:12];
    row_A[23:16] <= ((print[11:08] > 9)? "7" : "0") + print[11:08];
    row_A[15: 8] <= ((print[07:04] > 9)? "7" : "0") + print[07:04];
    row_A[ 7: 0] <= ((print[03:00] > 9)? "7" : "0") + print[03:00];
  end
end



always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "Max location    ";//2E0
  end
  else if (P == S_MAIN_WAIT) begin
    row_B <= "x-correlation...";
  end
  else if (P == S_MAIN_PRINT) begin
    row_B <= "Max location    ";//2E0
    row_B[23:16] <= ((maxpos[9:8] > 9)? "7" : "0") + maxpos[9:8];
    row_B[15: 8] <= ((maxpos[7:4] > 9)? "7" : "0") + maxpos[7:4];
    row_B[ 7: 0] <= ((maxpos[3:0] > 9)? "7" : "0") + maxpos[3:0];
  end
end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
/*always @(posedge clk) begin
  if (~reset_n)
    sample_addr <= 12'h000;
  else if (P_next == S_MAIN_ADDR)
    sample_addr <= (sample_addr < 2048)? sample_addr + 1 : sample_addr;
end*/
// End of the user's button control.
// ------------------------------------------------------------------------

endmodule
