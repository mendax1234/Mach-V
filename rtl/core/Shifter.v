/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   Shifter
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Barrel Shifter for RISC-V.
--                Performs Shift Left Logical (SLL), Shift Right Logical (SRL), 
--                and Shift Right Arithmetic (SRA).
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module Shifter (
        input  [ 1:0] Sh,
        input  [ 4:0] Shamt5,
        input  [31:0] ShIn,
        output [31:0] ShOut
    );

    wire [31:0] ShTemp0;
    wire [31:0] ShTemp1;
    wire [31:0] ShTemp2;
    wire [31:0] ShTemp3;
    wire [31:0] ShTemp4;

    assign ShTemp0 = ShIn;
    shiftByNPowerOf2 #(0) shiftBy0PowerOf2 (
                         Sh,
                         Shamt5[0],
                         ShTemp0,
                         ShTemp1
                     );
    shiftByNPowerOf2 #(1) shiftBy1PowerOf2 (
                         Sh,
                         Shamt5[1],
                         ShTemp1,
                         ShTemp2
                     );
    shiftByNPowerOf2 #(2) shiftBy2PowerOf2 (
                         Sh,
                         Shamt5[2],
                         ShTemp2,
                         ShTemp3
                     );
    shiftByNPowerOf2 #(3) shiftBy3PowerOf2 (
                         Sh,
                         Shamt5[3],
                         ShTemp3,
                         ShTemp4
                     );
    shiftByNPowerOf2 #(4) shiftBy4PowerOf2 (
                         Sh,
                         Shamt5[4],
                         ShTemp4,
                         ShOut
                     );


endmodule


module shiftByNPowerOf2
    //module Shifter
    #(
         parameter i = 0
     )  // exponent
     (
         input      [ 1:0] Sh,
         input             flagShift,
         input      [31:0] ShTempIn,
         output reg [31:0] ShTempOut
     );

    always @(Sh, ShTempIn, flagShift) begin
        if (flagShift)
        case (Sh)
            2'b00:
                ShTempOut = {ShTempIn[31-2**i:0], {2 ** i{1'b0}}};  // SLL
            2'b10:
                ShTempOut = {{2 ** i{1'b0}}, ShTempIn[31:2**i]};  // SRL
            2'b11:
                ShTempOut = {{2 ** i{ShTempIn[31]}}, ShTempIn[31:2**i]};  // SRA
            //2'b01: ShTempOut = { ShTempIn[2**i-1:0], ShTempIn[31:2**i] } ;  	// ROR is not supported by RISC-V
            default:
                ShTempOut = ShTempIn;  // invalid
        endcase
        else
            ShTempOut = ShTempIn;
    end

endmodule
