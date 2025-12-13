`timescale 1ns / 1ps

module Hazard (
    input      [4:0] rs1D,
    input      [4:0] rs2D,
    input      [4:0] rs1E,
    input      [4:0] rs2E,
    input      [4:0] rs2M,
    input      [4:0] rdE,
    input      [4:0] rdM,
    input      [4:0] rdW,
    input            RegWriteM,
    input            RegWriteW,
    input            MemWriteM,
    input            MemtoRegW,
    input            MemtoRegE,
    input            Busy,
    input      [1:0] PCSrcM,
    input      [6:0] OpcodeD,
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output           ForwardM,
    output           lwStall,
    output           StallF,
    output           StallD,
    output           FlushE,
    output           FlushD,
    output           FlushM,
    output           Forward1D,
    output           Forward2D
);

    // ===========================================================================
    // Instruction Checks
    // ===========================================================================
    wire rs1_active;
    wire rs2_active;

    // Check if instruction actually USES rs1
    assign rs1_active = (OpcodeD != 7'b1101111) &&  // JAL
        (OpcodeD != 7'b0110111) &&  // LUI
        (OpcodeD != 7'b0010111);  // AUIPC

    // Check if instruction REQUIRES rs2 for Hazard Stalling
    assign rs2_active = (OpcodeD != 7'b1101111) &&  // JAL
        (OpcodeD != 7'b0110111) &&  // LUI
        (OpcodeD != 7'b0010111) &&  // AUIPC
        (OpcodeD != 7'b0000011) &&  // Load
        (OpcodeD != 7'b0010011) &&  // DP Imm
        (OpcodeD != 7'b1100111) &&  // JALR
        (OpcodeD != 7'b0100011);  // Store

    // ===========================================================================
    // Forwarding Logic
    // ===========================================================================

    // Forward AE
    always @(*) begin
        if ((rs1E == rdM) && RegWriteM && (rdM != 0)) begin
            ForwardAE = 2'b10;  // Forward from Memory
        end else if ((rs1E == rdW) && RegWriteW && (rdW != 0)) begin
            ForwardAE = 2'b01;  // Forward from Writeback
        end else begin
            ForwardAE = 2'b00;
        end
    end

    // Forward BE
    always @(*) begin
        if ((rs2E == rdM) && RegWriteM && (rdM != 0)) begin
            ForwardBE = 2'b10;  // Forward from Memory
        end else if ((rs2E == rdW) && RegWriteW && (rdW != 0)) begin
            ForwardBE = 2'b01;  // Forward from Writeback
        end else begin
            ForwardBE = 2'b00;
        end
    end

    // ForwardM (Mem-Mem Copy for Stores)
    assign ForwardM = (rs2M == rdW) && MemWriteM && MemtoRegW && (rdW != 0);

    // ===========================================================================
    // Stall & Flush Logic
    // ===========================================================================

    // Load-Use Hazard
    // Stalls if Load in EX matches rs1 or rs2 in Decode (and rs1/rs2 are actually active)
    assign lwStall = MemtoRegE && (rdE != 0) && (((rs1D == rdE) && rs1_active) || ((rs2D == rdE) && rs2_active));

    assign StallF = (lwStall | Busy) & ~PCSrcM[0];
    assign StallD = (lwStall | Busy) & ~PCSrcM[0];

    // Control Hazards
    assign FlushE = lwStall | PCSrcM[0];
    assign FlushD = PCSrcM[0];
    assign FlushM = PCSrcM[0];

    // Decode Forwarding
    assign Forward1D = (rs1D == rdW) & RegWriteW & (rdW != 0);
    assign Forward2D = (rs2D == rdW) & RegWriteW & (rdW != 0);

endmodule
