`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/10 16:37:52
// Design Name: 
// Module Name: lab8
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


module lab8(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
    );

//reg [0:127] passwd_hash = 128'hE9982EC5CA981BD365603623CF4B2277;
reg [0:127] passwd_hash = 128'hBFD00EDD436B5048006CD7A2C0753C40;

reg [2:0] P, P_next;
localparam [2:0] S_MAIN_INIT = 0, S_MAIN_SET = 1,
                 S_MAIN_MD5 = 2, S_MAIN_PARE = 3,
                 S_MAIN_WAIT = 4, S_MAIN_SHOW = 5;
// turn off all the LEDs
assign usr_led = pare;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Initial row_A   "; // Initialize the text of the first row. 
reg [127:0] row_B = "Initial row_B   "; // Initialize the text of the second row.

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


reg [7:0] tm[ 0:63];
reg [7:0] msg[ 0:63];
reg [31:0] r[ 0:63];
reg [31:0] k[ 0:63];
reg [31:0] g[ 0:63];
reg [31:0] w[ 0:15];

initial begin
  { r[ 0], r[ 1], r[ 2], r[ 3], r[ 4], r[ 5], r[ 6], r[ 7],
    r[ 8], r[ 9], r[10], r[11], r[12], r[13], r[14], r[15],
    r[16], r[17], r[18], r[19], r[20], r[21], r[22], r[23],
    r[24], r[25], r[26], r[27], r[28], r[29], r[30], r[31],
    r[32], r[33], r[34], r[35], r[36], r[37], r[38], r[39],
    r[40], r[41], r[42], r[43], r[44], r[45], r[46], r[47],
    r[48], r[49], r[50], r[51], r[52], r[53], r[54], r[55],
    r[56], r[57], r[58], r[59], r[60], r[61], r[62], r[63]
  }
  <= { 32'h07, 32'h0C, 32'h11, 32'h16, 32'h07, 32'h0C, 32'h11, 32'h16, 32'h07, 32'h0C, 32'h11, 32'h16, 32'h07, 32'h0C, 32'h11, 32'h16, //32'h07, 32'h12, 32'h17, 32'h22
       32'h05, 32'h09, 32'h0E, 32'h14, 32'h05, 32'h09, 32'h0E, 32'h14, 32'h05, 32'h09, 32'h0E, 32'h14, 32'h05, 32'h09, 32'h0E, 32'h14, //32'h05, 32'h09, 32'h14, 32'h20,
       32'h04, 32'h0B, 32'h10, 32'h17, 32'h04, 32'h0B, 32'h10, 32'h17, 32'h04, 32'h0B, 32'h10, 32'h17, 32'h04, 32'h0B, 32'h10, 32'h17, //32'h04, 32'h11, 32'h16, 32'h23,
       32'h06, 32'h0A, 32'h0F, 32'h15, 32'h06, 32'h0A, 32'h0F, 32'h15, 32'h06, 32'h0A, 32'h0F, 32'h15, 32'h06, 32'h0A, 32'h0F, 32'h15};//,32'h06, 32'h10, 32'h15, 32'h21 
       
  { k[ 0], k[ 1], k[ 2], k[ 3], k[ 4], k[ 5], k[ 6], k[ 7],
    k[ 8], k[ 9], k[10], k[11], k[12], k[13], k[14], k[15],
    k[16], k[17], k[18], k[19], k[20], k[21], k[22], k[23],
    k[24], k[25], k[26], k[27], k[28], k[29], k[30], k[31],
    k[32], k[33], k[34], k[35], k[36], k[37], k[38], k[39],
    k[40], k[41], k[42], k[43], k[44], k[45], k[46], k[47],
    k[48], k[49], k[50], k[51], k[52], k[53], k[54], k[55],
    k[56], k[57], k[58], k[59], k[60], k[61], k[62], k[63]
  }
  <= { 32'hD76AA478, 32'hE8C7B756, 32'h242070DB, 32'hC1BDCEEE,
       32'hF57C0FAF, 32'h4787C62A, 32'hA8304613, 32'hFD469501,
       32'h698098D8, 32'h8B44F7AF, 32'hFFFF5BB1, 32'h895CD7BE,
       32'h6B901122, 32'hFD987193, 32'hA679438E, 32'h49B40821,
       32'hF61E2562, 32'hC040B340, 32'h265E5A51, 32'hE9B6C7AA,
       32'hD62F105D, 32'h02441453, 32'hD8A1E681, 32'hE7D3FBC8,
       32'h21E1CDE6, 32'hC33707D6, 32'hF4D50D87, 32'h455A14ED,
       32'hA9E3E905, 32'hFCEFA3F8, 32'h676F02D9, 32'h8D2A4C8A,
       32'hFFFA3942, 32'h8771F681, 32'h6D9D6122, 32'hFDE5380C,
       32'hA4BEEA44, 32'h4BDECFA9, 32'hF6BB4B60, 32'hBEBFBC70,
       32'h289B7EC6, 32'hEAA127FA, 32'hD4EF3085, 32'h04881D05,
       32'hD9D4D039, 32'hE6DB99E5, 32'h1FA27CF8, 32'hC4AC5665,
       32'hF4292244, 32'h432AFF97, 32'hAB9423A7, 32'hFC93A039,
       32'h655B59C3, 32'h8F0CCC92, 32'hFFEFF47D, 32'h85845DD1,
       32'h6FA87E4F, 32'hFE2CE6E0, 32'hA3014314, 32'h4E0811A1,
       32'hF7537E82, 32'hBD3AF235, 32'h2AD7D2BB, 32'hEB86D391 };

  { g[ 0], g[ 1], g[ 2], g[ 3], g[ 4], g[ 5], g[ 6], g[ 7],
    g[ 8], g[ 9], g[10], g[11], g[12], g[13], g[14], g[15],
    g[16], g[17], g[18], g[19], g[20], g[21], g[22], g[23],
    g[24], g[25], g[26], g[27], g[28], g[29], g[30], g[31],
    g[32], g[33], g[34], g[35], g[36], g[37], g[38], g[39],
    g[40], g[41], g[42], g[43], g[44], g[45], g[46], g[47],
    g[48], g[49], g[50], g[51], g[52], g[53], g[54], g[55],
    g[56], g[57], g[58], g[59], g[60], g[61], g[62], g[63]
  }
  <= { 32'd00, 32'd01, 32'd02, 32'd03, 32'd04, 32'd05, 32'd06, 32'd07, 
       32'd08, 32'd09, 32'd10, 32'd11, 32'd12, 32'd13, 32'd14, 32'd15,
       32'd01, 32'd06, 32'd11, 32'd00, 32'd05, 32'd10, 32'd15, 32'd04, 
       32'd09, 32'd14, 32'd03, 32'd08, 32'd13, 32'd02, 32'd07, 32'd12,
       32'd05, 32'd08, 32'd11, 32'd14, 32'd01, 32'd04, 32'd07, 32'd10,
       32'd13, 32'd00, 32'd03, 32'd06, 32'd09, 32'd12, 32'd15, 32'd02,
       32'd00, 32'd07, 32'd14, 32'd05, 32'd12, 32'd03, 32'd10, 32'd01, 
       32'd08, 32'd15, 32'd06, 32'd13, 32'd04, 32'd11, 32'd02, 32'd09 };

  { msg[ 0], msg[ 1], msg[ 2], msg[ 3], msg[ 4], msg[ 5], msg[ 6], msg[ 7],
    msg[ 8], msg[ 9], msg[10], msg[11], msg[12], msg[13], msg[14], msg[15],
    msg[16], msg[17], msg[18], msg[19], msg[20], msg[21], msg[22], msg[23],
    msg[24], msg[25], msg[26], msg[27], msg[28], msg[29], msg[30], msg[31],
    msg[32], msg[33], msg[34], msg[35], msg[36], msg[37], msg[38], msg[39],
    msg[40], msg[41], msg[42], msg[43], msg[44], msg[45], msg[46], msg[47],
    msg[48], msg[49], msg[50], msg[51], msg[52], msg[53], msg[54], msg[55],
    msg[56], msg[57], msg[58], msg[59], msg[60], msg[61], msg[62], msg[63]
  }
  <= { 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
       8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
       8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
       8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h40, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00 };


  w[ 0]<= { 8'h30, 8'h30, 8'h30, 8'h30};
  w[ 1]<= { 8'h30, 8'h30, 8'h30, 8'h30};
  w[ 2]<= { 8'h00, 8'h00, 8'h00, 8'h80};
  w[ 3]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[ 4]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[ 5]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[ 6]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[ 7]<= { 8'h00, 8'h00, 8'h00, 8'h00};
  w[ 8]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[ 9]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[10]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[11]<= { 8'h00, 8'h00, 8'h00, 8'h00};
  w[12]<= { 8'h00, 8'h00, 8'h00, 8'h00}; 
  w[13]<= { 8'h00, 8'h00, 8'h00, 8'h00};
  w[14]<= { 8'h00, 8'h00, 8'h00, 8'h40};
  w[15]<= { 8'h00, 8'h00, 8'h00, 8'h00};
  
end

reg [7:0] hash[0:15];

localparam PAD_LEN = 56;
reg [ 6: 0] cnt;
reg [1:0] cnt_inner;
reg [31: 0] a, b, c, d, f;
reg [31: 0] leftrotate;

    
reg pare, pare_done;



                 
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
      P_next = S_MAIN_SET;
    S_MAIN_SET:
      P_next = S_MAIN_MD5;
    S_MAIN_MD5:
      if (cnt == 63 && cnt_inner == 3) P_next = S_MAIN_PARE;
    S_MAIN_PARE:
      if (pare == 1) P_next = S_MAIN_WAIT; //|| last == 1
      else if(pare_done == 1) P_next = S_MAIN_SET;
      else P_next = S_MAIN_PARE;
    S_MAIN_WAIT:
      /*if(btn_pressed == 1)*/ P_next = S_MAIN_SHOW;
     // else P_next = S_MAIN_WAIT;
    S_MAIN_SHOW:
      P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_INIT;
  endcase
end

reg [26: 0] mm;

always @(posedge clk) begin
  if(~reset_n) mm <=0;
  else if(P == S_MAIN_PARE && P_next == S_MAIN_SET)
    mm <= mm + 1;
end

reg [16: 0] tm_cnt;

always @(posedge clk) begin
  if(~reset_n || tm_cnt == 100000)
    tm_cnt <= 0;
  else if(pare == 0)
    tm_cnt <= tm_cnt + 1;
  else
    tm_cnt <= tm_cnt;
end



reg last;
always @(posedge clk) begin
  if(~reset_n)
    last <= 0;
  else if(mm == 100000000)
    last <= 1;
  else
    last <= last;
end

always @(posedge clk) begin
  if(P == S_MAIN_INIT && P_next == S_MAIN_SET) begin
    msg[ 0] <= 8'h30; msg[ 1] <= 8'h30;
    msg[ 2] <= 8'h30; msg[ 3] <= 8'h30;
    msg[ 4] <= 8'h30; msg[ 5] <= 8'h30;
    msg[ 6] <= 8'h30; msg[ 7] <= 8'h30;
  end
  else if(cnt == 64 && cnt_inner == 3 && P_next != S_MAIN_WAIT)begin
    if(msg[ 7] != 57)
	  msg[ 7] <= msg[ 7] + 1;
	else begin//(msg[ 7] == 57) 
	  msg[ 7] <= 48;
	  if(msg[ 6] != 57)
	    msg[ 6] <= msg[ 6] + 1;        
      else begin//(msg[ 6] == 57) 
        msg[ 6] <= 48;
        if(msg[ 5] != 57)
          msg[ 5] <= msg[ 5] + 1;
        else begin//(msg[ 5] == 57)
          msg[ 5] <= 48;
          if(msg[ 4] != 57)//(msg[ 4] == 57)
            msg[ 4] <= msg[ 4] + 1;
          else begin
            msg[ 4] <= 48;
            if(msg[ 3] != 57)//(msg[ 3] == 57)
              msg[ 3] <= msg[ 3] + 1;
            else begin
              msg[ 3] <= 48;
              if(msg[ 2] != 57)//(msg[ 3] == 57)
                msg[ 2] <= msg[ 2] + 1;
              else begin
                msg[ 2] <= 48;
                if(msg[ 1] != 57)
                  msg[ 1] <= msg[ 1] + 1;
                else begin
                  msg[ 1] <= 48;
                  msg[ 0] <= msg[ 0] + 1;
                end
              end  
            end   
          end
        end
      end
    end
  end
end

always @(posedge clk) begin
  if(P == S_MAIN_SET)begin
    w[0] <={ msg[ 3], msg[ 2], msg[ 1], msg[ 0]};
	w[1] <={ msg[ 7], msg[ 6], msg[ 5], msg[ 4]};
  end
end

reg [31: 0] h0, h1, h2, h3;

always @(posedge clk) begin
  if (~reset_n) 
  begin
    row_A <= "Initial row_A   ";
    row_B <= "Initial row_B   ";
  end 
  /*else if(P == S_MAIN_MD5 || P == S_MAIN_SET)
  begin
    row_A <= "Passwd: xxxxxxxx";
    row_A[ 63: 56] <= msg[ 0];
    row_A[ 55: 48] <= msg[ 1];
    row_A[ 47: 40] <= msg[ 2];
    row_A[ 39: 32] <= msg[ 3];
    row_A[ 31: 24] <= msg[ 4];
    row_A[ 23: 16] <= msg[ 5];
    row_A[ 15:  8] <= msg[ 6];
    row_A[  7:  0] <= msg[ 7];
    row_B <= "Time: yyyyyyy ms";  
    row_B[ 79: 72] <= tm[ 1];
    row_B[ 71: 64] <= tm[ 2];
    row_B[ 63: 56] <= tm[ 3];
    row_B[ 55: 48] <= tm[ 4];
    row_B[ 47: 40] <= tm[ 5];
    row_B[ 39: 32] <= tm[ 6];
    row_B[ 31: 24] <= tm[ 7];
  end*/
  else if(P == S_MAIN_PARE) begin   
    /*row_A[127:120] <= (h0[ 31: 28] > 9) ? h0[ 31: 28] + 55 : h0[ 31: 28] + 48;
    row_A[119:112] <= (h0[ 27: 24] > 9) ? h0[ 27: 24] + 55 : h0[ 27: 24] + 48;
    row_A[111:104] <= (h0[ 23: 20] > 9) ? h0[ 23: 20] + 55 : h0[ 23: 20] + 48;
    row_A[103: 96] <= (h0[ 19: 16] > 9) ? h0[ 19: 16] + 55 : h0[ 19: 16] + 48;
    row_A[ 95: 88] <= (h0[ 15: 12] > 9) ? h0[ 15: 12] + 55 : h0[ 15: 12] + 48;
    row_A[ 87: 80] <= (h0[ 11:  8] > 9) ? h0[ 11:  8] + 55 : h0[ 11:  8] + 48;
    row_A[ 79: 72] <= (h0[  7:  4] > 9) ? h0[  7:  4] + 55 : h0[  7:  4] + 48;
    row_A[ 71: 64] <= (h0[  3:  0] > 9) ? h0[  3:  0] + 55 : h0[  3:  0] + 48;
    row_A[ 63: 56] <= (h1[ 31: 28] > 9) ? h1[ 31: 28] + 55 : h1[ 31: 28] + 48;
    row_A[ 55: 48] <= (h1[ 27: 24] > 9) ? h1[ 27: 24] + 55 : h1[ 27: 24] + 48;
    row_A[ 47: 40] <= (h1[ 23: 20] > 9) ? h1[ 23: 20] + 55 : h1[ 23: 20] + 48;
    row_A[ 39: 32] <= (h1[ 19: 16] > 9) ? h1[ 19: 16] + 55 : h1[ 19: 16] + 48;
    row_A[ 31: 24] <= (h1[ 15: 12] > 9) ? h1[ 15: 12] + 55 : h1[ 15: 12] + 48;
    row_A[ 23: 16] <= (h1[ 11:  8] > 9) ? h1[ 11:  8] + 55 : h1[ 11:  8] + 48;
    row_A[ 15:  8] <= (h1[  7:  4] > 9) ? h1[  7:  4] + 55 : h1[  7:  4] + 48;
    row_A[  7:  0] <= (h1[  3:  0] > 9) ? h1[  3:  0] + 55 : h1[  3:  0] + 48;

    row_B[127:120] <= (h2[ 31: 28] > 9) ? h2[ 31: 28] + 55 : h2[ 31: 28] + 48;
    row_B[119:112] <= (h2[ 27: 24] > 9) ? h2[ 27: 24] + 55 : h2[ 27: 24] + 48;
    row_B[111:104] <= (h2[ 23: 20] > 9) ? h2[ 23: 20] + 55 : h2[ 23: 20] + 48;
    row_B[103: 96] <= (h2[ 19: 16] > 9) ? h2[ 19: 16] + 55 : h2[ 19: 16] + 48;
    row_B[ 95: 88] <= (h2[ 15: 12] > 9) ? h2[ 15: 12] + 55 : h2[ 15: 12] + 48;
    row_B[ 87: 80] <= (h2[ 11:  8] > 9) ? h2[ 11:  8] + 55 : h2[ 11:  8] + 48;
    row_B[ 79: 72] <= (h2[  7:  4] > 9) ? h2[  7:  4] + 55 : h2[  7:  4] + 48;
    row_B[ 71: 64] <= (h2[  3:  0] > 9) ? h2[  3:  0] + 55 : h2[  3:  0] + 48;
    row_B[ 63: 56] <= (h3[ 31: 28] > 9) ? h3[ 31: 28] + 55 : h3[ 31: 28] + 48;
    row_B[ 55: 48] <= (h3[ 27: 24] > 9) ? h3[ 27: 24] + 55 : h3[ 27: 24] + 48;
    row_B[ 47: 40] <= (h3[ 23: 20] > 9) ? h3[ 23: 20] + 55 : h3[ 23: 20] + 48;
    row_B[ 39: 32] <= (h3[ 19: 16] > 9) ? h3[ 19: 16] + 55 : h3[ 19: 16] + 48;
    row_B[ 31: 24] <= (h3[ 15: 12] > 9) ? h3[ 15: 12] + 55 : h3[ 15: 12] + 48;
    row_B[ 23: 16] <= (h3[ 11:  8] > 9) ? h3[ 11:  8] + 55 : h3[ 11:  8] + 48;
    row_B[ 15:  8] <= (h3[  7:  4] > 9) ? h3[  7:  4] + 55 : h3[  7:  4] + 48;
    row_B[  7:  0] <= (h3[  3:  0] > 9) ? h3[  3:  0] + 55 : h3[  3:  0] + 48;*/
    row_A[127:120] <= (hash[ 8][ 7: 4] > 9) ? hash[ 8][ 7: 4] + 55 : hash[ 8][ 7: 4] + 48;
    row_A[119:112] <= (hash[ 8][ 3: 0] > 9) ? hash[ 8][ 3: 0] + 55 : hash[ 8][ 3: 0] + 48;
    row_A[111:104] <= (hash[ 9][ 7: 4] > 9) ? hash[ 9][ 7: 4] + 55 : hash[ 9][ 7: 4] + 48;
    row_A[103: 96] <= (hash[ 9][ 3: 0] > 9) ? hash[ 9][ 3: 0] + 55 : hash[ 9][ 3: 0] + 48;
    row_A[ 95: 88] <= (hash[10][ 7: 4] > 9) ? hash[10][ 7: 4] + 55 : hash[10][ 7: 4] + 48;
    row_A[ 87: 80] <= (hash[10][ 3: 0] > 9) ? hash[10][ 3: 0] + 55 : hash[10][ 3: 0] + 48;
    row_A[ 79: 72] <= (hash[11][ 7: 4] > 9) ? hash[11][ 7: 4] + 55 : hash[11][ 7: 4] + 48;
    row_A[ 71: 64] <= (hash[11][ 3: 0] > 9) ? hash[11][ 3: 0] + 55 : hash[11][ 3: 0] + 48;
    row_A[ 63: 56] <= (hash[12][ 7: 4] > 9) ? hash[12][ 7: 4] + 55 : hash[12][ 7: 4] + 48;
    row_A[ 55: 48] <= (hash[12][ 3: 0] > 9) ? hash[12][ 3: 0] + 55 : hash[12][ 3: 0] + 48;
    row_A[ 47: 40] <= (hash[13][ 7: 4] > 9) ? hash[13][ 7: 4] + 55 : hash[13][ 7: 4] + 48;
    row_A[ 39: 32] <= (hash[13][ 3: 0] > 9) ? hash[13][ 3: 0] + 55 : hash[13][ 3: 0] + 48;
    row_A[ 31: 24] <= (hash[14][ 7: 4] > 9) ? hash[14][ 7: 4] + 55 : hash[14][ 7: 4] + 48;
    row_A[ 23: 16] <= (hash[14][ 3: 0] > 9) ? hash[14][ 3: 0] + 55 : hash[14][ 3: 0] + 48;
    row_A[ 15:  8] <= (hash[15][ 7: 4] > 9) ? hash[15][ 7: 4] + 55 : hash[15][ 7: 4] + 48;
    row_A[  7:  0] <= (hash[15][ 3: 0] > 9) ? hash[15][ 3: 0] + 55 : hash[15][ 3: 0] + 48;
    //row_A<= {msg[0], msg[1], msg[2], msg[3], msg[4], msg[5], msg[6], msg[7], "         "};
    /*row_A[127:120] <= (a[ 31: 28] > 9) ? a[ 31: 28] + 55 : a[ 31: 28] + 48;
    row_A[119:112] <= (a[ 27: 24] > 9) ? a[ 27: 24] + 55 : a[ 27: 24] + 48;
    row_A[111:104] <= (a[ 23: 20] > 9) ? a[ 23: 20] + 55 : a[ 23: 20] + 48;
    row_A[103: 96] <= (a[ 19: 16] > 9) ? a[ 19: 16] + 55 : a[ 19: 16] + 48;
    row_A[ 95: 88] <= (a[ 15: 12] > 9) ? a[ 15: 12] + 55 : a[ 15: 12] + 48;
    row_A[ 87: 80] <= (a[ 11:  8] > 9) ? a[ 11:  8] + 55 : a[ 11:  8] + 48;
    row_A[ 79: 72] <= (a[  7:  4] > 9) ? a[  7:  4] + 55 : a[  7:  4] + 48;
    row_A[ 71: 64] <= (a[  3:  0] > 9) ? a[  3:  0] + 55 : a[  3:  0] + 48;
    row_A[ 63: 56] <= (f[ 31: 28] > 9) ? f[ 31: 28] + 55 : f[ 31: 28] + 48;
    row_A[ 55: 48] <= (f[ 27: 24] > 9) ? f[ 27: 24] + 55 : f[ 27: 24] + 48;
    row_A[ 47: 40] <= (f[ 23: 20] > 9) ? f[ 23: 20] + 55 : f[ 23: 20] + 48;
    row_A[ 39: 32] <= (f[ 19: 16] > 9) ? f[ 19: 16] + 55 : f[ 19: 16] + 48;
    row_A[ 31: 24] <= (f[ 15: 12] > 9) ? f[ 15: 12] + 55 : f[ 15: 12] + 48;
    row_A[ 23: 16] <= (f[ 11:  8] > 9) ? f[ 11:  8] + 55 : f[ 11:  8] + 48;
    row_A[ 15:  8] <= (f[  7:  4] > 9) ? f[  7:  4] + 55 : f[  7:  4] + 48;
    row_A[  7:  0] <= (f[  3:  0] > 9) ? f[  3:  0] + 55 : f[  3:  0] + 48;*/
    /*row_A[ 63: 56] <= (b[ 31: 28] > 9) ? b[ 31: 28] + 55 : b[ 31: 28] + 48;
    row_A[ 55: 48] <= (b[ 27: 24] > 9) ? b[ 27: 24] + 55 : b[ 27: 24] + 48;
    row_A[ 47: 40] <= (b[ 23: 20] > 9) ? b[ 23: 20] + 55 : b[ 23: 20] + 48;
    row_A[ 39: 32] <= (b[ 19: 16] > 9) ? b[ 19: 16] + 55 : b[ 19: 16] + 48;
    row_A[ 31: 24] <= (b[ 15: 12] > 9) ? b[ 15: 12] + 55 : b[ 15: 12] + 48;
    row_A[ 23: 16] <= (b[ 11:  8] > 9) ? b[ 11:  8] + 55 : b[ 11:  8] + 48;
    row_A[ 15:  8] <= (b[  7:  4] > 9) ? b[  7:  4] + 55 : b[  7:  4] + 48;
    row_A[  7:  0] <= (b[  3:  0] > 9) ? b[  3:  0] + 55 : b[  3:  0] + 48;*/
    /*row_B[127:120] <= (leftrotate[ 31: 28] > 9) ? leftrotate[ 31: 28] + 55 : leftrotate[ 31: 28] + 48;
    row_B[119:112] <= (leftrotate[ 27: 24] > 9) ? leftrotate[ 27: 24] + 55 : leftrotate[ 27: 24] + 48;
    row_B[111:104] <= (leftrotate[ 23: 20] > 9) ? leftrotate[ 23: 20] + 55 : leftrotate[ 23: 20] + 48;
    row_B[103: 96] <= (leftrotate[ 19: 16] > 9) ? leftrotate[ 19: 16] + 55 : leftrotate[ 19: 16] + 48;
    row_B[ 95: 88] <= (leftrotate[ 15: 12] > 9) ? leftrotate[ 15: 12] + 55 : leftrotate[ 15: 12] + 48;
    row_B[ 87: 80] <= (leftrotate[ 11:  8] > 9) ? leftrotate[ 11:  8] + 55 : leftrotate[ 11:  8] + 48;
    row_B[ 79: 72] <= (leftrotate[  7:  4] > 9) ? leftrotate[  7:  4] + 55 : leftrotate[  7:  4] + 48;
    row_B[ 71: 64] <= (leftrotate[  3:  0] > 9) ? leftrotate[  3:  0] + 55 : leftrotate[  3:  0] + 48;*/
    row_B[127:120] <= (hash[ 0][ 7: 4] > 9) ? hash[ 0][ 7: 4] + 55 : hash[ 0][ 7: 4] + 48;
    row_B[119:112] <= (hash[ 0][ 3: 0] > 9) ? hash[ 0][ 3: 0] + 55 : hash[ 0][ 3: 0] + 48;
    row_B[111:104] <= (hash[ 1][ 7: 4] > 9) ? hash[ 1][ 7: 4] + 55 : hash[ 1][ 7: 4] + 48;
    row_B[103: 96] <= (hash[ 1][ 3: 0] > 9) ? hash[ 1][ 3: 0] + 55 : hash[ 1][ 3: 0] + 48;
    row_B[ 95: 88] <= (hash[ 2][ 7: 4] > 9) ? hash[ 2][ 7: 4] + 55 : hash[ 2][ 7: 4] + 48;
    row_B[ 87: 80] <= (hash[ 2][ 3: 0] > 9) ? hash[ 2][ 3: 0] + 55 : hash[ 2][ 3: 0] + 48;
    row_B[ 79: 72] <= (hash[ 3][ 7: 4] > 9) ? hash[ 3][ 7: 4] + 55 : hash[ 3][ 7: 4] + 48;
    row_B[ 71: 64] <= (hash[ 3][ 3: 0] > 9) ? hash[ 3][ 3: 0] + 55 : hash[ 3][ 3: 0] + 48;
    row_B[ 63: 56] <= (hash[ 4][ 7: 4] > 9) ? hash[ 4][ 7: 4] + 55 : hash[ 4][ 7: 4] + 48;
    row_B[ 55: 48] <= (hash[ 4][ 3: 0] > 9) ? hash[ 4][ 3: 0] + 55 : hash[ 4][ 3: 0] + 48;
    row_B[ 47: 40] <= (hash[ 5][ 7: 4] > 9) ? hash[ 5][ 7: 4] + 55 : hash[ 5][ 7: 4] + 48;
    row_B[ 39: 32] <= (hash[ 5][ 3: 0] > 9) ? hash[ 5][ 3: 0] + 55 : hash[ 5][ 3: 0] + 48;
    row_B[ 31: 24] <= (hash[ 6][ 7: 4] > 9) ? hash[ 6][ 7: 4] + 55 : hash[ 6][ 7: 4] + 48;
    row_B[ 23: 16] <= (hash[ 6][ 3: 0] > 9) ? hash[ 6][ 3: 0] + 55 : hash[ 6][ 3: 0] + 48;
    row_B[ 15:  8] <= (hash[ 7][ 7: 4] > 9) ? hash[ 7][ 7: 4] + 55 : hash[ 7][ 7: 4] + 48;
    row_B[  7:  0] <= (hash[ 7][ 3: 0] > 9) ? hash[ 7][ 3: 0] + 55 : hash[ 7][ 3: 0] + 48;
    /*row_B[ 63: 56] <= msg[ 0]; row_B[ 55: 48] <= msg[ 1]; 
    row_B[ 47: 40] <= msg[ 2]; row_B[ 39: 32] <= msg[ 3]; 
    row_B[ 31: 24] <= msg[ 4]; row_B[ 23: 16] <= msg[ 5]; 
    row_B[ 15:  8] <= msg[ 6]; row_B[  7:  0] <= msg[ 7];*/
  end
  else if(P == S_MAIN_SHOW) begin 
  row_A<= {msg[7], msg[6], msg[5], msg[4], msg[3], msg[2], msg[1], msg[0], "         "};
  end
  else if(P == S_MAIN_WAIT)
  begin
    row_A <= "Press the BTN3  ";
    row_B <= "to show the ans.";   
  end
  
  /*else if(P == S_MAIN_SHOW && last == 1)
  begin
    row_A <= "There is not    ";
    row_B <= "found the answer";
  end*/
end



always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET || cnt ==65 && cnt_inner == 3) cnt <= 0;
  else if(cnt != 65 && cnt_inner == 3)
    cnt <= cnt + 1;
  else
    cnt <= cnt;
end



always @(posedge clk)
begin
  if(~reset_n) cnt_inner <= 0;
  else if(P == S_MAIN_SET)
    cnt_inner <= 1;
  else if(cnt_inner == 1)
    cnt_inner <= 2;
  else if(cnt_inner == 2)
    cnt_inner <= 3;
  else if(cnt_inner == 3)
    cnt_inner <= 1;
end

always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET)
    f <= (32'hEFCDAB89 & 32'h98BADCFE) | (~(32'hEFCDAB89) & 32'h10325476);
  else if((cnt >= 0 && cnt < 15)&&cnt_inner == 3)
    f <= (b & c) | ((~b) & d);
  else if((cnt >= 15 && cnt < 31) && cnt_inner == 3)
    f <= (d & b) | ((~d) & c);
  else if((cnt >= 31 && cnt < 47) && cnt_inner == 3)
    f <= b ^ c ^ d;
  else if((cnt >= 47) && cnt_inner == 3)
    f <= c ^ (b | (~d));
end


always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET)
    a <= 32'h67452301;
  else if((P == S_MAIN_MD5)&& cnt_inner == 2)
    a <= d;
end

always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET)
    b <= 32'hEFCDAB89;
  else if((P == S_MAIN_MD5)&& cnt_inner == 2)
    b <= b + leftrotate;
end

always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET)
    c <= 32'h98BADCFE;
  else if((P == S_MAIN_MD5)&& cnt_inner == 2)
    c <= b;
end

always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET)
    d <= 32'h10325476;
  else if((P == S_MAIN_MD5)&& cnt_inner == 2)
    d <= c;
end


always @(posedge clk)
begin
  if(cnt_inner == 1)
    leftrotate <= ((a + f + k[cnt] + w[g[cnt]]) << r[cnt])| ((a + f + k[cnt] + w [g[cnt]]) >> (32 - r[cnt]));
end


reg [3:0] cnt_pare;

always @(posedge clk)
begin
  if(~reset_n || P == S_MAIN_SET) cnt_pare <= 0;
  else if(P == S_MAIN_PARE)
    cnt_pare <= cnt_pare + 1;
  else
    cnt_pare <= cnt_pare;
end

always @(posedge clk)
begin
  if(~reset_n)
    h0 <= 0;
  else if(P == S_MAIN_PARE)
    h0 <= 32'h67452301 + a;
end

always @(posedge clk)
begin
  if(~reset_n)
    h1 <= 0;
  else if(P == S_MAIN_PARE)
    h1 <= 32'hEFCDAB89 + b;
end

always @(posedge clk)
begin
  if(~reset_n)
    h2 <= 0;
  else if(P == S_MAIN_PARE)
    h2 <= 32'h98BADCFE + c;
end

always @(posedge clk)
begin
  if(~reset_n)
    h3 <= 0;
  else if(P == S_MAIN_PARE)
    h3 <= 32'h10325476 + d;
end

always @(posedge clk) begin
  if(~reset_n)begin
    hash[ 0]<= 0;
    hash[ 1]<= 0;
    hash[ 2]<= 0;
    hash[ 3]<= 0;
    hash[ 4]<= 0;
    hash[ 5]<= 0;
    hash[ 6]<= 0;
    hash[ 7]<= 0;
    hash[ 8]<= 0;
    hash[ 9]<= 0;
    hash[10]<= 0;
    hash[11]<= 0;
    hash[12]<= 0;
    hash[13]<= 0;
    hash[14]<= 0;
    hash[15]<= 0;
  end
  else if(P == S_MAIN_PARE) begin
    hash[ 0]<= h0[  7:  0];
    hash[ 1]<= h0[ 15:  8];
    hash[ 2]<= h0[ 23: 16];
    hash[ 3]<= h0[ 31: 24];
    hash[ 4]<= h1[  7:  0];
    hash[ 5]<= h1[ 15:  8];
    hash[ 6]<= h1[ 23: 16];
    hash[ 7]<= h1[ 31: 24];
    hash[ 8]<= h2[  7:  0];
    hash[ 9]<= h2[ 15:  8];
    hash[10]<= h2[ 23: 16];
    hash[11]<= h2[ 31: 24];
    hash[12]<= h3[  7:  0];
    hash[13]<= h3[ 15:  8];
    hash[14]<= h3[ 23: 16];
    hash[15]<= h3[ 31: 24];
  end
end

always @(posedge clk) begin
  if(~reset_n || P == S_MAIN_INIT) pare <= 0;
  else if(hash[0] == passwd_hash[0:7] && hash[1] == passwd_hash[8:15] && hash[2] == passwd_hash[16:23] && hash[3] == passwd_hash[24:31] && hash[4] == passwd_hash[32:39] &&
                 hash[5] == passwd_hash[40:47] && hash[6] == passwd_hash[48:55] && hash[7] == passwd_hash[56:63] && hash[8] == passwd_hash[64:71] && hash[9] == passwd_hash[72:79] &&
                 hash[10] == passwd_hash[80:87] && hash[11] == passwd_hash[88:95] && hash[12] == passwd_hash[96:103] && hash[13] == passwd_hash[104:111] && hash[14] == passwd_hash[112:119] &&
                 hash[15] == passwd_hash[120:127] ) 
    pare <= 1;
  else pare <= pare;
end

always @(posedge clk) begin
  if(~reset_n || P == S_MAIN_SET) pare_done <= 0;
  else if(cnt == 65 && cnt_inner == 1 && pare == 0)
    pare_done <= 1;
  else 
    pare_done <= pare_done;
end

always @(posedge clk) begin
  if(~reset_n) begin
    tm[ 0] <= 8'h30; tm[ 1] <= 8'h30;
    tm[ 2] <= 8'h30; tm[ 3] <= 8'h30;
    tm[ 4] <= 8'h30; tm[ 5] <= 8'h30;
    tm[ 6] <= 8'h30; tm[ 7] <= 8'h30;
  end
  else if(tm_cnt == 100000)begin
    if(tm[ 7] != 57)
	  tm[ 7] <= tm[ 7] + 1;
	else begin//(tm[ 7] == 57) 
	  tm[ 7] <= 48;
	  if(tm[ 6] != 57)
	    tm[ 6] <= tm[ 6] + 1;        
      else begin//(tm[ 6] == 57) 
        tm[ 6] <= 48;
        if(tm[ 5] != 57)
          tm[ 5] <= tm[ 5] + 1;
        else begin//(tm[ 5] == 57)
          tm[ 5] <= 48;
          if(tm[ 4] != 57)//(tm[ 4] == 57)
            tm[ 4] <= tm[ 4] + 1;
          else begin
            tm[ 4] <= 48;
            if(tm[ 3] != 57)//(tm[ 3] == 57)
              tm[ 3] <= tm[ 3] + 1;
            else begin
              tm[ 3] <= 48;
              if(tm[ 2] != 57)//(tm[ 3] == 57)
                tm[ 2] <= tm[ 2] + 1;
              else begin
                tm[ 2] <= 48;
                tm[ 1] <= tm[ 1] + 1;
              end  
            end   
          end
        end
      end
    end
  end
end

endmodule
