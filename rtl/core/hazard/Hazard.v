/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   Hazard
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Hazard Handling Unit for Mach-V RISC-V Processor.
--                Detects data hazards (Load-Use) and control hazards (Branches),
--                generating the necessary Stall, Flush, and Forwarding signals.
-- 
-- Credits:       First version created by Hieu.
--                Hazard handling concepts and architecture taught in CG3207.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module Hazard (
        // Decode-stage register indices
        input  [4:0] rs1D_1,    // Pipe 1 rs1 (Decode)
        input  [4:0] rs2D_1,    // Pipe 1 rs2 (Decode)
        input  [4:0] rs1D_2,    // Pipe 2 rs1 (Decode)
        input  [4:0] rs2D_2,    // Pipe 2 rs2 (Decode)

        // Decode-stage opcodes
        input  [6:0] OpcodeD_1, // Pipe 1 opcode (Decode)
        input  [6:0] OpcodeD_2, // Pipe 2 opcode (Decode)

        // Execute-stage register indices
        input  [4:0] rs1E_1,    // Pipe 1 rs1 (Execute)
        input  [4:0] rs2E_1,    // Pipe 1 rs2 (Execute)
        input  [4:0] rdE_1,     // Pipe 1 rd  (Execute)
        input  [4:0] rs1E_2,    // Pipe 2 rs1 (Execute)
        input  [4:0] rs2E_2,    // Pipe 2 rs2 (Execute)
        input  [4:0] rdE_2,     // Pipe 2 rd  (Execute)

        // Execute-stage control
        input        MemtoRegE_1, // Load in EX stage (Pipe 1)

        // Memory-stage signals (for store forwarding)
        input  [4:0] rs2M_1,    // Pipe 1 rs2 (Memory - Store)
        input  [4:0] rs2M_2,    // Pipe 2 rs2 (Memory - Store)
        input  [4:0] rdM_1,     // Pipe 1 rd  (Memory)
        input  [4:0] rdM_2,     // Pipe 2 rd  (Memory)
        input        RegWriteM_1,// Pipe 1 RegWrite (Memory)
        input        RegWriteM_2,// Pipe 2 RegWrite (Memory)
        input        MemWriteM_1,// Pipe 1 MemWrite (Memory)
        input        MemWriteM_2,// Pipe 2 MemWrite (Memory)

        // Writeback-stage signals
        input  [4:0] rdW_1,     // Pipe 1 rd  (Writeback)
        input  [4:0] rdW_2,     // Pipe 2 rd  (Writeback)
        input        RegWriteW_1,// Pipe 1 RegWrite (Writeback)
        input        RegWriteW_2,// Pipe 2 RegWrite (Writeback)
        input        MemtoRegW_1,// Pipe 1 MemtoReg (Writeback)
        input        MemtoRegW_2,// Pipe 2 MemtoReg (Writeback)

        // Misc control/status
        input        Busy,              // Multi-cycle unit busy
        input        BranchMispredictM, // Branch mispredict in M stage

        // Forwarding results (Execute stage)
        output reg [2:0] ForwardAE_1, // Select for ALU A (Pipe1)
        output reg [2:0] ForwardBE_1, // Select for ALU B (Pipe1)
        output reg [2:0] ForwardAE_2, // Select for ALU A (Pipe2)
        output reg [2:0] ForwardBE_2, // Select for ALU B (Pipe2)

        // Memory-store forwarding flags
        output          ForwardM_1_W1, // Pipe1 store forwarded from WB1
        output          ForwardM_1_W2, // Pipe1 store forwarded from WB2
        output          ForwardM_2_W1, // Pipe2 store forwarded from WB1
        output          ForwardM_2_W2, // Pipe2 store forwarded from WB2

        // Decode-stage forwarding indicators (for register file bypass)
        output   [1:0]   Forward1D_1, // Pipe1 rs1 forwarded from WB
        output   [1:0]   Forward2D_1, // Pipe1 rs2 forwarded from WB
        output   [1:0]   Forward1D_2, // Pipe2 rs1 forwarded from WB
        output   [1:0]   Forward2D_2, // Pipe2 rs2 forwarded from WB

        // Stall / Flush outputs
        output          lwStall, // Load-use stall
        output          StallF,  // Stall Fetch
        output          StallD,  // Stall Decode
        output          FlushE,  // Flush Execute
        output          FlushD,  // Flush Decode
        output          FlushM   // Flush Memory
    );

    wire rs1_active_1 = (OpcodeD_1 != 7'b1101111) && (OpcodeD_1 != 7'b0110111) && (OpcodeD_1 != 7'b0010111);
    wire rs2_active_1 = rs1_active_1 && (OpcodeD_1 != 7'b0000011) && (OpcodeD_1 != 7'b0010011) && (OpcodeD_1 != 7'b1100111);
    wire rs1_active_2 = (OpcodeD_2 != 7'b1101111) && (OpcodeD_2 != 7'b0110111) && (OpcodeD_2 != 7'b0010111);
    wire rs2_active_2 = rs1_active_2 && (OpcodeD_2 != 7'b0000011) && (OpcodeD_2 != 7'b0010011) && (OpcodeD_2 != 7'b1100111);

    // --- PIPELINE 1 FORWARDING ---
    always @(*) begin
        if      ((rs1E_1 == rdM_2) && RegWriteM_2 && (rdM_2 != 0))
            ForwardAE_1 = 3'd4;
        else if ((rs1E_1 == rdM_1) && RegWriteM_1 && (rdM_1 != 0))
            ForwardAE_1 = 3'd3;
        else if ((rs1E_1 == rdW_2) && RegWriteW_2 && (rdW_2 != 0))
            ForwardAE_1 = 3'd2;
        else if ((rs1E_1 == rdW_1) && RegWriteW_1 && (rdW_1 != 0))
            ForwardAE_1 = 3'd1;
        else
            ForwardAE_1 = 3'd0;
    end
    always @(*) begin
        if      ((rs2E_1 == rdM_2) && RegWriteM_2 && (rdM_2 != 0))
            ForwardBE_1 = 3'd4;
        else if ((rs2E_1 == rdM_1) && RegWriteM_1 && (rdM_1 != 0))
            ForwardBE_1 = 3'd3;
        else if ((rs2E_1 == rdW_2) && RegWriteW_2 && (rdW_2 != 0))
            ForwardBE_1 = 3'd2;
        else if ((rs2E_1 == rdW_1) && RegWriteW_1 && (rdW_1 != 0))
            ForwardBE_1 = 3'd1;
        else
            ForwardBE_1 = 3'd0;
    end

    // --- PIPELINE 2 FORWARDING ---
    always @(*) begin
        if      ((rs1E_2 == rdM_2) && RegWriteM_2 && (rdM_2 != 0))
            ForwardAE_2 = 3'd4;
        else if ((rs1E_2 == rdM_1) && RegWriteM_1 && (rdM_1 != 0))
            ForwardAE_2 = 3'd3;
        else if ((rs1E_2 == rdW_2) && RegWriteW_2 && (rdW_2 != 0))
            ForwardAE_2 = 3'd2;
        else if ((rs1E_2 == rdW_1) && RegWriteW_1 && (rdW_1 != 0))
            ForwardAE_2 = 3'd1;
        else
            ForwardAE_2 = 3'd0;
    end
    always @(*) begin
        if      ((rs2E_2 == rdM_2) && RegWriteM_2 && (rdM_2 != 0))
            ForwardBE_2 = 3'd4;
        else if ((rs2E_2 == rdM_1) && RegWriteM_1 && (rdM_1 != 0))
            ForwardBE_2 = 3'd3;
        else if ((rs2E_2 == rdW_2) && RegWriteW_2 && (rdW_2 != 0))
            ForwardBE_2 = 3'd2;
        else if ((rs2E_2 == rdW_1) && RegWriteW_1 && (rdW_1 != 0))
            ForwardBE_2 = 3'd1;
        else
            ForwardBE_2 = 3'd0;
    end

    // --- MEMORY FORWARDING (Stores) ---
    // Pipe 1 Store checks WB2 first, then WB1
    assign ForwardM_1_W2 = MemWriteM_1 && (rs2M_1 == rdW_2) && RegWriteW_2 && (rs2M_1 != 0);
    assign ForwardM_1_W1 = MemWriteM_1 && (rs2M_1 == rdW_1) && RegWriteW_1 && (rs2M_1 != 0) && !ForwardM_1_W2;

    // Pipe 2 Store checks WB2 first, then WB1
    assign ForwardM_2_W2 = MemWriteM_2 && (rs2M_2 == rdW_2) && RegWriteW_2 && (rs2M_2 != 0);
    assign ForwardM_2_W1 = MemWriteM_2 && (rs2M_2 == rdW_1) && RegWriteW_1 && (rs2M_2 != 0) && !ForwardM_2_W2;

    // 2'b10 = Forward from W_2,  2'b01 = Forward from W_1,  2'b00 = No Forwarding
    assign Forward1D_1 = ((rs1D_1 != 0) && (rs1D_1 == rdW_2) && RegWriteW_2) ? 2'b10 :
           ((rs1D_1 != 0) && (rs1D_1 == rdW_1) && RegWriteW_1) ? 2'b01 : 2'b00;

    assign Forward2D_1 = ((rs2D_1 != 0) && (rs2D_1 == rdW_2) && RegWriteW_2) ? 2'b10 :
           ((rs2D_1 != 0) && (rs2D_1 == rdW_1) && RegWriteW_1) ? 2'b01 : 2'b00;

    assign Forward1D_2 = ((rs1D_2 != 0) && (rs1D_2 == rdW_2) && RegWriteW_2) ? 2'b10 :
           ((rs1D_2 != 0) && (rs1D_2 == rdW_1) && RegWriteW_1) ? 2'b01 : 2'b00;

    assign Forward2D_2 = ((rs2D_2 != 0) && (rs2D_2 == rdW_2) && RegWriteW_2) ? 2'b10 :
           ((rs2D_2 != 0) && (rs2D_2 == rdW_1) && RegWriteW_1) ? 2'b01 : 2'b00;

    assign lwStall = MemtoRegE_1 && (rdE_1 != 0) && (
               ((rs1D_1 == rdE_1) && rs1_active_1) || ((rs2D_1 == rdE_1) && rs2_active_1) ||
               ((rs1D_2 == rdE_1) && rs1_active_2) || ((rs2D_2 == rdE_1) && rs2_active_2)
           );

    assign StallF = (lwStall | Busy) & ~BranchMispredictM;
    assign StallD = (lwStall | Busy) & ~BranchMispredictM;
    assign FlushE = lwStall | BranchMispredictM;
    assign FlushD = BranchMispredictM;
    assign FlushM = BranchMispredictM;
endmodule
