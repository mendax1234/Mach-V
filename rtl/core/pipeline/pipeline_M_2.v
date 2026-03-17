/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-03-17
-- Module Name:   pipeline_M_2
-- Project Name:  Mach-V
-- Description:   EX/MEM Pipeline Register 1. 
--                Latches calculated results and control signals from the Execute 
--                stage to be used in the Memory stage.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

module pipeline_M_2(
        // --------------------
        // Clock / Reset / Flow
        // --------------------
        input             CLK,
        input             RESET,
        input             Busy,
        input             FlushM,

        // --------------------
        // PIPELINE 2 - EX -> MEM inputs
        // --------------------
        input             RegWriteE_2,
        input             MemWriteE_2,
        input      [ 2:0] Funct3E_2,
        input      [31:0] ComputeResultE_2,
        input      [31:0] WriteDataE_2,
        input      [ 4:0] rs2E_2,
        input      [ 4:0] rdE_2,

        // --------------------
        // PIPELINE 2 - MEM outputs (registered)
        // --------------------
        output reg        RegWriteM_2,
        output reg        MemWriteM_2,
        output reg [ 2:0] Funct3M_2,
        output reg [31:0] ComputeResultM_2,
        output reg [31:0] WriteDataM_2,
        output reg [ 4:0] rs2M_2,
        output reg [ 4:0] rdM_2
    );
    always @(posedge CLK) begin
        if (RESET || FlushM) begin
            RegWriteM_2 <= 1'b0;
            MemWriteM_2 <= 1'b0;
            Funct3M_2 <= 3'b0;
            ComputeResultM_2 <= 32'b0;
            WriteDataM_2 <= 32'b0;
            rs2M_2 <= 5'b0;
            rdM_2 <= 5'b0;
        end
        else if (~Busy) begin
            RegWriteM_2 <= RegWriteE_2;
            MemWriteM_2 <= MemWriteE_2;
            Funct3M_2 <= Funct3E_2;
            ComputeResultM_2 <= ComputeResultE_2;
            WriteDataM_2 <= WriteDataE_2;
            rs2M_2 <= rs2E_2;
            rdM_2 <= rdE_2;
        end
    end
endmodule
