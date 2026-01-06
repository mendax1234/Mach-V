/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   pipeline_D
-- Project Name:  Mach-V
-- Description:   IF/ID Pipeline Register. 
--                Latches the instruction and PC from the Fetch stage to be 
--                decoded in the Decode stage.
-- 
-- Credits:       First version created by Hieu.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module pipeline_D (
    input             CLK,
    input             RESET,
    input             StallD,
    input             FlushD,
    input      [31:0] InstrF,
    input      [31:0] PCF,
    output reg [31:0] InstrD,
    output reg [31:0] PCD
);

    always @(posedge CLK) begin
        if (RESET || FlushD) begin
            InstrD <= 32'b0;
            PCD <= 32'b0;
        end else if (~StallD) begin
            InstrD <= InstrF;
            PCD <= PCF;
        end
    end

endmodule


