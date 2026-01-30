/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   pipeline_W
-- Project Name:  Mach-V
-- Description:   MEM/WB Pipeline Register. 
--                Latches memory read data and ALU results from the Memory stage 
--                to be written back to registers in the Writeback stage.
-- 
-- Credits:       First version created by Hieu.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module pipeline_W (
    input             CLK,
    input             RESET,
    input             RegWriteM,
    input             MemtoRegM,
    input      [31:0] ReadDataM,
    input      [31:0] ComputeResultM,
    input      [ 4:0] rdM,
    input      [ 2:0] Funct3M,
    output reg        RegWriteW,
    output reg        MemtoRegW,
    output reg [31:0] ReadDataW,
    output reg [31:0] ComputeResultW,
    output reg [ 4:0] rdW,
    output reg [ 2:0] Funct3W
);

    always @(posedge CLK)
        if (RESET) begin
            RegWriteW <= 1'b0;
            MemtoRegW <= 1'b0;
            ReadDataW <= 32'b0;
            ComputeResultW <= 32'b0;
            rdW <= 5'b0;
            Funct3W <= 2'b0;
        end else begin  // do not stall M/W stage for MCycle
            RegWriteW <= RegWriteM;
            MemtoRegW <= MemtoRegM;
            ReadDataW <= ReadDataM;
            ComputeResultW <= ComputeResultM;
            rdW <= rdM;
            Funct3W <= Funct3M;
        end

endmodule
