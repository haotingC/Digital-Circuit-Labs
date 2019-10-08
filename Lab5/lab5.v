`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/10/16 14:21:33
// Design Name: 
// Module Name: lab5
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz 
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


module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = {2'b11,Q};

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.

parameter RANGE = 1024;
parameter Q_OUTER = 0, Q_INNER = 1, Q_COMPLETE = 2, Q_STORE = 3;
reg prime_flag[0:RANGE-1];
reg [10:0]prime_counter;
reg [10:0]clean_idx;
reg [9:0]prime_tmp;
reg [1:0]Q,Q_NEXT;
reg [27:0]delay_cnt;
reg [7:0]display_idx;
reg [7:0]data[0:5];
reg reverse_flag;
reg [9:0]prime_table[0:172];
reg [7:0]prime_num;
wire [7:0]prime_num_tmp;
integer i;



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
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
  end else if (Q == Q_COMPLETE && delay_cnt == 70000000 && !reverse_flag) begin
    row_A <= row_B;
    row_B <= {"Prime #",data[0],data[1]," is ",data[2],data[3],data[4]};
  end else if (Q == Q_COMPLETE && delay_cnt == 70000000 && reverse_flag) begin
    row_A <= {"Prime #",data[0],data[1]," is ",data[2],data[3],data[4]};
    row_B <= row_A;
  end
end

//lab5 FSM
always@(posedge clk)begin
	if(~reset_n)
		Q <= Q_OUTER;
	else
		Q <= Q_NEXT;
end

always@(*)begin
	case(Q)
		Q_OUTER: //the first for loop
			if(prime_counter == RANGE-1) Q_NEXT = Q_STORE;
			else if(prime_flag[prime_counter])  Q_NEXT = Q_INNER;
			else						   Q_NEXT = Q_OUTER;
		Q_INNER: //the second for loop
			if(clean_idx+prime_tmp > RANGE-1)Q_NEXT = Q_OUTER;
			else							  Q_NEXT = Q_INNER;
		Q_STORE: //set up prime table
			if(prime_counter == RANGE-1) Q_NEXT = Q_COMPLETE;
			else 					  Q_NEXT = Q_STORE;
		Q_COMPLETE: //LCD print
			Q_NEXT = Q_COMPLETE;
		default:
			Q_NEXT = Q_OUTER;
	endcase
end

//count from 0 to 1023 for first for loop
always@(posedge clk)begin
	if(~reset_n)
		prime_counter <= 2;
	else if(Q == Q_OUTER)
		prime_counter <= (prime_counter == RANGE-1) ? 2 : prime_counter + 1;					
	else if(Q == Q_STORE)
		prime_counter <= (prime_counter == RANGE-1) ? 2 : prime_counter + 1;					
end

//count from prime_counter to 1023 for second for_loop
always@(posedge clk)begin
	if(~reset_n)
		clean_idx <= 2;
	else if(Q == Q_INNER)
		clean_idx <= clean_idx + prime_tmp;		
	else if(Q == Q_OUTER)
		clean_idx <= prime_counter<<1; 
end

always@(posedge clk)begin
	if(~reset_n)
		prime_tmp <= 2;
	else if(Q == Q_OUTER)
		prime_tmp <= prime_counter; 
end

//use flag to remember whether idx is prime number or not
always@(posedge clk)begin
	if(~reset_n)
		for(i=0;i<RANGE;i=i+1)
			prime_flag[i] <= 1;
	else if(Q == Q_INNER)
		prime_flag[clean_idx] <= 0;				
end

//set up the prime table
always@(posedge clk)begin
	if(Q==Q_STORE && prime_flag[prime_counter])
		prime_table[prime_num] <= prime_counter;
end

//remember the prime quantity
always@(posedge clk)begin
	if(~reset_n)
		prime_num <= 1;
	else if(Q==Q_STORE && prime_flag[prime_counter])
		prime_num <= prime_num+1;	
end


//delay 0.7 sec on Arty board  
always@(posedge clk)begin
	if(~reset_n)
		delay_cnt <= 1;
	else if(Q == Q_COMPLETE)
		delay_cnt <= (delay_cnt == 70000001) ? 1 : delay_cnt + 1;
end

assign prime_num_tmp = prime_num-1;
always@(posedge clk)begin
	if(~reset_n)
		display_idx <= 1;
	else if(!reverse_flag && btn_pressed)//reverse for a moment should be process
		display_idx <= (display_idx-3 + prime_num_tmp <= prime_num_tmp) ? display_idx-3 + prime_num_tmp : display_idx-3;
	else if( reverse_flag && btn_pressed)//reverse for a moment should be process
		display_idx <= (display_idx+3 >= prime_num_tmp) ? display_idx+3 - prime_num_tmp : display_idx+3;
	else if((delay_cnt == 70000001) && !reverse_flag)
		display_idx <= (display_idx == prime_num_tmp) ? 1 : display_idx + 1;
	else if((delay_cnt == 70000001) && reverse_flag)
		display_idx <= (display_idx == 1) ? prime_num_tmp : display_idx - 1;
end

always@(posedge clk)begin
	if(~reset_n)
		reverse_flag <= 0;
	else if(btn_pressed)
		reverse_flag <= !reverse_flag;
end

//convert ASCII
always@(*)begin
	data[0] = (display_idx[7:4] < 10)? display_idx[7:4]+48: display_idx[7:4]+55; 
	data[1] = (display_idx[3:0] < 10)? display_idx[3:0]+48: display_idx[3:0]+55; 
	data[2] = prime_table[display_idx][9:8]+48; 
	data[3] = (prime_table[display_idx][7:4] < 10)? prime_table[display_idx][7:4]+48: prime_table[display_idx][7:4]+55; 
	data[4] = (prime_table[display_idx][3:0] < 10)? prime_table[display_idx][3:0]+48: prime_table[display_idx][3:0]+55; 
end

endmodule
