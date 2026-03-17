/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-03-17
-- Module Name:   pipeline_E_2
-- Project Name:  Mach-V
-- Description:   ID/EX Pipeline Register 2. 
--                Latches control and data signals from the Decode stage to be 
--                used in the Execute stage. Handles flushing and stalling.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

module pipeline_E_2 (
        // --------------------
        // Clock / Reset / Flow
        // --------------------
        input             CLK,
        input             RESET,
        input             Busy,
        input             FlushE,

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
        end
        else if (~Busy) begin
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
