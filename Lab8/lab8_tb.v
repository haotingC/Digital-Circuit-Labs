`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/10 16:44:56
// Design Name: 
// Module Name: lab8_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab8_tb();
reg clk;
reg reset_n;/*
reg [7:0] A, B;
reg [31:0] r[ 0:63];
reg [31:0] k[ 0:63];
reg [31:0] g[ 0:63];
reg [63: 0] initial_msg;
reg [ 3: 0] initial_len;
reg [127:0] hash;
reg [ 7: 0] msg [0:63];
reg [ 7: 0] p;
reg [31: 0] w;
reg [63: 0] bits_len;
localparam PAD_LEN = 56;
reg [ 5: 0] cnt;
reg [31: 0] a, b, c, d;
reg leftrotate;
reg set_done, count_done, pare;
reg [2:0] P, P_next;

wire [31: 0] h0, h1, h2, h3;    */

reg usr_btn;
wire LCD_RS;
wire LCD_RW;
wire LCD_E;
wire LCD_D;
wire usr_led;

   
    
lab8 utt(
  .clk(clk),
  .reset_n(reset_n),
  .usr_btn(usr_btn),
  .usr_led(usr_led),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_E(LCD_E),
  .LCD_D(LCD_D)
);/*
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
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);*/
    
    initial begin
      clk = 1;
      reset_n = 0;
      #20
      reset_n = 1;
    end
    
    always 
      #5 clk = !clk;

endmodule
