`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: RISC-V Processor Decoder Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Interface and implementation can be modified.
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file as well as any files derived from this.
----------------------------------------------------------------------------------
*/

module Decoder (
    input [6:0] Opcode,
    input [2:0] Funct3,
    input [6:0] Funct7,
    output [1:0] PCS,  // 00 for non-control, 01 for conditional branch, 10 for jal, 11 for jalr
    output RegWrite,		// Asserted only by instructions which write to register file (load, auipc, lui, DPImm, DPReg);
    output MemWrite,  // Asserted only by store (sw)
    output MemtoReg,  // Asserted only by load (lw)
    output [1:0] ALUSrcA, 	// Needed for lui, auipic. Refer to the microarchitecture for its use. Uncomment wire and port map in RV.v as well
    output [1:0] ALUSrcB,		// Asserted by all instructions which use an immediate (load, store, lui, auipc, DPImm). Needs to be expanded to a 2-bit signal to support link functionality for jal, jalr. Change wire width in RV.v as well
    output reg [2:0] ImmSrc,  // 000 for U, 010 for UJ, 011 for I, 110 for S, 111 for SB.
    output reg [3:0] ALUControl,	// 0000 for add, 0001 for sub, 1110 for and, 1100 for or, 0010 for sll, 1010 for srl, 1011 for sra, 0001 for branch, 0000 for all others.
    // Note that the most significant 3 bits are Funct3 for all DP instrns. LSB is the same as Funct[5] for DPReg type and DPImm_shifts. For other DPImms, Funct[5] is 0.
    // It is the same as sub for branches, and add for all others not mentioned in the line above.
    output ComputeResultSel, // select to choose ALUResult or mul/div result as the computeResult (ALUResult)
    output reg MCycleStart,  // to issue the MCycle to start
    output reg [1:0] MCycleOp, // to select operation (mul, div, signed, or unsigned) to do in MCycle
    output [2:0] SizeSel // Size selection for load/store
);
    // Change wire to reg if assigned inside a procedural (always) block. However, where it is easy enough, use assign instead of always.
    // A 2-1 multiplexing can be done easily using an assign with a ternary operator
    // For multiplexing with number of inputs > 2, a case construct within an always block is a natural fit. DO NOT to use nested ternary assignment operator as it hampers the readability of your code.

    // PCS: program counter selection
    assign PCS = (Opcode == 7'b1101111) ? 2'b10 :  // jal
        (Opcode == 7'b1100011) ? 2'b01 :  // branch
        (Opcode == 7'b1100111) ? 2'b11 :  // jalr
        2'b00;

    // RegWrite
    assign RegWrite = (Opcode == 7'b0000011  // load
        || Opcode == 7'b0010011  // DP Imm
        || Opcode == 7'b0110011  // DP Reg
        || Opcode == 7'b0010111  // auipc
        || Opcode == 7'b0110111  // lui
        || Opcode == 7'b1101111);  // jal

    // MemtoReg
    assign MemtoReg = (Opcode == 7'b0000011);  // load

    // MemWrite
    assign MemWrite = (Opcode == 7'b0100011);  // store

    // ALUSrcA
    assign ALUSrcA = (Opcode == 7'b0010111 // auipc
        || Opcode == 7'b1101111 // jal
        || Opcode == 7'b1100111) ? 2'b11 :  // jalr
        (Opcode == 7'b0110111) ? 2'b01 :  // lui
        2'b00;  // remaining instructions will use rs1

    // ALUSrcB
    assign ALUSrcB = (Opcode == 7'b0010011  // DP Imm
        || Opcode == 7'b0000011  // load
        || Opcode == 7'b0100011  // store
        || Opcode == 7'b0010111  // auipc
        || Opcode == 7'b0110111) ? 2'b11 :  // lui
        (Opcode == 7'b1101111    // jal
        || Opcode == 7'b1100111) ? 2'b01 :  // jalr
        2'b00;  // DP Reg and Branch

    // ALU & Mcycle mux
    assign ComputeResultSel = (Opcode == 7'b0110011 && Funct7 == 7'b0000001) ? 1'b1 : 1'b0;  // decide ALU result or Mcycle result

    // SizeSel generation based on Funct3 for load/store instructions
    // 000: byte, 001: halfword, 010: word, 100: byte unsigned, 101: halfword unsigned
    assign SizeSel = (Opcode == 7'b0000011 || Opcode == 7'b0100011) ? Funct3 : 3'b010;

    // MCycleOp decode- 00: signed mul, 01: unsigned mul, 10: signed div, 11:  unsigned div
    always @(*) begin
        MCycleOp[1] = Funct3[2];  // divide or mul
        if (MCycleOp[1]) begin
            MCycleOp[0] = Funct3[0]; // signed or unsigned for divisio
        end else begin
            MCycleOp[0] = Funct3[1]; // signed or unsigned for
        end
    end

    always @(*) begin
        MCycleStart = 1'b0;
        case (Opcode)
            7'b0110011: begin  // R-type (DPReg)
                MCycleStart = (Funct7 == 7'b0000001) ? 1'b1 : 1'b0;  // start if Funct7 = 0x01
                ImmSrc      = 3'bxxx;  // R-type has no immediate
                ALUControl  = {Funct3, Funct7[5]};  // ALU op decided by funct3/funct7
            end

            7'b0010011: begin  // I-type (DPImm)
                ImmSrc = 3'b011;  // I-type immediate
                if (Funct3 == 3'b001 || Funct3 == 3'b101)   // slli, srli, srai
                    ALUControl = {Funct3, Funct7[5]};  // shift-immediates use imm[30]
                else ALUControl = {Funct3, 1'b0};
            end

            7'b0000011: begin  // Load
                ImmSrc     = 3'b011;  // I-type immediate
                ALUControl = 4'b0000;  // add base + offset
            end

            7'b0100011: begin  // Store
                ImmSrc     = 3'b110;  // S-type immediate
                ALUControl = 4'b0000;  // add base + offset
            end

            7'b1100011: begin  // Branch
                ImmSrc     = 3'b111;  // B-type immediate
                ALUControl = 4'b0001;  // subtract (for comparison)
            end

            7'b0010111: begin  // AUIPC
                ImmSrc     = 3'b000;  // U-type
                ALUControl = 4'b0000;  // add
            end

            7'b0110111: begin  // LUI
                ImmSrc     = 3'b000;  // U-type
                ALUControl = 4'b0000;  // just pass imm (ALU add with zero)
            end

            7'b1101111: begin  // JAL
                ImmSrc     = 3'b010;  // J-type immediate
                ALUControl = 4'b0000;  // add
            end

            7'b1100111: begin // JALR
                ImmSrc     = 3'b011;  // I-type
                ALUControl = 4'b0000; // add
            end

            default: begin
                ImmSrc      = 3'b000;
                ALUControl  = 4'b0000;  // safe default
                MCycleStart = 1'b0;
            end
        endcase
    end

endmodule
