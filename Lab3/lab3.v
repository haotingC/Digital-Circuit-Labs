`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/26 15:03:31
// Design Name: 
// Module Name: lab3
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


module lab3(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

/*
aaa     usr_btn     b   counter
0000    1             0   1
0001    0                  0
0010    1                  1
            0
            1                  1
            1                  2
            1                  3
1111    1                  4

assign b = &aaa
*/
reg signed [3:0] onf;
reg [30:0] cnt0, cnt1, cnt2, cnt3;
reg [3:0] bright;
reg [20:0] counter;
reg [3:0] light;

assign usr_led = light & onf; //& light;

//reg [100] aaa

//aaa[100]=aaa[100 1], usr btn

always @(posedge clk)
begin
   if(usr_btn[0])
      cnt0 = cnt0 + 1;
   else
      cnt0 = 0;
end

always @(posedge clk)
begin
   if(usr_btn[1])
      cnt1 = cnt1 +1;
   else
      cnt1 = 0;
end

always @(posedge clk)
begin
   if(usr_btn[2])
      cnt2 = cnt2 +1;
   else
      cnt2 = 0;
end

always @(posedge clk)
begin
   if(usr_btn[3])
      cnt3 = cnt3 +1;
   else
      cnt3 = 0;
end

always @(posedge clk)
begin
   if(reset_n == 0)
      onf = 0;
   else if(cnt1 == 10000)
   begin
      if(onf == 7)
         onf = 7;
      else
         onf = onf + 1;
   end
   else if(cnt0 == 10000)
   begin
      if(onf == -8)
         onf = -8;
      else
         onf = onf - 1;
    end
    else 
       onf = onf;
end

always @(posedge clk)
begin
   if(reset_n == 0)
      bright = 0;
   else if(cnt3 == 10000)
   begin
      if(bright == 4)
         bright = 4;
      else
         bright = bright + 1;
   end
   else if(cnt2 == 10000)
   begin
      if(bright == 0)
         bright = 0;
      else
         bright = bright - 1;
   end
   else
      bright = bright;
end

always @(posedge clk)
begin
   if(reset_n == 0)
      counter = 0;
   else if(counter == 1000000)
      counter = 0;
   else
      counter = counter +1;
end

always @(posedge clk)
begin
   if(reset_n == 0)
      light = 0;
   else if(bright == 0) //5%
   begin
      if(counter == 50000)
         light = 0; 
      else if(counter == 1000000)
         light = -1;
      else
         light = light;
   end      
   else if(bright == 1)  //25%
   begin
      if(counter == 250000)
         light = 0;
      else if(counter == 1000000)
         light = -1;
      else
         light = light;
   end   
   else if(bright == 2)  //50%
   begin
      if(counter == 500000)
         light = 0;
      else if(counter == 1000000)
         light = -1;
      else
         light = light;
   end   
   else if(bright == 3)  //75%
   begin
      if(counter == 750000)
         light = 0;
      else if(counter == 1000000)
         light = -1;
      else
         light = light;
   end
end

endmodule
