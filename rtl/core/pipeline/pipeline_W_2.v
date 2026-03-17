/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-03-17
-- Module Name:   pipeline_W_w
-- Project Name:  Mach-V
-- Description:   MEM/WB Pipeline Register. 
--                Latches memory read data and ALU results from the Memory stage 
--                to be written back to registers in the Writeback stage.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

module pipeline_W_2(
        input             CLK,
        input             RESET,

        // --- PIPELINE 2 ---
        input             RegWriteM_2,
        input      [31:0] ComputeResultM_2,
        input      [ 4:0] rdM_2,

        output reg        RegWriteW_2,
        output reg [31:0] ComputeResultW_2,
        output reg [ 4:0] rdW_2
    );
    always @(posedge CLK) begin
        if (RESET) begin
            RegWriteW_2 <= 1'b0;
            ComputeResultW_2 <= 32'b0;
            rdW_2 <= 5'b0;
        end
        else begin
            RegWriteW_2 <= RegWriteM_2;
            ComputeResultW_2 <= ComputeResultM_2;
            rdW_2 <= rdM_2;
        end
    end
endmodule
