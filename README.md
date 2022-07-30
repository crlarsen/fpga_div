# Verilog IEEE 754 State Machine Division Module

## Description

Second version of the floating point division module. No optimization.

The repository includes a simulation testbench (fp_div_tb.v), and a test harness for
running the code on a Digilent BASYS 3 board (fpga_div.v).

The code is explained in the video series [Building an FPU in Verilog](https://www.youtube.com/watch?v=rYkVdJnVJFQ&list=PLlO9sSrh8HrwcDHAtwec1ycV-m50nfUVs).
See the video *Building an FPU in Verilog: Dividing Floating Point Numbers, Part 2*.

## Manifest

|   Filename        |                        Description                           |
|-------------------|--------------------------------------------------------------|
| README.md         | This file.                                                   |
| clockDivider.v    | Used to divide the board's 100MHz clock signal down so that the execution of the state machine can be observed. |
| fp_class.sv       | Utility module to identify the type of the IEEE 754 value passed in, and extract the exponent & significand fields for use by other modules. |
| fp_div.v          | State machine circuit to compute floating point division.    |
| fp_div_tb.v       | Simulation testbench for division circuit.                              |
| fpga_div.v        | FPGA test harness.                                           |
| ieee-754-flags.vh | Verilog header file to define constants for datum type (NaN, Infinity, Zero, Subnormal, and Normal), rounding attributes, and IEEE exceptions. |
| debounce.v        | Module to "debounce" FPGA board push buttons.                |
| hex2_7seg.v       | Module to convert 16-bit binary numbers to the appropriate encoding for display on a 7-segment LED. |
| padder11.v        | Prefix adder used by round module.                           |
| padder113.v       | Prefix adder used by round module.                           |
| padder24.v        | Prefix adder used by round module.                           |
| padder53.v        | Prefix adder used by fp_div module.                          |
| PijGij.v          | Utility routines needed by the various prefix adder modules. |
| pulse.v           | Utility to convert a push button signal into a 1 clock cycle pulse. |
| register.v        | Generic module for creating registers. Both the width of the register in bits, and the default/reset value for the register are parameterized. |
| round.v           | Parameterized rounding module.                               |
| x7seg.v | Collection of modules to multiplex data onto the 4-digit, 7-segment display on a BASYS 3 board. |

## Copyright

:copyright: Chris Larsen, 2019-2022
