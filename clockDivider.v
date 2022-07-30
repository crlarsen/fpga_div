`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2022
// Engineer: 
// 
// Create Date: 07/09/2022 01:59:16 PM
// Design Name: 
// Module Name: clockDivider
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


module clockDivider(clk, arst, q, done) ;
  parameter N = 7 ;
  parameter MAX = 127 ;
  input clk,arst;
  output [N-1:0] q = 0;
  output done = 0;

  reg [N-1:0] q ;
  reg done ;
  
  always @(posedge clk or posedge arst)
    begin
      if (arst == 1'b1)
        begin
          q <= 0 ;
          done <= 0 ;
        end
      else if (q == MAX)
        begin
          q <= 0 ;
          done <= ~done ;
        end
      else
        begin
          q <= q + 1;
        end
    end
    
endmodule
