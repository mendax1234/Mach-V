/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   pipeline_E
-- Project Name:  Mach-V
-- Description:   ID/EX Pipeline Register. 
--                Latches control and data signals from the Decode stage to be 
--                used in the Execute stage. Handles flushing and stalling.
-- 
-- Credits:       First version created by Hieu.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module pipeline_E (
        // --------------------
        // Clock / Reset / Flow
        // --------------------
        input             CLK,
        input             RESET,
        input             Busy,
        input             FlushE,

        // --------------------
        // PIPELINE 1 - Decode -> EX inputs
        // --------------------
        input      [ 1:0] PCSD,
        input             RegWriteD_1,
        input             MemtoRegD_1,
        input             MemWriteD_1,
        input      [ 3:0] ALUControlD_1,
        input      [ 1:0] ALUSrcAD_1,
        input      [ 1:0] ALUSrcBD_1,
        input      [31:0] RD1D_1,
        input      [31:0] RD2D_1,
        input      [31:0] ExtImmD_1,
        input      [ 4:0] rs1D_1,
        input      [ 4:0] rs2D_1,
        input      [ 4:0] rdD_1,
        input      [31:0] PCD_1,
        input      [ 2:0] Funct3D_1,
        input      [ 1:0] MCycleOpD,
        input             MCycleStartD,
        input             MCycleResultSelD,
        input             ComputeResultSelD,
        input             PrPCSrcD,
        input      [31:0] PrBTAD,

        // --------------------
        // PIPELINE 1 - EX outputs (registered)
        // --------------------
        output reg [ 1:0] PCSE,
        output reg        RegWriteE_1,
        output reg        MemtoRegE_1,
        output reg        MemWriteE_1,
        output reg [ 3:0] ALUControlE_1,
        output reg [ 1:0] ALUSrcAE_1,
        output reg [ 1:0] ALUSrcBE_1,
        output reg [31:0] RD1E_1,
        output reg [31:0] RD2E_1,
        output reg [31:0] ExtImmE_1,
        output reg [ 4:0] rs1E_1,
        output reg [ 4:0] rs2E_1,
        output reg [ 4:0] rdE_1,
        output reg [31:0] PCE_1,
        output reg [ 2:0] Funct3E_1,
        output reg [ 1:0] MCycleOpE,
        output reg        MCycleStartE,
        output reg        MCycleResultSelE,
        output reg        ComputeResultSelE,
        output reg        PrPCSrcE,
        output reg [31:0] PrBTAE,

        // --------------------
        // PIPELINE 2 - Decode -> EX inputs
        // --------------------
        input             RegWriteD_2,
        input             MemWriteD_2,
        input      [ 2:0] Funct3D_2,
        input      [ 3:0] ALUControlD_2,
        input      [ 1:0] ALUSrcAD_2,
        input      [ 1:0] ALUSrcBD_2,
        input      [31:0] RD1D_2,
        input      [31:0] RD2D_2,
        input      [31:0] ExtImmD_2,
        input      [ 4:0] rs1D_2,
        input      [ 4:0] rs2D_2,
        input      [ 4:0] rdD_2,
        input      [31:0] PCD_2,

        // --------------------
        // PIPELINE 2 - EX outputs (registered)
        // --------------------
        output reg        RegWriteE_2,
        output reg        MemWriteE_2,
        output reg [ 2:0] Funct3E_2,
        output reg [ 3:0] ALUControlE_2,
        output reg [ 1:0] ALUSrcAE_2,
        output reg [ 1:0] ALUSrcBE_2,
        output reg [31:0] RD1E_2,
        output reg [31:0] RD2E_2,
        output reg [31:0] ExtImmE_2,
        output reg [ 4:0] rs1E_2,
        output reg [ 4:0] rs2E_2,
        output reg [ 4:0] rdE_2,
        output reg [31:0] PCE_2
    );
    always @(posedge CLK) begin
        if (RESET || FlushE) begin
            PCSE <= 2'b0;
            RegWriteE_1 <= 1'b0;
            MemtoRegE_1 <= 1'b0;
            MemWriteE_1 <= 1'b0;
            ALUControlE_1 <= 4'b0;
            ALUSrcAE_1 <= 2'b0;
            ALUSrcBE_1 <= 2'b0;
            RD1E_1 <= 32'b0;
            RD2E_1 <= 32'b0;
            ExtImmE_1 <= 32'b0;
            rs1E_1 <= 5'b0;
            rs2E_1 <= 5'b0;
            rdE_1 <= 5'b0;
            PCE_1 <= 32'b0;
            Funct3E_1 <= 3'b0;
            MCycleOpE <= 2'b0;
            MCycleStartE <= 1'b0;
            MCycleResultSelE <= 1'b0;
            ComputeResultSelE <= 1'b0;
            PrPCSrcE <= 1'b0;
            PrBTAE <= 32'b0;

            RegWriteE_2 <= 1'b0;
            MemWriteE_2 <= 1'b0;
            Funct3E_2 <= 3'b0;
            ALUControlE_2 <= 4'b0;
            ALUSrcAE_2 <= 2'b0;
            ALUSrcBE_2 <= 2'b0;
            RD1E_2 <= 32'b0;
            RD2E_2 <= 32'b0;
            ExtImmE_2 <= 32'b0;
            rs1E_2 <= 5'b0;
            rs2E_2 <= 5'b0;
            rdE_2 <= 5'b0;
            PCE_1 <= 32'b0;
        end
        else if (~Busy) begin
            PCSE <= PCSD;
            RegWriteE_1 <= RegWriteD_1;
            MemtoRegE_1 <= MemtoRegD_1;
            MemWriteE_1 <= MemWriteD_1;
            ALUControlE_1 <= ALUControlD_1;
            ALUSrcAE_1 <= ALUSrcAD_1;
            ALUSrcBE_1 <= ALUSrcBD_1;
            RD1E_1 <= RD1D_1;
            RD2E_1 <= RD2D_1;
            ExtImmE_1 <= ExtImmD_1;
            rs1E_1 <= rs1D_1;
            rs2E_1 <= rs2D_1;
            rdE_1 <= rdD_1;
            PCE_1 <= PCD_1;
            Funct3E_1 <= Funct3D_1;
            MCycleOpE <= MCycleOpD;
            MCycleStartE <= MCycleStartD;
            MCycleResultSelE <= MCycleResultSelD;
            ComputeResultSelE <= ComputeResultSelD;
            PrPCSrcE <= PrPCSrcD;
            PrBTAE <= PrBTAD;

            RegWriteE_2 <= RegWriteD_2;
            MemWriteE_2 <= MemWriteD_2;
            Funct3E_2 <= Funct3D_2;
            ALUControlE_2 <= ALUControlD_2;
            ALUSrcAE_2 <= ALUSrcAD_2;
            ALUSrcBE_2 <= ALUSrcBD_2;
            RD1E_2 <= RD1D_2;
            RD2E_2 <= RD2D_2;
            ExtImmE_2 <= ExtImmD_2;
            rs1E_2 <= rs1D_2;
            rs2E_2 <= rs2D_2;
            rdE_2 <= rdD_2;
            PCE_2 <= PCD_2;
        end
    end
endmodule
