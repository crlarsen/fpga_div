`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2022 
// Engineer: 
// 
// Create Date: 07/09/2022 03:40:13 AM
// Design Name: 
// Module Name: fp_div_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Test bench to verify that the state machine completes normal
//              division in NSIG+5 cycles, and special cases (sNaNs, qNaNs,
//              Infinities, and Zeroes) in 2 cycles.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fp_div_tb();
  parameter NEXP = 5;
  parameter NSIG = 10;
  `include "ieee-754-flags.vh"
  reg [NEXP+NSIG:0] a, b;
  reg [NRAS:0] ra = 1 << roundTiesToEven;
  wire [NEXP+NSIG:0] q;
  wire done;
  wire [NTYPES-1:0] qFlags;             // Type of return value: sNaN, qNaN, Infinity,
  wire [NEXCEPTIONS-1:0] exception;     // Which exceptions were signalled?

  reg clk = 0, start = 0;

  always @(*) begin
    #10 clk = ~clk;
    #10 clk = ~clk;
//    a = 16'h4200; b = 16'h4500; // 3 / 5
//    a = 16'h4500; b = 16'h4200; // 5 / 3
//    a = 16'h5D8C; b = 16'h5710; // PI = 335 / 113
//    a = 16'h0; b = 16'h5710; // 0 / 113
//    a = 16'h5D8C; b = 16'h0; // 335 / 0
    a = 16'h0; b = 16'h0; // 0 / 0
    #5 start = 1;

    #5 clk = ~clk;
    #5 start = 0;
    #5 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;

    #10 clk = ~clk;
    #10 clk = ~clk;
  end

  always @(*) begin
    a = 16'h4D80; b = 16'h4700;

    #20 start = 1;
    #10 start = 0;
  end

  fp_div #(NEXP,NSIG) U0(clk, start, a, b, ra, q, qFlags, exception, done);
endmodule
