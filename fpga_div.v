`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2020-2022
// Engineer: 
// 
// Create Date: 07/07/2022 03:44:34 PM
// Design Name: 
// Module Name: fpga_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: FPGA test harness for floating point division implemented as a
//              state machine.
//
// Inputs:
// o clk -- 100MHz Digilent BASYS 3 board system clock.
// o sw[15:0] -- 16-bit binary input which can be loaded into various registers.
// o btnD -- Reset register values to default values:
//           - ra (rounding attribute) is reset to roundTiesToEven.
//           - dividend is reset to 16'h5D8C (integer value 355).
//           - divisor is reset to 16'h5710 (integer value 113).
//             [Note: The ratio of these 2 numbers approximates PI to the level
//             of precision possible for the binary16 floating point format.]
// o btnL -- Latch sw[15:0] into the dividend register.
// o btnR -- Latch sw[15:0] into the divisor register.
// o btnC -- Latch sw[3:0] into the ra (rounding attribute) register.
// o btnD -- Send `start' pulse to begin execution of the state machine.
//           Press and hold until LED 2 flashes on.
//
// Outputs:
// o led -- Report state for:
//          - LED 15: State Machine Clock
//          - LED 14: Done Signal
//          - LED 13: Start Signal
//          - LED 12: "Up" Push Button
//          - LED 11: Pulse for the register write/reset signals
//          - LED 10: "Down" Push Button
//          - LED 9: "Left" Push Button
//          - LED 8: "Center" Push Button
//          - LED 7: "Right" Push Button
//          - LED 6: unused
//          - LED 5: unused
//          - LED 4: Inexact Exception
//          - LED 3: Underflow Exception
//          - LED 2: Overflow Exception
//          - LED 1: Divide by Zero Exception
//          - LED 0: Invalid Exception
//          [Note: LED 11 showing the pulse for the reset, dividendWE, raWE,
//          and divisorWE signals flashes for just 1 cycle at 190Hz (a little
//          more than 5 milliseconds) when their corresponding buttons are
//          pressed. Blink and you'll miss it!]
// o seg -- 7-segment display shows the quotient significand as the computation
//          is taking place, and the final result after `done' has been toggled.
// o an -- Used by display logic to sequentially flash the digits onto the
//         7-segment display.
// o dp -- Disabled, otherwise not used by the test harness.
// 
// Dependencies: pulse.v, debounce.v, register.v, mod_counter.v, fp_div,
//               fp_class.v, round.v, padder11.v, padder24.v, padder53.v,
//               padder113.v, x7seg.v, hex2_7seg.v 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fpga_div(clk, btnL, btnC, btnR, btnU, btnD, sw, led, seg, an, dp);
  parameter NEXP = 5;
  parameter NSIG = 10;
  `include "ieee-754-flags.vh"
  input clk, btnL, btnC, btnR, btnU, btnD;
  input [NEXP+NSIG:0] sw;
  output [NEXP+NSIG:0] led;
  output [0:6] seg;
  output [3:0] an;
  output dp;

  wire one_second_clock;

  localparam CRYSTAL = 100 ; // 100 MHZ
  localparam NUM_SEC = 1 ;
  localparam STOPAT = (CRYSTAL * 500_000 * NUM_SEC) - 1 ;
  localparam C = 33; //32..0 counter
  wire [C-1:0] big_counter ;

  wire [NEXP+NSIG:0] dividend, divisor; // Operands
  wire [NRAS:0] ra;                     // Rounding Attribute
  wire [NEXP+NSIG:0] q;                 // Quotient Return Value
  wire [NTYPES-1:0] qFlags;             // Type of return value: sNaN, qNaN, Infinity,
  wire [NEXCEPTIONS-1:0] exception;     // Which exceptions were signalled?

  // Generate 190 Hz clock signal
  wire clk190;
  reg [30:0] counter;
  always @(posedge clk)
    begin
      if (clk)
        counter = counter + 1;
    end
  assign clk190 = counter[18];

  // Generate a single clock pulse to latch data into register
  wire raWE, dividendWE, divisorWE, reset;
  pulse U0(clk190, btnC, raWE);
  pulse U1(clk190, btnL, dividendWE);
  pulse U2(clk190, btnR, divisorWE);
  pulse U3(clk190, btnD, reset);

  register #(1+NRAS, 1<<roundTiesToEven) U4(clk190, reset, raWE, sw[NRAS:0], ra);
  register #(1+NEXP+NSIG, 16'h5D8C) U5(clk190, reset, dividendWE, sw, dividend);
  register #(1+NEXP+NSIG, 16'h5710) U6(clk190, reset, divisorWE, sw, divisor);

  clockDivider #(C,STOPAT) U7(clk, 1'b0, big_counter, one_second_clock) ;

  // Debounce reset signal
  wire cleanBtnU, start;
  debounce U8(clk190, btnU, cleanBtnU);
  pulseFE U9(one_second_clock, cleanBtnU, start);

  wire done;
  // clk, start, a, b, ra, q, qFlags, exception, done
  fp_div #(NEXP,NSIG) U10(.clk(one_second_clock),
                          .start(start),
                          .a(dividend),
                          .b(divisor),
                          .ra(ra),
                          .q(q),
                          .qFlags(qFlags),
                          .exception(exception),
                          .done(done));

  x7segb U11(q, clk, start, seg, an);

  assign led = {one_second_clock,                // State Machine Clock
                done,                            // Done Pulse
                start,                           // Start Pulse
                btnU,                            // Start Button
                reset|dividendWE|raWE|divisorWE, // Register Latch Pulse
                btnD,                            // Reset Default Register Values
                btnL,                            // Set Dividend
                btnC,                            // Set Rounding Attribute
                btnR,                            // Set Divisor
                1'b0,                            // Unused
                1'b0,                            // Unused
                exception};                      // Inexact
                                                 // Underflow
                                                 // Overflow
                                                 // Divide by Zero
                                                 // Invalid

endmodule
