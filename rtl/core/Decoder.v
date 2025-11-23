`timescale 1ns / 1ps

module Decoder (
    input      [6:0] Opcode,
    input      [2:0] Funct3,
    input      [6:0] Funct7,
    output reg [1:0] PCS,               // 00: Non-control, 01: Branch, 10: JAL, 11: JALR
    output reg       RegWrite,          // Write to Register File
    output reg       MemWrite,          // Write to Memory
    output reg       MemtoReg,          // Load from Memory
    output reg [1:0] ALUSrcA,           // ALU Source A Mux
    output reg [1:0] ALUSrcB,           // ALU Source B Mux
    output reg [2:0] ImmSrc,            // Immediate Gen Type
    output reg [3:0] ALUControl,        // ALU Operation Control
    output reg       ComputeResultSel,  // 0: ALU, 1: Multi-Cycle
    output reg       MCycleResultSel,   // 0: Low/Quotient, 1: High/Remainder
    output reg       MCycleStart,       // Start Multi-Cycle Unit
    output reg [1:0] MCycleOp,          // Multi-Cycle Opcode
    output reg [2:0] SizeSel            // Load/Store Size (Byte/Half/Word)
);

  // ========================================================================
  //                            MAIN DECODER
  // ========================================================================
  // Sets all main control signals based on the Opcode
  always @(*) begin
    // --- DEFAULTS (Prevent Latches) ---
    PCS              = 2'b00;
    RegWrite         = 1'b0;
    MemWrite         = 1'b0;
    MemtoReg         = 1'b0;
    ALUSrcA          = 2'b00;  // Default: Register rs1
    ALUSrcB          = 2'b00;  // Default: Register rs2
    ImmSrc           = 3'b000;
    ALUControl       = 4'b0000;
    ComputeResultSel = 1'b0;
    MCycleStart      = 1'b0;
    SizeSel          = 3'b010;  // Default: Word (32-bit)

    case (Opcode)
      // ------------------------------------
      // R-Type Instructions (Register-Register)
      // ------------------------------------
      7'b0110011: begin
        RegWrite = 1'b1;
        ImmSrc   = 3'bxxx;  // Not used

        // Determine if this is a Multi-Cycle Op (M-Extension)
        if (Funct7 == 7'b0000001) begin
          ComputeResultSel = 1'b1;  // Select MCycle Result
          MCycleStart      = 1'b1;
          ALUControl       = 4'b0000;  // Don't care
        end else begin
          ComputeResultSel = 1'b0;  // Select ALU Result
          MCycleStart      = 1'b0;
          ALUControl       = {Funct3, Funct7[5]};  // Standard ALU decoding
        end
      end

      // ------------------------------------
      // I-Type Instructions (Immediate Arithmetic)
      // ------------------------------------
      7'b0010011: begin
        RegWrite = 1'b1;
        ALUSrcB  = 2'b11;  // Use Immediate
        ImmSrc   = 3'b011;  // I-Type

        // Special handling for Shift Immediates (SLLI, SRLI, SRAI)
        if (Funct3 == 3'b001 || Funct3 == 3'b101)
          ALUControl = {Funct3, Funct7[5]};  // Funct7[5] distinguishes SRLI/SRAI
        else ALUControl = {Funct3, 1'b0};
      end

      // ------------------------------------
      // Load Instructions
      // ------------------------------------
      7'b0000011: begin
        RegWrite   = 1'b1;
        MemtoReg   = 1'b1;
        ALUSrcB    = 2'b11;  // Base + Offset
        ImmSrc     = 3'b011;  // I-Type
        ALUControl = 4'b0000;  // Add
        SizeSel    = Funct3;  // Byte/Half/Word
      end

      // ------------------------------------
      // Store Instructions
      // ------------------------------------
      7'b0100011: begin
        MemWrite   = 1'b1;
        ALUSrcB    = 2'b11;  // Base + Offset
        ImmSrc     = 3'b110;  // S-Type
        ALUControl = 4'b0000;  // Add
        SizeSel    = Funct3;  // Byte/Half/Word
      end

      // ------------------------------------
      // Branch Instructions
      // ------------------------------------
      7'b1100011: begin
        PCS        = 2'b01;  // Branch
        ImmSrc     = 3'b111;  // B-Type
        ALUControl = 4'b0001;  // Subtract (Comparison)
      end

      // ------------------------------------
      // JAL (Jump and Link)
      // ------------------------------------
      7'b1101111: begin
        PCS = 2'b10;  // JAL
        RegWrite = 1'b1;
        ALUSrcA = 2'b11;  // PC
        ALUSrcB = 2'b01;  // 4
        ImmSrc = 3'b010;  // J-Type
        ALUControl = 4'b0000;  // PC + 4 (Actually handled by dedicated adder, but ALU setup safely)
      end

      // ------------------------------------
      // JALR (Jump and Link Register)
      // ------------------------------------
      7'b1100111: begin
        PCS        = 2'b11;  // JALR
        RegWrite   = 1'b1;
        ALUSrcA    = 2'b00;  // rs1
        ALUSrcB    = 2'b01;  // 4
        ImmSrc     = 3'b011;  // I-Type
        ALUControl = 4'b0000;  // PC + 4
      end

      // ------------------------------------
      // LUI (Load Upper Immediate)
      // ------------------------------------
      7'b0110111: begin
        RegWrite   = 1'b1;
        ALUSrcA    = 2'b01;  // Zero
        ALUSrcB    = 2'b11;  // Immediate
        ImmSrc     = 3'b000;  // U-Type
        ALUControl = 4'b0000;  // 0 + Imm
      end

      // ------------------------------------
      // AUIPC (Add Upper Immediate to PC)
      // ------------------------------------
      7'b0010111: begin
        RegWrite   = 1'b1;
        ALUSrcA    = 2'b11;  // PC
        ALUSrcB    = 2'b11;  // Immediate
        ImmSrc     = 3'b000;  // U-Type
        ALUControl = 4'b0000;  // PC + Imm
      end

      default: begin
        // Defaults already set at top of block
      end
    endcase
  end

  // ========================================================================
  //                           AUXILIARY DECODERS
  // ========================================================================

  // Multi-Cycle Operation Type (Signed/Unsigned, Mul/Div)
  always @(*) begin
    MCycleOp[1] = Funct3[2];  // 1=Div, 0=Mul
    if (MCycleOp[1]) MCycleOp[0] = Funct3[0];  // Division: 0=Signed, 1=Unsigned
    else MCycleOp[0] = Funct3[1];  // Mult: 00=Mul, 01=MulH, etc.
  end

  // Multi-Cycle Result Select (High vs Low bits)
  always @(*) begin
    case (Funct3)
      3'b000:  MCycleResultSel = 1'b0;  // MUL (Low)
      3'b100:  MCycleResultSel = 1'b0;  // DIV (Quotient)
      3'b101:  MCycleResultSel = 1'b0;  // DIVU (Quotient)
      default: MCycleResultSel = 1'b1;  // High/Remainder
    endcase
  end

endmodule
