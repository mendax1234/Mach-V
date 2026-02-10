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
        input             WE,
        input      [ 4:0] rs1,
        input      [ 4:0] rs2,
        input      [ 4:0] rd,
        input      [31:0] WD,
        output reg [31:0] RD1,
        output reg [31:0] RD2
    );

    // declare RegBank
    reg [31:0] RegBank[0:31];
    // 32 addresses, each a 32-bit word
    // (1 to 31) is sufficient as R15 is not stored. Kept it as (0 to 31) just to supress a warning

    // read
    always@(*)	// change to @posedge CLK only if using synch read. In that case, the output is RD1E, RD2E directly
    begin
        RD1 <= (rs1 == 5'b00000) ? 32'd0 : RegBank[rs1];
        RD2 <= (rs2 == 5'b00000) ? 32'd0 : RegBank[rs2];
    end

    // write
    always @(posedge CLK) begin
        if ((rd != 5'b00000) & (WE))
            RegBank[rd] <= WD;
    end

endmodule
