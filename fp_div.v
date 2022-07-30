`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2022 
// Engineer: 
// 
// Create Date: 07/09/2022 03:11:29 AM
// Design Name: 
// Module Name: fp_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Floating Point Division State Machine
//              To begin execution `start' must be high on the rising edge of the
//              clock (`clk') signal.
//              Actual division takes NSIG+5 clock cycles.
//              Exceptional cases (NaNs, Infinities, Zeroes) take 2 cycles.
//              The result has been computed and output on `q' module will
//              assert the `done' signal. The `done' signal can be used to clock
//              the result into a register.
//
// Inputs:
// o clk -- clock signal; used to drive the state machine.
// o start -- single pulse to signal that the a, b, and ra input values are
//            available, and computation needs to begin.
// o a -- dividend
// o b -- divisor
// o ra - rounding attribute; one, and only one, of the flags roundTiesToEven,
//        roundTowardZero, roundTowardPositive, and roundTowardNegative is
//        allowed to be set at any given time. At least one of the flags must be
//        set to valid.
//
// Outputs:
// o q -- quotient
// o qFlags -- bit vector which specifies the quotient's type: sNaN, qNaN,
//             Infinity, Zero, Normal, or Subnormal.
// o exception -- bit vector specifying which, if any, exceptions occurred during
//                execution.
// o done -- pulse to signal that the results are ready on the output lines.
// 
// Dependencies: fp_class.v, round.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fp_div(clk, start, a, b, ra, q, qFlags, exception, done);
  parameter NEXP = 5;
  parameter NSIG = 10;
  `include "ieee-754-flags.vh"
  localparam CLOG2_NSIG = $clog2(NSIG+1);
  input clk, start;
  input [NEXP+NSIG:0] a, b;
  input [NRAS:0] ra;
  output [NEXP+NSIG:0] q=0;
  reg [NEXP+NSIG:0] q;
  output [NTYPES-1:0] qFlags;
  reg [NTYPES-1:0] qFlags;
  output [NEXCEPTIONS-1:0] exception; // Which exceptions were signalled?
  reg [NEXCEPTIONS-1:0] exception = 0;
  output done;
  reg done;

  reg [CLOG2_NSIG-1:0] counter = 0;
  
  // Extract fields of the dividend and divisor.
  wire signed [NEXP+1:0] aExp, bExp;
  wire [NSIG:0] aSigWire, bSigWire;
  wire [NTYPES-1:0] aFlags, bFlags;
  fp_class #(NEXP,NSIG) aClass(a, aExp, aSigWire, aFlags);
  fp_class #(NEXP,NSIG) bClass(b, bExp, bSigWire, bFlags);

  // Compute sign of quotient.
  wire qSign = a[NEXP+NSIG]^b[NEXP+NSIG];

  // Input/Output values for rounding module. The rounding module also
  // uses {qSig, aSig} as the sigIn value.
  reg signed [NEXP+1:0] normExp, expIn, qExp;
  wire signed [NEXP+1:0] expOut;
  wire [NSIG:0] sigOut;
  wire inexact;

  // qSig is the temporary value used to calculate qSig in the main
  // always block.
  reg [NSIG+2:0] qSig;

  // Special cases only require one additional clock cycle to complete.
  // This may change in the future.
  localparam SPECIAL_CYCLE_COUNT = 1;
  // This value gives us enough extra cycles to compute enough of
  // the quotient significand to ensure that the first truncated
  // bit (the MSB of y bar) is computed exactly. There are two extra
  // cycles needed to renormalize the quotient significand (if needed),
  // round the result, and construct the final return value.
  localparam DIVIDE_CYCLE_COUNT = NSIG+4;

  // Register used when rounding infinities.
  reg si;

  // aSig is the portion of the dividend which hasn't yet been processed.
  // bSig is the zero-extended divisor
  // rSig is our guess for the next value of aSig. If rSig is negative
  // our guess was wrong and we reuse the current aSig.
  reg signed [NSIG+2:0] aSig, bSig, rSig;
  
  // This flag, when true, says we're processing a special case which
  // doesn't require performing an actual division.
  reg special = 0;

  // Main body of division logic. This does all of the work of
  // constructing the return value.
  always @(posedge clk) begin
    // All of the exception cases finish in a single cycle
    // This value only gets set to a positive number for the
    // case that we actually have to perform long division.
    if (start)
      begin
        // Special cases, that is, cases for which no long division is
        // performed are treated as the default. Long division is expected
        // to be the most common case but, because there are multiple
        // special cases, it's simpler to treat the special cases as the
        // default. There's only one case which isn't a special case and
        // it's simpler to disable the `special' flag in that one place,
        // and change the counter value in that one place than it is to
        // set the special flag, and the counter in the multitude of
        // special cases. It's also less likely to create bugs if/when
        // changes to the code are made in the future.
        special = 1; // Flag to say that we're doing a special case
        counter = SPECIAL_CYCLE_COUNT;

        // Initialize all of the output variables.
        qFlags = 0;
        q = 0;
        exception = 0;
        
        casex(aFlags | bFlags)
          // For the cases where one, or both, of the operands is a NaN,
          // return the NaN. If one of the operands is an sNaN and the
          // other is a qNaN return the sNaN.
          6'b1xxxxx: begin
              {q, qFlags} = aFlags[SNAN] ? {a, aFlags} : {b, bFlags};
              exception[INVALID] = 1;
            end
          6'b01xxxx: {q, qFlags} = aFlags[QNAN] ? {a, aFlags} : {b, bFlags};
          // Both of the operands are Infinity.
          6'b001000: begin
              qFlags[QNAN] = 1;
              q = {qSign, {NEXP+NSIG{1'b1}}};
              exception[INVALID] = 1;
            end
          // One finite operand and the other is Infinity.
          6'b001xxx: begin
              if (aFlags[INFINITY]) // Dividend is Infinity. Divisor is finite.
                begin
                  si = ra[roundTowardZero] |
                      (ra[roundTowardNegative] & ~qSign) |
                      (ra[roundTowardPositive] &  qSign);
                  q = {qSign, {NEXP-1{1'b1}}, ~si, {NSIG{si}}};
                  qFlags[INFINITY] = ~si;
                  qFlags[NORMAL]   =  si;
                  exception[OVERFLOW] = 1;
                end
              else // Dividend is finite. Divisor is Infinity.
                begin
                   qFlags[ZERO] = 1;
                   q = {qSign, {NEXP+NSIG{1'b0}}};
                end
            end
          // Both operands are Zero.
          6'b000100: begin
              qFlags[QNAN] = 1;
              q = {qSign, {NEXP+NSIG{1'b1}}};
              exception[INVALID] = 1;
            end
          // One operand is Zero, the other is Normal/Subnormal.
          6'b0001xx: begin
              if (aFlags[ZERO]) // Dividend is zero. Divisor is non-zero.
                begin
                  qFlags[ZERO] = 1;
                  q = {qSign, {NEXP+NSIG{1'b0}}};
                end
              else // Dividend is non-zero. Divisor is zero.
                begin
                  si = ra[roundTowardZero] |
                      (ra[roundTowardNegative] & ~qSign) |
                      (ra[roundTowardPositive] &  qSign);
                  q = {qSign, {NEXP-1{1'b1}}, ~si, {NSIG{si}}};
                  qFlags[INFINITY] = ~si;
                  qFlags[NORMAL]   =  si;
                  exception[DIVIDEBYZERO] = 1;
                end
            end
          // Both operands are Normal/Subnormal numbers and we need to
          // actually perform division.
          default: begin
              // Override the assumption made at the top of the always
              // block that all of the cases are special cases.
              special = 0;
              counter = DIVIDE_CYCLE_COUNT;

              // Initialize working registers.
              qSig = 0;
              aSig = {2'b00, aSigWire};
              bSig = {2'b00, bSigWire};
              normExp = 0;

              // Compute first bit of quotient significand.
              rSig = aSig - bSig;
              qSig = {qSig[NSIG+1:0], ~rSig[NSIG+2]};
              aSig = {(rSig[NSIG+2] ? aSig[NSIG+1:0] : rSig[NSIG+1:0]), 1'b0};

              q = {3'b000, qSig}; // Show user what has been computed, so far.
            end
        endcase
      end
    else if (counter > 2)
      begin
        // Compute next bit of quotient significand.
        counter = counter - 1;
                
        rSig = aSig - bSig;
        qSig = {qSig[NSIG+1:0], ~rSig[NSIG+2]};
        aSig = {(rSig[NSIG+2] ? aSig[NSIG+1:0] : rSig[NSIG+1:0]), 1'b0};

        q = {3'b000, qSig}; // Show user what has been computed, so far.
      end
    else if (counter > 1)
      begin
        // If needed, renormalize quotient significand, and adjust
        // the quotient exponent in preparation for rounding the
        // result.
        counter = counter - 1;
        
        normExp[0] = ~qSig[NSIG+2];
        expIn = aExp - bExp - normExp;
        qSig = qSig << ~qSig[NSIG+2];

        q = {3'b000, qSig}; // Show user what has been computed, so far.
      end
    else if (counter > 0)
      begin
        // Construct return value from rounded results.
        counter = counter - 1;
        
        // Only construct a return value if this is not a special case.
        if (~special)
          begin
            if (~|sigOut) // Zero
              begin
                qFlags[ZERO] = 1;
                q = {ra[roundTowardNegative], {NEXP+NSIG{1'b0}}};
                exception[UNDERFLOW] = 1;
              end
            else if (expOut < EMIN) // Subnormal
              begin
                qFlags[SUBNORMAL] = 1;
                q = {qSign, {NEXP{1'b0}}, sigOut[NSIG:1]};
              end
            else if (expOut > EMAX) // Infinity
              begin
                si = ra[roundTowardZero] |
                    (ra[roundTowardNegative] & ~qSign) |
                    (ra[roundTowardPositive] &  qSign);
                q = {qSign, {NEXP-1{1'b1}}, ~si, {NSIG{si}}};
                qFlags[INFINITY] = ~si;
                qFlags[NORMAL]   =  si;
                exception[OVERFLOW] = 1;
                exception[INEXACT] = 1;
              end
            else // Normal
              begin
                qFlags[NORMAL] = 1;
                qExp = expOut + BIAS;

                q = {qSign, qExp[NEXP-1:0], sigOut[NSIG-1:0]};
              end

            exception[INEXACT] = exception[INEXACT] | inexact;
          end
        
        special = 0;
      end
  end

  round #(2*NSIG+6, NEXP, NSIG) U0(qSign, expIn, {qSig, aSig}, ra,
                                   expOut, sigOut, inexact);

  // Logic to generate `done' signal. This signal lets the rest of
  // the system know that the computation is complete.
  reg running = 0;

  always @(negedge clk) begin
    if (counter > 0)
      begin
        running <= 1;
        done <= 0;
      end
    else if (running)
      begin
        running <= 0;
        done <= 1;
      end
    else
      done <=0;
  end
endmodule
