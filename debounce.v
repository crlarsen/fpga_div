`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2020-2022
// Engineer: 
// 
// Create Date: 07/09/2022 08:13:35 AM
// Design Name: 
// Module Name: debounce
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

module debounce(clk, btnin, btnout);
  input clk, btnin;
  output btnout;

  reg [2:0] delay;

  initial
    begin
      delay = 3'b000;
    end

  always @(posedge clk)
    begin
      if (clk)
        begin
          delay = {btnin, delay[2:1]};
        end
    end

  assign btnout = &delay;

endmodule
