/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   pipeline_M
-- Project Name:  Mach-V
-- Description:   EX/MEM Pipeline Register. 
--                Latches calculated results and control signals from the Execute 
--                stage to be used in the Memory stage.
-- 
-- Credits:       First version created by Hieu.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module pipeline_M (
        // --------------------
        // Clock / Reset / Flow
        // --------------------
        input             CLK,
        input             RESET,
        input             Busy,
        input             FlushM,
        input             BranchMispredictM,

        // --------------------
        // PIPELINE 1 - EX -> MEM inputs
        // --------------------
        input             RegWriteE_1,
        input             MemtoRegE_1,
        input             MemWriteE_1,
        input      [31:0] ComputeResultE_1,
        input      [31:0] WriteDataE_1,
        input      [ 4:0] rs2E_1,
        input      [ 4:0] rdE_1,
        input      [ 2:0] Funct3E_1,
        input      [31:0] RD1E_Forwarded_1,
        input      [31:0] PCE,
        input      [31:0] ExtImmE_1,
        input      [ 1:0] PCSE,
        input      [ 2:0] ALUFlagsE_1,
        input             PrPCSrcE,
        input      [31:0] PrBTAE,

        // --------------------
        // PIPELINE 1 - MEM outputs (registered)
        // --------------------
        output reg        RegWriteM_1,
        output reg        MemtoRegM_1,
        output reg        MemWriteM_1,
        output reg [ 2:0] Funct3M_1,
        output reg [31:0] ComputeResultM_1,
        output reg [31:0] WriteDataM_1,
        output reg [ 4:0] rs2M_1,
        output reg [ 4:0] rdM_1,
        output reg [31:0] RD1M_1,
        output reg [31:0] PCM,
        output reg [31:0] ExtImmM_1,
        output reg [ 1:0] PCSM,
        output reg [ 2:0] ALUFlagsM_1,
        output reg        PrPCSrcM,
        output reg [31:0] PrBTAM,

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
        output            RegWriteM_2,
        output            MemWriteM_2,
        output reg [ 2:0] Funct3M_2,
        output reg [31:0] ComputeResultM_2,
        output reg [31:0] WriteDataM_2,
        output reg [ 4:0] rs2M_2,
        output reg [ 4:0] rdM_2
    );

    // Internal registers to hold the actual latched state
    reg RegWriteM_2_internal;
    reg MemWriteM_2_internal;

    // Combinationally squash the outputs instantly on a mispredict
    assign RegWriteM_2 = RegWriteM_2_internal & ~BranchMispredictM;
    assign MemWriteM_2 = MemWriteM_2_internal & ~BranchMispredictM;

    always @(posedge CLK) begin
        if (RESET || FlushM) begin
            RegWriteM_1 <= 1'b0;
            MemtoRegM_1 <= 1'b0;
            MemWriteM_1 <= 1'b0;
            Funct3M_1 <= 3'b0;
            ComputeResultM_1 <= 32'b0;
            WriteDataM_1 <= 32'b0;
            rs2M_1 <= 5'b0;
            rdM_1 <= 5'b0;
            RD1M_1 <= 32'b0;
            PCM <= 32'b0;
            ExtImmM_1 <= 32'b0;
            PCSM <= 2'b0;
            ALUFlagsM_1 <= 3'b0;
            PrPCSrcM <= 1'b0;
            PrBTAM <= 32'b0;

            RegWriteM_2_internal <= 1'b0;
            MemWriteM_2_internal <= 1'b0;
            Funct3M_2 <= 3'b0;
            ComputeResultM_2 <= 32'b0;
            WriteDataM_2 <= 32'b0;
            rs2M_2 <= 5'b0;
            rdM_2 <= 5'b0;
        end
        else if (~Busy) begin
            RegWriteM_1 <= RegWriteE_1;
            MemtoRegM_1 <= MemtoRegE_1;
            MemWriteM_1 <= MemWriteE_1;
            Funct3M_1 <= Funct3E_1;
            ComputeResultM_1 <= ComputeResultE_1;
            WriteDataM_1 <= WriteDataE_1;
            rs2M_1 <= rs2E_1;
            rdM_1 <= rdE_1;
            RD1M_1 <= RD1E_Forwarded_1;
            PCM <= PCE;
            ExtImmM_1 <= ExtImmE_1;
            PCSM <= PCSE;
            ALUFlagsM_1 <= ALUFlagsE_1;
            PrPCSrcM <= PrPCSrcE;
            PrBTAM <= PrBTAE;

            RegWriteM_2_internal <= RegWriteE_2;
            MemWriteM_2_internal <= MemWriteE_2;
            Funct3M_2 <= Funct3E_2;
            ComputeResultM_2 <= ComputeResultE_2;
            WriteDataM_2 <= WriteDataE_2;
            rs2M_2 <= rs2E_2;
            rdM_2 <= rdE_2;
        end
    end
endmodule
