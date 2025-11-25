`timescale 1ns / 1ps

module pipeline_E (
    input             CLK,
    input             RESET,
    input             Busy,
    input             FlushE,
    input      [ 1:0] PCSD,
    input             RegWriteD,
    input             MemtoRegD,
    input             MemWriteD,
    input      [ 3:0] ALUControlD,
    input      [ 1:0] ALUSrcAD,
    input      [ 1:0] ALUSrcBD,
    input      [31:0] RD1D,
    input      [31:0] RD2D,
    input      [31:0] ExtImmD,
    input      [ 4:0] rs1D,
    input      [ 4:0] rs2D,
    input      [ 4:0] rdD,
    input      [31:0] PCD,
    input      [ 2:0] Funct3D,
    input      [ 1:0] MCycleOpD,
    input             MCycleStartD,
    input             MCycleResultSelD,
    input             ComputeResultSelD,
    output reg [ 1:0] PCSE,
    output reg        RegWriteE,
    output reg        MemtoRegE,
    output reg        MemWriteE,
    output reg [ 3:0] ALUControlE,
    output reg [ 1:0] ALUSrcAE,
    output reg [ 1:0] ALUSrcBE,
    output reg [31:0] RD1E,
    output reg [31:0] RD2E,
    output reg [31:0] ExtImmE,
    output reg [ 4:0] rs1E,
    output reg [ 4:0] rs2E,
    output reg [ 4:0] rdE,
    output reg [31:0] PCE,
    output reg [ 2:0] Funct3E,
    output reg [ 1:0] MCycleOpE,
    output reg        MCycleStartE,
    output reg        MCycleResultSelE,
    output reg        ComputeResultSelE
);

    always @(posedge CLK) begin
        if (RESET || FlushE) begin
            PCSE              <= 2'b0;
            RegWriteE         <= 1'b0;
            MemtoRegE         <= 1'b0;
            MemWriteE         <= 1'b0;
            ALUControlE       <= 4'b0;
            ALUSrcAE          <= 2'b0;
            ALUSrcBE          <= 2'b0;
            RD1E              <= 32'b0;
            RD2E              <= 32'b0;
            ExtImmE           <= 32'b0;
            rs1E              <= 5'b0;
            rs2E              <= 5'b0;
            rdE               <= 5'b0;
            PCE               <= 32'b0;
            Funct3E           <= 3'b0;
            MCycleOpE         <= 2'b0;
            MCycleStartE      <= 1'b0;
            MCycleResultSelE  <= 1'b0;
            ComputeResultSelE <= 1'b0;
        end else if (~Busy) begin
            PCSE              <= PCSD;
            RegWriteE         <= RegWriteD;
            MemtoRegE         <= MemtoRegD;
            MemWriteE         <= MemWriteD;
            ALUControlE       <= ALUControlD;
            ALUSrcAE          <= ALUSrcAD;
            ALUSrcBE          <= ALUSrcBD;
            RD1E              <= RD1D;
            RD2E              <= RD2D;
            ExtImmE           <= ExtImmD;
            rs1E              <= rs1D;
            rs2E              <= rs2D;
            rdE               <= rdD;
            PCE               <= PCD;
            Funct3E           <= Funct3D;
            MCycleOpE         <= MCycleOpD;
            MCycleStartE      <= MCycleStartD;
            MCycleResultSelE  <= MCycleResultSelD;
            ComputeResultSelE <= ComputeResultSelD;
        end
    end

endmodule
