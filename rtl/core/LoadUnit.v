/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   LoadStoreUnit
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Store Unit.
--                Handles Byte/Half/Word alignment for Memory Reads (Loads) and 
--                Memory Writes (Stores). Generates byte write masks.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module LoadUnit (
        input  [ 2:0] Funct3,
        input  [ 1:0] ByteOffset,   // Address[1:0]
        input  [31:0] ReadData_in,
        output [31:0] ReadDataW
    );

    // --- STORE PATH (Alignment & Masking) ---
    wire [ 4:0] shamt;  // Offset * 8
    assign shamt = {ByteOffset, 3'b000};

    wire [31:0] data_shifted;
    reg  [31:0] loaded_val;

    assign data_shifted = ReadData_in >> shamt;

    always @(*) begin
        case (Funct3)
            3'b000:
                loaded_val = {{24{data_shifted[7]}}, data_shifted[7:0]};  // LB
            3'b001:
                loaded_val = {{16{data_shifted[15]}}, data_shifted[15:0]};  // LH
            3'b100:
                loaded_val = {24'b0, data_shifted[7:0]};  // LBU
            3'b101:
                loaded_val = {16'b0, data_shifted[15:0]};  // LHU
            default:
                loaded_val = data_shifted;  // LW
        endcase
    end

    assign ReadDataW = loaded_val;
endmodule
