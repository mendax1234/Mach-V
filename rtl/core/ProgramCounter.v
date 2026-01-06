/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   ProgramCounter
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Program Counter Register.
--                Holds the current instruction address. Updates on rising clock edge
--                unless stalled. Resets to PC_INIT.
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module ProgramCounter #(
    parameter PC_INIT = 32'h00400000
) (
    input             CLK,
    input             RESET,
    input             StallF,  // stall signal for fetch stage
    input      [31:0] PC_IN,
    output reg [31:0] PC
);

    initial begin
        PC <= PC_INIT;
    end

    always @(posedge CLK) begin
        if (RESET) PC <= PC_INIT;
        else if (~StallF) PC <= PC_IN;
    end

endmodule
