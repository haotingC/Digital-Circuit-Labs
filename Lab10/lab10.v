`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/08/25 14:29:54
// Design Name: 
// Module Name: lab10
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a moon moving across a city
//              night view on a screen through the VGA interface of Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,

    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [33:0] moon_clock;
reg  [3:0]  fire_clock;
wire [9:0]  pos;
wire        moon_region;
wire        fire_region;

// declare SRAM control signals
wire [16:0] sram_addr, sram_addr1, sram_addr2;
wire [11:0] data_in;
wire [11:0] print_out, data_out, data_out1, data_out2;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;       // 50MHz clock for VGA control
wire video_on;      // when video_on is 0, the VGA controller is sending
                    // synchronization signals to the display device.
  
wire pixel_tick;    // when pixel tick is 1, we must update the RGB value
                    // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x; // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y; // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [16:0] pixel_addr, pixel_addr1, pixel_addr2;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
  
// Instiantiate a VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores an 320x240 12-bit city image, plus a 64x40 moon image.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
          
sran1 #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(64*40))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr1), .data_i(data_in), .data_o(data_out1));

sran2 #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(22500))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr2), .data_i(data_in), .data_o(data_out2));
          
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr1 = pixel_addr1;
assign sram_addr2 = pixel_addr2;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the moon, upper bits of the
// moon clock is the x position of the moon in the VGA screen
assign pos = moon_clock[33:24];

always @(posedge clk) begin
  if (~reset_n || moon_clock[33:25] > VBUF_W + 64)
    moon_clock <= 0;
  else
    moon_clock <= moon_clock + 1;
end

always @(posedge clk) begin
  if (~reset_n || fire_clock == 8)
    fire_clock <= 0;
  else if(moon_clock[24: 0] == 0 && fire_clock < 8)
    fire_clock <= fire_clock + 1;
  else
    fire_clock <= fire_clock;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the moon image is 64x40, when scaled
// up to the screen, it becomes 128x80
assign moon_region = pixel_y >= 0 && pixel_y < 80 &&
                     (pixel_x + 127) >= pos && pixel_x < pos + 1;
                     
assign fire_region = pixel_y >= 100 && pixel_y < 200 &&
                     pixel_x >= 450 && pixel_x < 550 ;

always @ (posedge clk) begin
  if(~reset_n)
    pixel_addr <= 0;
  else if(~moon_region)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr1 <= 0;
  else if (moon_region)
    pixel_addr1 <= ((pixel_y&10'h2FE)<<5) + ((pixel_x-pos+127)>>1);
end

always @ (posedge clk) begin
  if(~reset_n)
    pixel_addr2 <= 0;
  else if(fire_region)
    pixel_addr2 <= fire_clock * 2500 + ((pixel_y-100) >> 1) * 50 + ((pixel_x-450) >> 1);
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end



always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(moon_region)begin
    if(data_out1 == 12'h0f0)
      rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    else
      rgb_next = data_out1;
  end
  else if(fire_region)begin
    if(data_out2 == 12'h000)
      rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    else
      rgb_next = data_out2;
  end
  else
    rgb_next = data_out;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
