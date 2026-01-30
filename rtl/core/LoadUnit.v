/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-29
-- Module Name:   LoadStoreUnit
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Load Unit.
--                Handles Byte/Half/Word alignment for Memory Reads (Loads).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/
`timescale 1ns / 1ps

module LoadUnit (
    input  [ 2:0] Funct3W,
    input  [ 1:0] ByteOffset,   // Address[1:0]
    input  [31:0] ReadData_in,
    output [31:0] ReadDataW
);

    // --- STORE PATH (Alignment & Masking) ---
    wire [ 4:0] shamt = {ByteOffset, 3'b000};  // Offset * 8

    wire [31:0] data_shifted = ReadData_in >> shamt;
    reg  [31:0] loaded_val;

    always @(*) begin
        case (Funct3W)
            3'b000: loaded_val = {{24{data_shifted[7]}}, data_shifted[7:0]};  // LB
            3'b001: loaded_val = {{16{data_shifted[15]}}, data_shifted[15:0]};  // LH
            3'b100: loaded_val = {24'b0, data_shifted[7:0]};  // LBU
            3'b101: loaded_val = {16'b0, data_shifted[15:0]};  // LHU
            default: loaded_val = data_shifted;  // LW
        endcase
    end

    assign ReadDataW = loaded_val;
endmodule
