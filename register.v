`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2020-2022
// Engineer: 
// 
// Create Date: 07/07/2022 03:52:58 PM
// Design Name: 
// Module Name: register
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generic register utility module
//              Parameterized for your convenience!
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module register(clk, clr, we, d, q);
  parameter N = 8;
  parameter V = 0;
  input clk, clr, we;
  input [N-1:0] d;
  output [N-1:0] q = V;
  reg [N-1:0] q;

  always @(posedge clk or posedge clr)
    begin
      if (clr)
        q = V;
      else if (clk)
        if (we)
          q = d;
    end
endmodule
