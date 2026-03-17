/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   pipeline_W_1
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

module pipeline_W_1 (
        input             CLK,
        input             RESET,

        // --- PIPELINE 1 ---
        input             RegWriteM_1,
        input             MemtoRegM_1,
        input      [31:0] ReadDataM_1,
        input      [31:0] ComputeResultM_1,
        input      [ 4:0] rdM_1,
        input      [ 2:0] Funct3M_1,

        output reg        RegWriteW_1,
        output reg        MemtoRegW_1,
        output reg [31:0] ReadDataW_1,
        output reg [31:0] ComputeResultW_1,
        output reg [ 4:0] rdW_1,
        output reg [ 2:0] Funct3W_1
    );
    always @(posedge CLK) begin
        if (RESET) begin
            RegWriteW_1 <= 1'b0;
            MemtoRegW_1 <= 1'b0;
            ReadDataW_1 <= 32'b0;
            ComputeResultW_1 <= 32'b0;
            rdW_1 <= 5'b0;
            Funct3W_1 <= 3'b0;
        end
        else begin
            RegWriteW_1 <= RegWriteM_1;
            MemtoRegW_1 <= MemtoRegM_1;
            ReadDataW_1 <= ReadDataM_1;
            ComputeResultW_1 <= ComputeResultM_1;
            rdW_1 <= rdM_1;
            Funct3W_1 <= Funct3M_1;
        end
    end
endmodule
