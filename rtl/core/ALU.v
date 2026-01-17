/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   ALU
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Arithmetic Logic Unit (ALU).
--                Performs arithmetic, logic, comparison, and shift operations.
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module ALU (
    input  wire [31:0] Src_A,
    input  wire [31:0] Src_B,
    input  wire [ 3:0] ALUControl,  // 0000:add, 0001:sub, 1110:and, 1100:or
                                    // 0010:sll, 1010:srl, 1011:sra
                                    // 0100:slt, 0110:sltu
    output reg  [31:0] ALUResult,
    output wire [ 2:0] ALUFlags     // {eq, lt, ltu}
);

    // ============================================================
    // Control Decode
    // ============================================================
    wire is_sub = (ALUControl == 4'b0001) || (ALUControl == 4'b0100) || (ALUControl == 4'b0110);

    // ============================================================
    // Adder (shared for add / sub / compare)
    // ============================================================
    wire [32:0] A_ext = {1'b0, Src_A};
    wire [32:0] B_ext = is_sub ? {1'b0, ~Src_B} : {1'b0, Src_B};
    wire [32:0] Cin = is_sub ? 33'd1 : 33'd0;

    wire [32:0] Sum = A_ext + B_ext + Cin;

    // ============================================================
    // Adder Flags
    // ============================================================
    wire C = Sum[32];  // Carry out
    wire N = Sum[31];  // Negative
    wire Z = (Sum[31:0] == 32'b0);

    // Signed overflow
    wire V = is_sub
           ? (Src_A[31] != Src_B[31]) && (Sum[31] != Src_A[31])
           : (Src_A[31] == Src_B[31]) && (Sum[31] != Src_A[31]);

    // Compare flags
    wire lt = N ^ V;  // Signed less-than
    wire ltu = ~C;  // Unsigned less-than

    assign ALUFlags = {Z, lt, ltu};

    // ============================================================
    // Shifter control
    // ============================================================
    reg [1:0] Sh;

    always @(*) begin
        case (ALUControl)
            4'b0010: Sh = 2'b00;  // SLL
            4'b1010: Sh = 2'b10;  // SRL
            4'b1011: Sh = 2'b11;  // SRA
            default: Sh = 2'b00;
        endcase
    end

    wire [31:0] ShOut;

    Shifter Shifter1 (
        .Sh    (Sh),
        .Shamt5(Src_B[4:0]),
        .ShIn  (Src_A),
        .ShOut (ShOut)
    );

    // ============================================================
    // Result Mux
    // ============================================================
    always @(*) begin
        case (ALUControl)
            // Arithmetic
            4'b0000: ALUResult = Sum[31:0];  // ADD
            4'b0001: ALUResult = Sum[31:0];  // SUB

            // Logic
            4'b1110: ALUResult = Src_A & Src_B;  // AND
            4'b1100: ALUResult = Src_A | Src_B;  // OR
            4'b1000: ALUResult = Src_A ^ Src_B;  // XOR

            // Comparisons
            4'b0100: ALUResult = {31'b0, lt};  // SLT
            4'b0110: ALUResult = {31'b0, ltu};  // SLTU

            // Shifts
            4'b0010, 4'b1010, 4'b1011: ALUResult = ShOut;

            default: ALUResult = 32'b0;
        endcase
    end

endmodule
