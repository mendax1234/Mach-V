`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: ALU
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: RISC-V Processor ALU Module
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
//test
module ALU (
    input [31:0] Src_A,
    input [31:0] Src_B,
    input [3:0] ALUControl, // 0000 for add, 0001 for sub, 1110 for and, 1100 for or, 0010 for sll, 1010 for srl, 1011 for sra.
    output reg [31:0] ALUResult,
    output [2:0] ALUFlags  //{eq, lt, ltu}
);

    // Shifter signals
    wire [ 1:0] Sh;  // Encodes the type of shift, 00 for sll, 10 for srl, 11 for sra
    wire [ 4:0] Shamt5;  // shift amount
    wire [31:0] ShIn;  // The value to be shifted, taken from Src_A
    wire [31:0] ShOut;  // The shifted result

    // Other signals
    wire [32:0] S_wider;
    reg  [32:0] Src_A_comp;
    reg  [32:0] Src_B_comp;
    reg  [32:0] C_0;
    reg  [32:0] diff; // for sltu 
    wire N, Z, C, V;  // optional intermediate values to derive eq, lt, ltu
    // Hint: We need to care about V only for subtraction
    wire eq, lt, ltu;
    wire add_or_sub, sub;

    // S_wider stores the temporary sum
    // S_wider[32] stores the carry-out
    // S_wider[31:0] stores the 32-bit result 
    assign S_wider = Src_A_comp + Src_B_comp + C_0;

    always @(Src_A, Src_B, ALUControl, S_wider, ShOut) begin
        // default values; help avoid latches
        C_0 = 0;
        Src_A_comp = {1'b0, Src_A};
        Src_B_comp = {1'b0, Src_B};

        case (ALUControl)
            4'b0000: ALUResult = S_wider[31:0];  //add {000, 0}        
            4'b0001: begin  //sub {000,1}
                C_0[0] = 1;
                Src_B_comp = {1'b0, ~Src_B};
                ALUResult = S_wider[31:0];
            end
            4'b1110: ALUResult = Src_A & Src_B; // and {111,0}
            4'b1100: ALUResult = Src_A | Src_B; // or  {110,0}
            4'b1000: ALUResult = Src_A ^ Src_B; // xor {100,0}

            // slt, sltu
            4'b0100: begin  // slt  {010,0} 
                C_0[0] = 1;
                Src_B_comp = {1'b0, ~Src_B};
                ALUResult = {31'b0, (S_wider[31] ^ V)};
                // Some comments for clarification with prof
                // ALUResult = {31'b0, (S_wider[31] ^ ((Src_A[31] & ~Src_B[31] & ~S_wider[31]) |
                //             (~Src_A[31] & Src_B[31] &  S_wider[31])))};
            end
            4'b0110: begin  // sltu {011,0}
                C_0[0] = 1;
                Src_B_comp = {1'b0, ~Src_B};
                ALUResult = {31'b0, (~C)}; 
                // Some comments for clarification with prof
                // ALUResult = {31'b0, (~S_wider[32])};
            end

            // include cases for shifts		// shifts
            4'b0010: ALUResult = ShOut;  // sll {001,0}
            4'b1010: ALUResult = ShOut;  // srl {101,0}
            4'b1011: ALUResult = ShOut;  // sra {101,1}
            default: ALUResult = 32'bx;
        endcase
    end

    // Set Zero Flag
    assign Z = (ALUResult == 0) ? 1 : 0;
    // Set Negative flag according to the MSB of the ALUResult
    assign N = ALUResult[31];
    // Set Carry flag according to the MSB of the S_wider and only when doing add/sub
    assign add_or_sub = (ALUControl == 4'b0000)  // add
                 || (ALUControl == 4'b0001)  // sub
                 || (ALUControl == 4'b0100)  // slt
                 || (ALUControl == 4'b0110); // sltu
    assign C = S_wider[32] & add_or_sub;
    // Set Overflow flag when performing add/sub
    assign sub = (ALUControl == 4'b0001) // sub
        || (ALUControl == 4'b0100)       // slt
        || (ALUControl == 4'b0110);      // sltu
    assign V = add_or_sub & (Src_A[31] ^ S_wider[31]) & ~(Src_A[31] ^ sub ^ Src_B[31]);

    // For instruction that involves subtraction (blt, bltu, etc.)
    // equal: Z
    // signed less-than: (N ^ V)
    // unsigned less-than: ~C
    assign eq = Z;
    assign lt = (sub) ? (N ^ V) : 1'b0;
    assign ltu = (sub) ? (~C) : 1'b0;

    assign ALUFlags = {eq, lt, ltu};  //{eq, lt, ltu} - all except eq are placeholders. 
    // Will need to be modified in lab 3 to support blt, bltu, bge, bgeu.

    // make shifter connections here
    // Sh signals can be derived directly from the appropriate ALUControl bits
    // assign Sh = {ALUControl[3], ALUControl[0]}; 	//0010 for sll, 1010 for srl, 1011 for sra
    assign Sh = (ALUControl == 4'b0010) ? 2'b00 : 
				(ALUControl == 4'b1010) ? 2'b10 : 
				(ALUControl == 4'b1011) ? 2'b11 : 2'b00; 	//0010 for sll, 1010 for srl, 1011 for sra
    assign Shamt5 = Src_B[4:0];
    assign ShIn = Src_A;


    // Instantiate Shifter        
    Shifter Shifter1 (
        Sh,
        Shamt5,
        ShIn,
        ShOut
    );

endmodule
