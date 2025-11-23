`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.11.2025 16:52:01
// Design Name: 
// Module Name: pipeline_D
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipeline_D (
    input CLK,
    input RESET,
    input StallD,
    input FlushD,
    input [31:0] InstrF,
    input [31:0] PCF,
    output reg [31:0] InstrD,
    output reg [31:0] PCD
);

    always @(posedge CLK) begin
        if (RESET || FlushD) begin
            InstrD <= 32'b0;
            PCD    <= 32'b0;
        end else if (~StallD) begin
            InstrD <= InstrF;
            PCD    <= PCF;
        end
    end

endmodule


