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

module lab4(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_PROMPT1 = 1, S_MAIN_WAIT_KEYIN1 = 2,
                 S_MAIN_PROMPT2 = 3, S_MAIN_WAIT_KEYIN2 = 4, S_MAIN_COMPUTE = 5,
                 S_MAIN_REPLY = 6;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;

// declare text message parameters
localparam MSG1_SIZE = 35;
localparam MSG2_SIZE = 36;
localparam MSG3_SIZE = 23;
localparam MEM_SIZE = 128;
localparam PROMPT1_STR = 0;
localparam PROMPT2_STR = MSG1_SIZE;
localparam REPLY_STR = MSG1_SIZE+MSG2_SIZE;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz

// declare system variables
wire enter_pressed;
wire print_enable, print_done;
reg  [$clog2(MEM_SIZE):0] send_counter;
reg  [2:0] P, P_next;
reg  [1:0] Q, Q_next;
reg  [$clog2(INIT_DELAY):0] init_counter;

reg  [7:0] data[0:MEM_SIZE-1];
reg  [0:MSG1_SIZE*8-1] msg1 = { "\015\012Enter the first decimal number: ", 8'h00 };
reg  [0:MSG2_SIZE*8-1] msg2 = { "\015\012Enter the second decimal number: ", 8'h00 };
reg  [0:MSG3_SIZE*8-1] msg3 = { "\015\012The GCD is: 0x0000\015\012", 8'h00 };

reg  [15:0] num_reg;  // The keyin number register
reg  [2:0]  key_cnt;
reg  [15:0] num1, num2, tmp1, tmp2;
reg  [15:0] gcd;
reg  gcd_done;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart0(
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

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//
integer idx;

always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < MSG1_SIZE; idx = idx + 1) data[idx] = msg1[idx*8 +: 8];
    for (idx = 0; idx < MSG2_SIZE; idx = idx + 1) data[idx+MSG1_SIZE] = msg2[idx*8 +: 8];
    for (idx = 0; idx < MSG3_SIZE; idx = idx + 1) data[idx+MSG1_SIZE+MSG2_SIZE] = msg3[idx*8 +: 8];
  end
  else if (P == S_MAIN_COMPUTE && gcd_done) begin
    data[REPLY_STR+16] <= ((gcd[15:12] > 9)? "7" : "0") + gcd[15:12];
    data[REPLY_STR+17] <= ((gcd[11: 8] > 9)? "7" : "0") + gcd[11: 8];
    data[REPLY_STR+18] <= ((gcd[ 7: 4] > 9)? "7" : "0") + gcd[ 7: 4];
    data[REPLY_STR+19] <= ((gcd[ 3: 0] > 9)? "7" : "0") + gcd[ 3: 0];
  end
end

// Combinational I/O logics
assign usr_led = usr_btn;
assign enter_pressed = (rx_temp == 8'h0D);

// ------------------------------------------------------------------------
// Main FSM that reads the UART input, compute GCD, and
// print the output of the GCD.
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
      if (init_counter < INIT_DELAY) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_PROMPT1;
    S_MAIN_PROMPT1: // Print the prompt message #1.
      if (print_done) P_next = S_MAIN_WAIT_KEYIN1;
      else P_next = S_MAIN_PROMPT1;
    S_MAIN_WAIT_KEYIN1: // wait for <Enter> key.
      if (enter_pressed) P_next = S_MAIN_PROMPT2;
      else P_next = S_MAIN_WAIT_KEYIN1;
    S_MAIN_PROMPT2: // Print the prompt message #2.
        if (print_done) P_next = S_MAIN_WAIT_KEYIN2;
        else P_next = S_MAIN_PROMPT2;
    S_MAIN_WAIT_KEYIN2: // wait for <Enter> key.
        if (enter_pressed) P_next = S_MAIN_COMPUTE;
        else P_next = S_MAIN_WAIT_KEYIN2;
    S_MAIN_COMPUTE: // compute the GCD.
        if (gcd_done) P_next = S_MAIN_REPLY;
        else P_next = S_MAIN_COMPUTE;
    S_MAIN_REPLY: // Print the reply message.
      if (print_done) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_REPLY;
    default:
      P_next = S_MAIN_INIT;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable = (P == S_MAIN_INIT && P_next == S_MAIN_PROMPT1) ||
                      (P == S_MAIN_WAIT_KEYIN1 && P_next == S_MAIN_PROMPT2) ||
                      (P == S_MAIN_COMPUTE && P_next == S_MAIN_REPLY);
assign print_done = (tx_byte == 8'h00);

// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end
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
      if (tx_byte == 8'h00) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics
assign transmit = (Q_next == S_UART_WAIT ||
                  (P == S_MAIN_WAIT_KEYIN1 && received) ||
                  (P == S_MAIN_WAIT_KEYIN2 && received) ||
                  print_enable);
assign tx_byte = (P == S_MAIN_WAIT_KEYIN1 || P == S_MAIN_WAIT_KEYIN2) && received?
                  rx_byte : data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= PROMPT1_STR;
    S_MAIN_WAIT_KEYIN1: send_counter <= PROMPT2_STR;
    S_MAIN_WAIT_KEYIN2: send_counter <= REPLY_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
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

always @(posedge clk) begin
  if (~reset_n || (P == S_MAIN_INIT || P == S_MAIN_PROMPT2)) key_cnt <= 0;
  else if (received && (rx_byte > 8'h2F) && (rx_byte < 8'h3A))
    key_cnt <= key_cnt + (key_cnt != 5);
end

always @(posedge clk)begin
  if (~reset_n) num_reg <= 0;
  else if (P == S_MAIN_INIT || P == S_MAIN_PROMPT2) num_reg <= 0;
  else if (received && (rx_byte > 8'h2F) && (rx_byte < 8'h3A) && key_cnt < 5)
	num_reg <= (num_reg * 10) + (rx_byte - 48);
end
// End of the UART input logic
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following logic computes the GCD of num1 and num2.
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_INIT) begin
    num1 <= 16'h0;
    num2 <= 16'h0;
    gcd  <= 16'h0;
    gcd_done <= 0;
  end else if (P == S_MAIN_WAIT_KEYIN1 && enter_pressed) begin
    num1 <= num_reg;
    tmp1 <= num_reg;
  end else if (P == S_MAIN_WAIT_KEYIN2 && enter_pressed) begin
    num2 <= num_reg;
    tmp2 <= num_reg;
  end else if (P == S_MAIN_COMPUTE && gcd_done == 0) begin
    if (tmp1 > tmp2)
      tmp1 <= tmp1 - tmp2;
    else if (tmp1 < tmp2)
      tmp2 <= tmp2 - tmp1;
    else begin
      gcd <= tmp1;
      gcd_done <= 1;
    end
  end
end
// End of the GCD computation logic
// ------------------------------------------------------------------------

endmodule
