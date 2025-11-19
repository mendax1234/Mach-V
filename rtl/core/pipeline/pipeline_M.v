`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.11.2025 16:52:01
// Design Name: 
// Module Name: pipeline_M
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


module pipeline_M(
    input CLK,
    input RESET,
    input Busy,
    input RegWriteE,
    input MemtoRegE,
    input MemWriteE,
    input [31:0] ComputeResultE,
    input [31:0] WriteDataE,
    input [4:0]  rs2E,
    input [4:0]  rdE,
    input [2:0] Funct3E,
    output reg RegWriteM,
    output reg MemtoRegM,
    output reg MemWriteM,
    output reg [2:0]  Funct3M,
    output reg [31:0] ComputeResultM,
    output reg [31:0] WriteDataM,
    output reg [4:0]  rs2M,
    output reg [4:0]  rdM
    );
    
    always @(posedge CLK) begin
        if (RESET) begin
            RegWriteM        <= 1'b0;
            MemtoRegM        <= 1'b0;
            MemWriteM        <= 1'b0;
            Funct3M          <= 3'b0;
            ComputeResultM   <= 32'b0;
            WriteDataM       <= 32'b0;
            rs2M            <= 5'b0;
            rdM              <= 5'b0;
        end else if (~Busy) begin
            RegWriteM        <= RegWriteE;
            MemtoRegM        <= MemtoRegE;
            MemWriteM        <= MemWriteE;
            Funct3M          <= Funct3E;
            ComputeResultM   <= ComputeResultE;
            WriteDataM       <= WriteDataE;
            rs2M            <= rs2E;
            rdM              <= rdE;
        end 
    end
     
endmodule
