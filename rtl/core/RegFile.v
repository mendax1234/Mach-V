/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   RegFile
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Register File (32 x 32-bit).
--                2 Read Ports (Combinational/Async), 1 Write Port (Synchronous).
--                Register 0 is hardwired to 0.
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module RegFile (
        input             CLK,
        // Pipeline 1 Write Port
        input             WE1,
        input      [ 4:0] rd1,
        input      [31:0] WD1,
        // Pipeline 2 Write Port
        input             WE2,
        input      [ 4:0] rd2,
        input      [31:0] WD2,

        // Pipeline 1 Read Ports
        input      [ 4:0] rs1_1,
        input      [ 4:0] rs2_1,
        output reg [31:0] RD1_1,
        output reg [31:0] RD2_1,

        // Pipeline 2 Read Ports
        input      [ 4:0] rs1_2,
        input      [ 4:0] rs2_2,
        output reg [31:0] RD1_2,
        output reg [31:0] RD2_2
    );

    // declare RegBank (0 to 31)
    reg [31:0] RegBank[0:31];

    // --- Combinational Reads ---
    always @(*) begin
        RD1_1 = (rs1_1 == 5'b00000) ? 32'd0 : RegBank[rs1_1];
        RD2_1 = (rs2_1 == 5'b00000) ? 32'd0 : RegBank[rs2_1];

        RD1_2 = (rs1_2 == 5'b00000) ? 32'd0 : RegBank[rs1_2];
        RD2_2 = (rs2_2 == 5'b00000) ? 32'd0 : RegBank[rs2_2];
    end

    // --- Synchronous Writes ---
    always @(posedge CLK) begin
        // If both pipelines write to the same register, WE2 executes last
        // and safely overrides WE1, satisfying the "latest instruction" priority rule.
        if (WE1 && (rd1 != 5'b00000)) begin
            RegBank[rd1] <= WD1;
        end
        if (WE2 && (rd2 != 5'b00000)) begin
            RegBank[rd2] <= WD2;
        end
    end

endmodule
