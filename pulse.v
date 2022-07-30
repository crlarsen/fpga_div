`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2020-2022
// Engineer: 
// 
// Create Date: 07/08/2022 10:55:28 AM
// Design Name: 
// Module Name: pulse, pulseTE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: pulse: Generate a single pulse when a button is pressed starting
//                     on the rising edge of the clock.
//              pulseFE: Generate a single pulse when a button is pressed starting
//                     on the falling edge of the clock.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pulse(clk, btn, we);
  input clk, btn;
  output we;

  reg [2:0] delay;

  initial
    begin
      delay = 3'b000;
    end

  always @(posedge clk)
    begin
      delay = {btn, delay[2], ~delay[1]};
    end

  assign we = &delay;

endmodule

module pulseFE(clk, btn, we);
  input clk, btn;
  output we;

  reg [2:0] delay;

  initial
    begin
      delay = 3'b000;
    end

  always @(negedge clk)
    begin
      delay = {btn, delay[2], ~delay[1]};
    end

  assign we = &delay;

endmodule
