`timescale 1ns / 1ps

module pipeline_M (
    input             CLK,
    input             RESET,
    input             Busy,
    input             FlushM,
    input             RegWriteE,
    input             MemtoRegE,
    input             MemWriteE,
    input      [31:0] ComputeResultE,
    input      [31:0] WriteDataE,
    input      [ 4:0] rs2E,
    input      [ 4:0] rdE,
    input      [ 2:0] Funct3E,
    input      [31:0] RD1E_Forwarded,
    input      [31:0] PCE,
    input      [31:0] ExtImmE,
    input      [ 1:0] PCSE,
    input      [ 2:0] ALUFlagsE,
    output reg        RegWriteM,
    output reg        MemtoRegM,
    output reg        MemWriteM,
    output reg [ 2:0] Funct3M,
    output reg [31:0] ComputeResultM,
    output reg [31:0] WriteDataM,
    output reg [ 4:0] rs2M,
    output reg [ 4:0] rdM,
    output reg [31:0] RD1M,
    output reg [31:0] PCM,
    output reg [31:0] ExtImmM,
    output reg [ 1:0] PCSM,
    output reg [ 2:0] ALUFlagsM
);

    always @(posedge CLK) begin
        if (RESET || FlushM) begin
            RegWriteM <= 1'b0;
            MemtoRegM <= 1'b0;
            MemWriteM <= 1'b0;
            Funct3M <= 3'b0;
            ComputeResultM <= 32'b0;
            WriteDataM <= 32'b0;
            rs2M <= 5'b0;
            rdM <= 5'b0;
            RD1M <= 32'b0;
            PCM <= 32'b0;
            ExtImmM <= 32'b0;
            PCSM <= 2'b0;
            ALUFlagsM <= 3'b0;
        end else if (~Busy) begin
            RegWriteM <= RegWriteE;
            MemtoRegM <= MemtoRegE;
            MemWriteM <= MemWriteE;
            Funct3M <= Funct3E;
            ComputeResultM <= ComputeResultE;
            WriteDataM <= WriteDataE;
            rs2M <= rs2E;
            rdM <= rdE;
            RD1M <= RD1E_Forwarded;
            PCM <= PCE;
            ExtImmM <= ExtImmE;
            PCSM <= PCSE;
            ALUFlagsM <= ALUFlagsE;
        end
    end

endmodule
