`timescale 1ns / 1ps

module RV #(
    parameter PC_INIT = 32'h00400000
) (
    input CLK,
    input RESET,
    input [31:0] Instr,
    input [31:0] ReadData_in,  // Raw memory input
    output MemRead,
    output [3:0] MemWrite_out,  // Byte enable mask
    output [31:0] PC,
    output [31:0] ComputeResultM,
    output [31:0] WriteData_out  // Aligned memory write data
);

  // ===========================================================================
  // WIRE DECLARATIONS (By Stage)
  // ===========================================================================

  // --- IF Stage (Fetch) ---
  wire [31:0] PCF;  // Current PC
  wire [31:0] InstrF;  // Fetched Instruction
  wire        StallF;  // Stall Fetch
  wire [31:0] PC_IN;  // Next PC
  wire [31:0] PC_Offset;  // PC Calculation
  reg  [31:0] PC_Base;  // PC Calculation

  // --- ID Stage (Decode) ---
  wire [31:0] PCD;
  wire [31:0] InstrD;
  wire        StallD;
  wire        FlushD;
  wire [ 6:0] OpcodeD;
  wire [ 6:0] Funct7D;
  wire [ 2:0] Funct3D;
  wire [ 4:0] rs1D;
  wire [ 4:0] rs2D;
  wire [ 4:0] rdD;
  wire [31:0] RD1D;  // Raw Register Data
  wire [31:0] RD2D;
  wire [31:0] RD1D_Forwarded;  // Data after Decode Forwarding
  wire [31:0] RD2D_Forwarded;
  wire [31:0] ExtImmD;
  // Control Signals
  wire        RegWriteD;
  wire        MemtoRegD;
  wire        MemWriteD;
  wire [ 1:0] ALUSrcAD;
  wire [ 1:0] ALUSrcBD;
  wire [ 3:0] ALUControlD;
  wire [ 1:0] PCSD;
  wire        ComputeResultSelD;
  wire        MCycleResultSelD;
  wire        MCycleStartD;
  wire [ 1:0] MCycleOpD;
  wire [ 2:0] ImmSrc;
  wire [ 2:0] SizeSel;  // For LoadStore Unit

  // --- EX Stage (Execute) ---
  wire [31:0] PCE;
  wire [31:0] RD1E;
  wire [31:0] RD2E;
  wire [31:0] ExtImmE;
  wire [ 4:0] rs1E;
  wire [ 4:0] rs2E;
  wire [ 4:0] rdE;
  wire [ 2:0] Funct3E;
  // ALU / MCycle Signals
  reg  [31:0] Src_A;  // ALU Inputs
  reg  [31:0] Src_B;
  reg  [31:0] RD1E_Forwarded;  // Hazard Mux Outputs
  reg  [31:0] RD2E_Forwarded;
  wire [31:0] ALUResultE;
  wire [ 2:0] ALUFlags;
  wire [31:0] MCycleResult;
  wire [31:0] MCycleResult_1;
  wire [31:0] MCycleResult_2;
  wire [31:0] ComputeResultE;  // Final result of Execute Stage
  // Control Signals
  wire        RegWriteE;
  wire        MemtoRegE;
  wire        MemWriteE;
  wire [ 1:0] ALUSrcAE;
  wire [ 1:0] ALUSrcBE;
  wire [ 3:0] ALUControlE;
  wire [ 1:0] PCSE;
  wire        ComputeResultSelE;
  wire        MCycleResultSelE;
  wire        MCycleStartE;
  wire [ 1:0] MCycleOpE;
  wire        Busy;  // Multi-Cycle Busy
  wire [ 1:0] PCSrcE;  // PC Branch Decision
  wire        FlushE;

  // --- MEM Stage (Memory) ---
  wire [31:0] WriteDataE;  // Data to be written (pre-alignment)
  wire [31:0] WriteDataM;  // Data to be written (at Memory stage)
  wire [31:0] ReadDataM;  // Data read from memory (Aligned)
  wire        RegWriteM;
  wire        MemtoRegM;
  wire        MemWriteM;
  wire [ 2:0] Funct3M;
  wire [ 4:0] rdM;
  wire [ 4:0] rs2M;
  wire [31:0] WriteDataM_Raw;  // Before LSU processing

  // --- WB Stage (Writeback) ---
  wire        RegWriteW;
  wire        MemtoRegW;
  wire [31:0] ReadDataW;  // From Memory
  wire [31:0] ComputeResultW;  // From ALU/MCycle
  wire [31:0] ResultW;  // Final Result (The one that goes to RegFile)
  wire [31:0] WD;  // Write Data Port (Alias of ResultW)
  wire [ 4:0] rdW;

  // --- Hazard Unit Signals ---
  wire [ 1:0] ForwardAE;
  wire [ 1:0] ForwardBE;
  wire        ForwardM;
  wire        Forward1D;
  wire        Forward2D;
  wire        lwStall;

  // ===========================================================================
  // Data Path
  // ===========================================================================

  // --- Instruction & PC Logic ---
  assign InstrF = Instr;
  assign PC = PCF;
  assign WE_PC = ~Busy;  // Freeze PC if Multi-Cycle Unit is busy

  // PC Selection Logic
  assign PC_Offset = (PCSrcE[0] == 1) ? ExtImmE : 32'd4;
  always @(*) begin
    case (PCSrcE)
      2'b10, 2'b11: PC_Base = RD1E_Forwarded;  // JALR
      2'b01:        PC_Base = PCE;  // Branch/JAL
      default:      PC_Base = PCF;  // Sequential (2'b00)
    endcase
  end
  assign PC_IN = PC_Base + PC_Offset;

  // --- Decode Stage Forwarding ---
  assign RD1D_Forwarded = Forward1D ? ResultW : RD1D;
  assign RD2D_Forwarded = Forward2D ? ResultW : RD2D;

  // Decoder output splitting
  assign OpcodeD = InstrD[6:0];
  assign rdD = InstrD[11:7];
  assign Funct3D = InstrD[14:12];
  assign rs1D = InstrD[19:15];
  assign rs2D = InstrD[24:20];
  assign Funct7D = InstrD[31:25];

  // --- Execute Stage Logic ---
  // ALU Muxes
  always @(*) begin
    // ALU Source A Mux
    case (ALUSrcAE)
      2'b00:   Src_A = RD1E_Forwarded;
      2'b01:   Src_A = 32'b0;  // LUI
      2'b11:   Src_A = PCE;  // AUIPC/JAL
      default: Src_A = RD1E_Forwarded;
    endcase

    // ALU Source B Mux
    case (ALUSrcBE)
      2'b00:   Src_B = RD2E_Forwarded;
      2'b01:   Src_B = 32'd4;  // JAL/JALR return
      2'b11:   Src_B = ExtImmE;  // Immediate
      default: Src_B = RD2E_Forwarded;
    endcase
  end

  // Hazard Muxes (Forwarding Logic)
  always @(*) begin
    case (ForwardAE)
      2'b00:   RD1E_Forwarded = RD1E;
      2'b01:   RD1E_Forwarded = ResultW;  // Forward from WB
      2'b10:   RD1E_Forwarded = ComputeResultM;  // Forward from MEM
      default: RD1E_Forwarded = RD1E;
    endcase

    case (ForwardBE)
      2'b00:   RD2E_Forwarded = RD2E;
      2'b01:   RD2E_Forwarded = ResultW;  // Forward from WB
      2'b10:   RD2E_Forwarded = ComputeResultM;  // Forward from MEM
      default: RD2E_Forwarded = RD2E;
    endcase
  end

  // Multiply/Divide Unit Result Selection
  assign MCycleResult = (MCycleResultSelE) ? MCycleResult_2 : MCycleResult_1;

  // Final Execute Result Select (ALU vs MCycle)
  assign ComputeResultE = (ComputeResultSelE) ? MCycleResult : ALUResultE;

  // Data to be stored (Passes to M stage)
  assign WriteDataE = RD2E_Forwarded;

  // --- Memory Stage Logic ---
  assign MemRead = MemtoRegM;  // Simple read enable

  // Handle Store Data Forwarding (M Stage)
  assign WriteDataM_Raw = ForwardM ? ResultW : WriteDataM;

  // --- Writeback Stage Logic ---
  assign ResultW = MemtoRegW ? ReadDataW : ComputeResultW;
  assign WD = ResultW;  // Data to RegFile
  assign WE = RegWriteW;  // WE to RegFile

  // ===========================================================================
  // MODULE INSTANTIATIONS
  // ===========================================================================

  ProgramCounter #(
      .PC_INIT(PC_INIT)
  ) ProgramCounter1 (
      .CLK(CLK),
      .RESET(RESET),
      .StallF(StallF),
      .PC_IN(PC_IN),
      .PC(PCF)
  );

  pipeline_D pipelineD (
      .CLK(CLK),
      .RESET(RESET),
      .StallD(StallD),
      .FlushD(FlushD),
      .InstrF(InstrF),
      .PCF(PCF),
      .InstrD(InstrD),
      .PCD(PCD)
  );

  Decoder Decoder1 (
      .Opcode(OpcodeD),
      .Funct3(Funct3D),
      .Funct7(Funct7D),
      .PCS(PCSD),
      .RegWrite(RegWriteD),
      .MemWrite(MemWriteD),
      .MemtoReg(MemtoRegD),
      .ALUSrcA(ALUSrcAD),
      .ALUSrcB(ALUSrcBD),
      .ImmSrc(ImmSrc),
      .ALUControl(ALUControlD),
      .ComputeResultSel(ComputeResultSelD),
      .MCycleResultSel(MCycleResultSelD),
      .MCycleStart(MCycleStartD),
      .MCycleOp(MCycleOpD),
      .SizeSel(SizeSel)
  );

  Extend Extend1 (
      .ImmSrc  (ImmSrc),
      .InstrImm(InstrD[31:7]),
      .ExtImm  (ExtImmD)
  );

  RegFile RegFile1 (
      .CLK(CLK),
      .WE (WE),
      .rs1(rs1D),
      .rs2(rs2D),
      .rd (rdW),
      .WD (WD),
      .RD1(RD1D),
      .RD2(RD2D)
  );

  pipeline_E pipelineE (
      .CLK(CLK),
      .RESET(RESET),
      .Busy(Busy),
      .FlushE(FlushE),
      .PCSD(PCSD),
      .RegWriteD(RegWriteD),
      .MemtoRegD(MemtoRegD),
      .MemWriteD(MemWriteD),
      .ALUControlD(ALUControlD),
      .ALUSrcAD(ALUSrcAD),
      .ALUSrcBD(ALUSrcBD),
      .RD1D(RD1D_Forwarded),
      .RD2D(RD2D_Forwarded),
      .ExtImmD(ExtImmD),
      .rs1D(rs1D),
      .rs2D(rs2D),
      .rdD(rdD),
      .PCD(PCD),
      .Funct3D(Funct3D),
      .MCycleOpD(MCycleOpD),
      .MCycleStartD(MCycleStartD),
      .MCycleResultSelD(MCycleResultSelD),
      .ComputeResultSelD(ComputeResultSelD),
      // Outputs
      .PCSE(PCSE),
      .RegWriteE(RegWriteE),
      .MemtoRegE(MemtoRegE),
      .MemWriteE(MemWriteE),
      .ALUControlE(ALUControlE),
      .ALUSrcAE(ALUSrcAE),
      .ALUSrcBE(ALUSrcBE),
      .RD1E(RD1E),
      .RD2E(RD2E),
      .ExtImmE(ExtImmE),
      .rs1E(rs1E),
      .rs2E(rs2E),
      .rdE(rdE),
      .PCE(PCE),
      .Funct3E(Funct3E),
      .MCycleOpE(MCycleOpE),
      .MCycleStartE(MCycleStartE),
      .MCycleResultSelE(MCycleResultSelE),
      .ComputeResultSelE(ComputeResultSelE)
  );

  ALU ALU1 (
      .Src_A(Src_A),
      .Src_B(Src_B),
      .ALUControl(ALUControlE),
      .ALUResult(ALUResultE),
      .ALUFlags(ALUFlags)
  );

  MCycle #(
      .width(32)
  ) MCycle1 (
      .CLK(CLK),
      .RESET(RESET),
      .Start(MCycleStartE),
      .MCycleOp(MCycleOpE),
      .Operand1(RD1E_Forwarded),
      .Operand2(RD2E_Forwarded),
      .Result1(MCycleResult_1),
      .Result2(MCycleResult_2),
      .Busy(Busy)
  );

  PC_Logic PC_Logic1 (
      .PCS(PCSE),
      .Funct3(Funct3E),
      .ALUFlags(ALUFlags),
      .PCSrc(PCSrcE)
  );

  pipeline_M pipelineM (
      .CLK(CLK),
      .RESET(RESET),
      .Busy(Busy),
      .RegWriteE(RegWriteE),
      .MemtoRegE(MemtoRegE),
      .MemWriteE(MemWriteE),
      .Funct3E(Funct3E),
      .ComputeResultE(ComputeResultE),
      .WriteDataE(WriteDataE),
      .rs2E(rs2E),
      .rdE(rdE),
      // Outputs
      .RegWriteM(RegWriteM),
      .MemtoRegM(MemtoRegM),
      .MemWriteM(MemWriteM),
      .Funct3M(Funct3M),
      .ComputeResultM(ComputeResultM),
      .WriteDataM(WriteDataM),
      .rs2M(rs2M),
      .rdM(rdM)
  );

  LoadStoreUnit LoadStoreUnit (
      .Funct3       (Funct3M),
      .MemWriteM    (MemWriteM),
      .WriteDataM   (WriteDataM_Raw),
      .ReadData_in  (ReadData_in),
      .ByteOffset   (ComputeResultM[1:0]),
      // Outputs
      .MemWrite_out (MemWrite_out),
      .WriteData_out(WriteData_out),
      .ReadDataM    (ReadDataM)
  );

  pipeline_W pipelineW (
      .CLK(CLK),
      .RESET(RESET),
      .RegWriteM(RegWriteM),
      .MemtoRegM(MemtoRegM),
      .ReadDataM(ReadDataM),
      .ComputeResultM(ComputeResultM),
      .rdM(rdM),
      // Outputs
      .RegWriteW(RegWriteW),
      .MemtoRegW(MemtoRegW),
      .ReadDataW(ReadDataW),
      .ComputeResultW(ComputeResultW),
      .rdW(rdW)
  );

  Hazard Hazard1 (
      .rs1D(rs1D),
      .rs2D(rs2D),
      .rs1E(rs1E),
      .rs2E(rs2E),
      .rs2M(rs2M),
      .rdE(rdE),
      .rdM(rdM),
      .rdW(rdW),
      .RegWriteM(RegWriteM),
      .RegWriteW(RegWriteW),
      .MemWriteM(MemWriteM),
      .MemtoRegW(MemtoRegW),
      .MemtoRegE(MemtoRegE),
      .Busy(Busy),
      .PCSrcE(PCSrcE),
      // Outputs
      .ForwardAE(ForwardAE),
      .ForwardBE(ForwardBE),
      .ForwardM(ForwardM),
      .lwStall(lwStall),
      .StallF(StallF),
      .StallD(StallD),
      .FlushE(FlushE),
      .FlushD(FlushD),
      .Forward1D(Forward1D),
      .Forward2D(Forward2D)
  );

endmodule
