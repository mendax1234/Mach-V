/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-29
-- Module Name:   LoadStoreUnit
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Store Unit.
--                Handles Byte/Half/Word alignment for Memory Writes (Stores).
--                Generates byte write masks.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module StoreUnit (
        input  [ 2:0] Funct3M,
        input         MemWriteM,
        input  [31:0] WriteDataM,
        input  [ 1:0] ByteOffset,    // Address[1:0]
        output [ 3:0] MemWrite_out,  // The mask sent to memory
        output [31:0] WriteData_out  // The aligned data sent to memory
    );

    // --- STORE PATH (Alignment & Masking) ---
    wire [4:0] shamt = {ByteOffset, 3'b000};  // Offset * 8

    // Align Data
    assign WriteData_out = WriteDataM << shamt;

    // Generate Mask
    reg [3:0] BaseMask;
    always @(*) begin
        case (Funct3M)
            3'b000:
                BaseMask = 4'b0001;  // SB
            3'b001:
                BaseMask = 4'b0011;  // SH
            default:
                BaseMask = 4'b1111;  // SW
        endcase
    end

    // Shift Mask
    assign MemWrite_out = (MemWriteM) ? (BaseMask << ByteOffset) : 4'b0000;
endmodule
