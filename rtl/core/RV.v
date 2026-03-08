/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   RV
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Top-level RISC-V Processor Core.
--                (2-Way Superscalar)
--                Instantiates and connects the 5 pipeline stages, Hazard Unit, 
--                Forwarding logic, Instruction Issue Unit, and BPU.
-- 
-- Credits:       First version collaborated with Hieu and Max.
--                Architecture based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module RV #(
        parameter PC_INIT = 32'h00400000
    ) (
        input         CLK,
        input         RESET,
        input  [31:0] Instr_1,
        input  [31:0] Instr_2,
        input  [31:0] ReadData_in,
        output        MemRead,
        output [ 3:0] MemWrite_out,
        output [31:0] PC,
        output [31:0] ComputeResultM,
        output [31:0] WriteData_out
    );

    // ===========================================================================
    // WIRE DECLARATIONS (Grouped & Documented)
    // ===========================================================================

    // ---------------------------------------------------------------------------
    // Fetch Stage (F) Signals
    // ---------------------------------------------------------------------------
    wire [31:0] PCF;            // Program Counter at Fetch
    wire [31:0] PC_IN;          // Next Program Counter input
    wire [31:0] PCPlus4F;       // PC + 4 (Sequential)
    wire        StallF;         // Stall signal for Fetch stage
    wire        WE_PC;          // Write Enable for Program Counter
    wire        PrPCSrcF;       // Predicted PC Source
    wire [31:0] PrBTAF;         // Predicted Branch Target Address
    wire [31:0] Instr_1_Issued; // Issued Instruction 1
    wire [31:0] Instr_2_Issued; // Issued Instruction 2

    // ---------------------------------------------------------------------------
    // Decode Stage (D) Signals - Common
    // ---------------------------------------------------------------------------
    wire [31:0] PCD;            // Program Counter at Decode
    wire        StallD;         // Stall signal for Decode stage
    wire        FlushD;         // Flush signal for Decode stage
    wire [31:0] InstrD_1_raw;   // Raw Instruction 1 from Pipeline D
    wire [31:0] InstrD_2_raw;   // Raw Instruction 2 from Pipeline D
    wire [31:0] PCD_1_Issued;
    wire [31:0] PCD_2_Issued;
    wire [31:0] PCE_1;
    wire [31:0] PCE_2;

    // ---------------------------------------------------------------------------
    // Decode Stage (D) Signals - Pipe 1
    // ---------------------------------------------------------------------------
    wire [31:0] InstrD_1;       // Processed Instruction 1
    wire [31:0] RD1D_1;         // Read Data 1 for Pipe 1
    wire [31:0] RD2D_1;         // Read Data 2 for Pipe 1
    wire [31:0] RD1D_Forwarded_1; // Forwarded Read Data 1
    wire [31:0] RD2D_Forwarded_1; // Forwarded Read Data 2
    wire [31:0] ExtImmD_1;      // Extended Immediate for Pipe 1
    wire [ 6:0] OpcodeD_1;      // Opcode for Pipe 1
    wire [ 6:0] Funct7D_1;      // Funct7 for Pipe 1
    wire [ 2:0] Funct3D_1;      // Funct3 for Pipe 1
    wire [ 2:0] ImmSrc_1;       // Immediate Source Selector for Pipe 1
    wire [ 2:0] SizeSel_1;      // Size Selector for Pipe 1
    wire [ 4:0] rs1D_1;         // Source Register 1 Address
    wire [ 4:0] rs2D_1;         // Source Register 2 Address
    wire [ 4:0] rdD_1;          // Destination Register Address
    wire        PrPCSrcD;       // Predicted PC Source at Decode
    wire [31:0] PrBTAD;         // Predicted Branch Target at Decode
    wire        RegWriteD_1;    // Register Write Enable for Pipe 1
    wire        MemtoRegD_1;    // Memory to Register Select
    wire        MemWriteD_1;    // Memory Write Enable
    wire [ 1:0] ALUSrcAD_1;     // ALU Source A Select
    wire [ 1:0] ALUSrcBD_1;     // ALU Source B Select
    wire [ 1:0] PCSD_1;         // PC Source Select
    wire [ 1:0] MCycleOpD_1;    // Multi-Cycle Operation Select
    wire [ 3:0] ALUControlD_1;  // ALU Control for Pipe 1
    wire        ComputeResultSelD_1; // Compute Result Selector
    wire        MCycleResultSelD_1;  // Multi-Cycle Result Selector
    wire        MCycleStartD_1;      // Start signal for Multi-Cycle

    // ---------------------------------------------------------------------------
    // Decode Stage (D) Signals - Pipe 2
    // ---------------------------------------------------------------------------
    wire [31:0] InstrD_2;       // Processed Instruction 2
    wire [31:0] RD1D_2;         // Read Data 1 for Pipe 2
    wire [31:0] RD2D_2;         // Read Data 2 for Pipe 2
    wire [31:0] RD1D_Forwarded_2; // Forwarded Read Data 1
    wire [31:0] RD2D_Forwarded_2; // Forwarded Read Data 2
    wire [31:0] ExtImmD_2;      // Extended Immediate for Pipe 2
    wire [ 6:0] OpcodeD_2;      // Opcode for Pipe 2
    wire [ 6:0] Funct7D_2;      // Funct7 for Pipe 2
    wire [ 2:0] Funct3D_2;      // Funct3 for Pipe 2
    wire [ 2:0] ImmSrc_2;       // Immediate Source Selector
    wire [ 4:0] rs1D_2;         // Source Register 1 Address
    wire [ 4:0] rs2D_2;         // Source Register 2 Address
    wire [ 4:0] rdD_2;          // Destination Register Address
    wire        RegWriteD_2;    // Register Write Enable for Pipe 2
    wire        MemWriteD_2;    // Memory Write Enable for Pipe 2
    wire [ 1:0] ALUSrcAD_2;     // ALU Source A Select
    wire [ 1:0] ALUSrcBD_2;     // ALU Source B Select
    wire [ 3:0] ALUControlD_2;  // ALU Control for Pipe 2

    // ---------------------------------------------------------------------------
    // Execute Stage (E) Signals - Common
    // ---------------------------------------------------------------------------
    // wire [31:0] PCE;         // Program Counter at Execute
    wire        Busy;           // Multi-Cycle unit busy flag
    wire        FlushE;         // Flush signal for Execute stage

    // ---------------------------------------------------------------------------
    // Execute Stage (E) Signals - Pipe 1
    // ---------------------------------------------------------------------------
    wire [31:0] RD1E_1;         // Read Data 1
    wire [31:0] RD2E_1;         // Read Data 2
    wire [31:0] ExtImmE_1;      // Extended Immediate
    wire [ 4:0] rs1E_1;         // Source Register 1 Address
    wire [ 4:0] rs2E_1;         // Source Register 2 Address
    wire [ 4:0] rdE_1;          // Destination Register Address
    wire [ 2:0] Funct3E_1;      // Funct3
    wire        RegWriteE_1;    // Register Write Enable
    wire        MemtoRegE_1;    // Memory to Register Select
    wire        MemWriteE_1;    // Memory Write Enable
    wire [ 1:0] ALUSrcAE_1;     // ALU Source A Select
    wire [ 1:0] ALUSrcBE_1;     // ALU Source B Select
    wire [ 1:0] PCSE;           // PC Source Select
    wire [ 1:0] MCycleOpE;      // Multi-Cycle Operation Select
    wire [ 3:0] ALUControlE_1;  // ALU Control
    wire        ComputeResultSelE_1; // Compute Result Selector
    wire        MCycleResultSelE_1;  // Multi-Cycle Result Selector
    wire        MCycleStartE;   // Start signal for Multi-Cycle
    wire        PrPCSrcE;       // Predicted PC Source
    wire [31:0] PrBTAE;         // Predicted Branch Target Address
    wire [31:0] MCycleResult_1; // Multi-Cycle Result 1
    wire [31:0] MCycleResult_2; // Multi-Cycle Result 2
    wire [31:0] MCycleResult;   // Selected Multi-Cycle Result
    wire [31:0] ALUResultE_1;   // ALU Output for Pipe 1
    wire [ 2:0] ALUFlagsE_1;    // ALU Flags for Pipe 1
    wire [31:0] ComputeResultE_1; // Final Computed Result for Pipe 1
    wire [31:0] WriteDataE_1;   // Data to write to memory (Pipe 1)

    // ---------------------------------------------------------------------------
    // Execute Stage (E) Signals - Pipe 2
    // ---------------------------------------------------------------------------
    wire [31:0] RD1E_2;         // Read Data 1
    wire [31:0] RD2E_2;         // Read Data 2
    wire [31:0] ExtImmE_2;      // Extended Immediate
    wire [31:0] WriteDataE_2;   // Data to write to memory (Pipe 2)
    wire [ 4:0] rs1E_2;         // Source Register 1 Address
    wire [ 4:0] rs2E_2;         // Source Register 2 Address
    wire [ 4:0] rdE_2;          // Destination Register Address
    wire        RegWriteE_2;    // Register Write Enable
    wire        MemWriteE_2;    // Memory Write Enable
    wire [ 2:0] Funct3E_2;      // Funct3
    wire [ 1:0] ALUSrcAE_2;     // ALU Source A Select
    wire [ 1:0] ALUSrcBE_2;     // ALU Source B Select
    wire [ 3:0] ALUControlE_2;  // ALU Control
    wire [31:0] ALUResultE_2;   // ALU Output for Pipe 2
    wire [ 2:0] ALUFlagsE_2;    // ALU Flags for Pipe 2
    wire [31:0] ComputeResultE_2; // Final Computed Result for Pipe 2

    // ---------------------------------------------------------------------------
    // Memory Stage (M) Signals - Common & Branches
    // ---------------------------------------------------------------------------
    wire [31:0] PCM;            // Program Counter at Memory stage
    wire        FlushM;         // Flush signal for Memory stage
    wire [31:0] PC_ResolvedM;   // Resolved Branch PC
    wire [ 1:0] PCSM;           // PC Source Select
    wire [ 1:0] PCSrcM;         // Final PC Source
    wire        PrPCSrcM;       // Predicted PC Source
    wire        MispredPCSrcM;  // Branch Source Misprediction Flag
    wire        MispredBTAM;    // Branch Target Misprediction Flag
    wire        BranchMispredictM; // Overall Branch Misprediction Flag
    wire [31:0] PrBTAM;         // Predicted Branch Target Address

    // ---------------------------------------------------------------------------
    // Memory Stage (M) Signals - Pipe 1
    // ---------------------------------------------------------------------------
    wire [31:0] ComputeResultM_1; // Computed Address/Result
    wire [31:0] WriteDataM_1;     // Data to Write
    wire [31:0] RD1M_1;           // Read Data 1 forwarded
    wire [31:0] ExtImmM_1;        // Extended Immediate
    wire [ 4:0] rs2M_1;           // Source Register 2
    wire [ 4:0] rdM_1;            // Destination Register
    wire [ 2:0] Funct3M_1;        // Funct3
    wire [ 2:0] ALUFlagsM_1;      // ALU Flags
    wire        RegWriteM_1;      // Register Write Enable
    wire        MemtoRegM_1;      // Memory to Register Select
    wire        MemWriteM_1;      // Memory Write Enable
    wire [31:0] WriteDataM_Raw_1; // Unmultiplexed Write Data

    // ---------------------------------------------------------------------------
    // Memory Stage (M) Signals - Pipe 2
    // ---------------------------------------------------------------------------
    wire [31:0] ComputeResultM_2; // Computed Address/Result
    wire [31:0] WriteDataM_2;     // Data to Write
    wire [31:0] WriteDataM_Raw_2; // Unmultiplexed Write Data
    wire [ 4:0] rs2M_2;           // Source Register 2
    wire [ 4:0] rdM_2;            // Destination Register
    wire [ 2:0] Funct3M_2;        // Funct3
    wire        RegWriteM_2;      // Register Write Enable
    wire        MemWriteM_2;      // Memory Write Enable

    // ---------------------------------------------------------------------------
    // Writeback Stage (W) Signals - Pipe 1
    // ---------------------------------------------------------------------------
    wire [31:0] ComputeResultW_1; // Computed Result
    wire [31:0] ReadDataW_1;      // Read Data from Memory
    wire [31:0] ReadDataW_Aligned_1; // Aligned Read Data
    wire [31:0] ResultW_1;        // Final Result to Writeback
    wire [ 4:0] rdW_1;            // Destination Register Address
    wire [ 2:0] Funct3W_1;        // Funct3
    wire        RegWriteW_1;      // Register Write Enable
    wire        MemtoRegW_1;      // Memory to Register Select

    // ---------------------------------------------------------------------------
    // Writeback Stage (W) Signals - Pipe 2
    // ---------------------------------------------------------------------------
    wire [31:0] ComputeResultW_2; // Computed Result
    wire [31:0] ResultW_2;        // Final Result to Writeback
    wire [ 4:0] rdW_2;            // Destination Register Address
    wire        RegWriteW_2;      // Register Write Enable

    // ---------------------------------------------------------------------------
    // Hazard & Forwarding Signals
    // ---------------------------------------------------------------------------
    wire [ 2:0] ForwardAE_1;      // Forwarding control for Pipe 1 Src A
    wire [ 2:0] ForwardBE_1;      // Forwarding control for Pipe 1 Src B
    wire [ 2:0] ForwardAE_2;      // Forwarding control for Pipe 2 Src A
    wire [ 2:0] ForwardBE_2;      // Forwarding control for Pipe 2 Src B
    wire        ForwardM_1_W1;    // Memory forwarding Pipe 1 from W1
    wire        ForwardM_1_W2;    // Memory forwarding Pipe 1 from W2
    wire        ForwardM_2_W1;    // Memory forwarding Pipe 2 from W1
    wire        ForwardM_2_W2;    // Memory forwarding Pipe 2 from W2
    wire [1:0]  Forward1D_1; // Decode forwarding Pipe 1 Src 1
    wire [1:0]  Forward2D_1; // Decode forwarding Pipe 1 Src 2
    wire [1:0]  Forward1D_2; // Decode forwarding Pipe 2 Src 1
    wire [1:0]  Forward2D_2; // Decode forwarding Pipe 2 Src 2
    wire        lwStall;          // Load-word stall flag

    // ---------------------------------------------------------------------------
    // Internal Logic & Flow Control Declarations
    // ---------------------------------------------------------------------------
    wire        Rollback;
    wire        Hold_Is_Branch;
    wire [31:0] Hold_PC;
    wire [31:0] BPU_PC = (Hold_Is_Branch) ? Hold_PC : PCF;
    wire [31:0] PC_Seq = Rollback ? (PCF + 32'd4) : (PCF + 32'd8);
    wire [31:0] PC_Pred = PrPCSrcF ? PrBTAF : PC_Seq;
    wire [31:0] PC_Offset = (PCSrcM[0] == 1) ? ExtImmM_1 : 32'd4;
    wire [31:0] PC_Base = (PCSrcM[1] == 1) ? RD1M_1 : PCM;

    // Memory Multiplexer Helpers
    wire        Master_MemWrite = MemWriteM_1 | MemWriteM_2;
    wire [ 2:0] Master_Funct3   = MemWriteM_1 ? Funct3M_1 : Funct3M_2;
    wire [31:0] Master_Data     = MemWriteM_1 ? WriteDataM_Raw_1 : WriteDataM_Raw_2;
    wire [31:0] Master_Addr     = MemWriteM_1 ? ComputeResultM_1 : (MemWriteM_2 ? ComputeResultM_2 : ComputeResultM_1);

    // Forwarding logic register vars
    reg [31:0] RD1E_Forwarded_1;
    reg [31:0] RD2E_Forwarded_1;
    reg [31:0] RD1E_Forwarded_2;
    reg [31:0] RD2E_Forwarded_2;
    reg [31:0] Src_A_1;
    reg [31:0] Src_B_1;
    reg [31:0] Src_A_2;
    reg [31:0] Src_B_2;

    // ===========================================================================
    // Data Path & Logic
    // ===========================================================================
    assign PC = PCF;
    assign WE_PC = ~Busy;

    assign PC_ResolvedM = PC_Base + PC_Offset;
    assign MispredPCSrcM = (PrPCSrcM != PCSrcM[0]);
    assign MispredBTAM = (PCSrcM[0] == 1'b1) && (PrBTAM != PC_ResolvedM);
    assign BranchMispredictM = MispredPCSrcM | MispredBTAM;
    assign PC_IN = BranchMispredictM ? PC_ResolvedM : PC_Pred;

    assign OpcodeD_1 = InstrD_1[6:0];
    assign rdD_1 = InstrD_1[11:7];
    assign Funct3D_1 = InstrD_1[14:12];
    assign rs1D_1 = InstrD_1[19:15];
    assign rs2D_1 = InstrD_1[24:20];
    assign Funct7D_1 = InstrD_1[31:25];

    assign OpcodeD_2 = InstrD_2[6:0];
    assign rdD_2 = InstrD_2[11:7];
    assign Funct3D_2 = InstrD_2[14:12];
    assign rs1D_2 = InstrD_2[19:15];
    assign rs2D_2 = InstrD_2[24:20];
    assign Funct7D_2 = InstrD_2[31:25];

    assign RD1D_Forwarded_1 = (Forward1D_1 == 2'b10) ? ResultW_2 :
           (Forward1D_1 == 2'b01) ? ResultW_1 : RD1D_1;

    assign RD2D_Forwarded_1 = (Forward2D_1 == 2'b10) ? ResultW_2 :
           (Forward2D_1 == 2'b01) ? ResultW_1 : RD2D_1;

    assign RD1D_Forwarded_2 = (Forward1D_2 == 2'b10) ? ResultW_2 :
           (Forward1D_2 == 2'b01) ? ResultW_1 : RD1D_2;

    assign RD2D_Forwarded_2 = (Forward2D_2 == 2'b10) ? ResultW_2 :
           (Forward2D_2 == 2'b01) ? ResultW_1 : RD2D_2;

    always @(*) begin
        case (ForwardAE_1)
            3'd4:
                RD1E_Forwarded_1 = ComputeResultM_2;
            3'd3:
                RD1E_Forwarded_1 = ComputeResultM_1;
            3'd2:
                RD1E_Forwarded_1 = ResultW_2;
            3'd1:
                RD1E_Forwarded_1 = ResultW_1;
            default:
                RD1E_Forwarded_1 = RD1E_1;
        endcase
        case (ForwardBE_1)
            3'd4:
                RD2E_Forwarded_1 = ComputeResultM_2;
            3'd3:
                RD2E_Forwarded_1 = ComputeResultM_1;
            3'd2:
                RD2E_Forwarded_1 = ResultW_2;
            3'd1:
                RD2E_Forwarded_1 = ResultW_1;
            default:
                RD2E_Forwarded_1 = RD2E_1;
        endcase
        case (ForwardAE_2)
            3'd4:
                RD1E_Forwarded_2 = ComputeResultM_2;
            3'd3:
                RD1E_Forwarded_2 = ComputeResultM_1;
            3'd2:
                RD1E_Forwarded_2 = ResultW_2;
            3'd1:
                RD1E_Forwarded_2 = ResultW_1;
            default:
                RD1E_Forwarded_2 = RD1E_2;
        endcase
        case (ForwardBE_2)
            3'd4:
                RD2E_Forwarded_2 = ComputeResultM_2;
            3'd3:
                RD2E_Forwarded_2 = ComputeResultM_1;
            3'd2:
                RD2E_Forwarded_2 = ResultW_2;
            3'd1:
                RD2E_Forwarded_2 = ResultW_1;
            default:
                RD2E_Forwarded_2 = RD2E_2;
        endcase
    end

    always @(*) begin
        case (ALUSrcAE_1)
            2'b00:
                Src_A_1 = RD1E_Forwarded_1;
            2'b01:
                Src_A_1 = 32'b0;
            2'b11:
                Src_A_1 = PCE_1;
            default:
                Src_A_1 = RD1E_Forwarded_1;
        endcase
        case (ALUSrcBE_1)
            2'b00:
                Src_B_1 = RD2E_Forwarded_1;
            2'b01:
                Src_B_1 = 32'd4;
            2'b11:
                Src_B_1 = ExtImmE_1;
            default:
                Src_B_1 = RD2E_Forwarded_1;
        endcase
        case (ALUSrcAE_2)
            2'b00:
                Src_A_2 = RD1E_Forwarded_2;
            2'b01:
                Src_A_2 = 32'b0;
            2'b11:
                Src_A_2 = PCE_2;
            default:
                Src_A_2 = RD1E_Forwarded_2;
        endcase
        case (ALUSrcBE_2)
            2'b00:
                Src_B_2 = RD2E_Forwarded_2;
            2'b01:
                Src_B_2 = 32'd4;
            2'b11:
                Src_B_2 = ExtImmE_2;
            default:
                Src_B_2 = RD2E_Forwarded_2;
        endcase
    end

    assign MCycleResult = (MCycleResultSelE_1) ? MCycleResult_2 : MCycleResult_1;
    assign ComputeResultE_1 = (ComputeResultSelE_1) ? MCycleResult : ALUResultE_1;
    assign ComputeResultE_2 = ALUResultE_2;
    assign WriteDataE_1 = RD2E_Forwarded_1;
    assign WriteDataE_2 = RD2E_Forwarded_2; // <-- Pipe 2 Store Data

    // --- Superscalar Memory Multiplexing ---
    assign WriteDataM_Raw_1 = ForwardM_1_W2 ? ResultW_2 : (ForwardM_1_W1 ? ResultW_1 : WriteDataM_1);
    assign WriteDataM_Raw_2 = ForwardM_2_W2 ? ResultW_2 : (ForwardM_2_W1 ? ResultW_1 : WriteDataM_2);

    // Because IIU prevents simultaneous memory instructions, we can safely MUX the single port:
    assign MemRead = MemtoRegM_1; // Loads are strictly Pipe 1
    assign ComputeResultM = Master_Addr; // Outputs the active address to the Wrapper

    assign ResultW_1 = MemtoRegW_1 ? ReadDataW_Aligned_1 : ComputeResultW_1;
    assign ResultW_2 = ComputeResultW_2;

    // ===========================================================================
    // MODULE INSTANTIATIONS
    // ===========================================================================

    ProgramCounter #(
                       .PC_INIT(PC_INIT)
                   ) ProgramCounter1 (
                       .CLK    (CLK),
                       .RESET  (RESET),
                       .StallF (StallF),
                       .PC_IN  (PC_IN),
                       .PC     (PCF)
                   );

    IIU InstructionIssueUnit (
            .CLK            (CLK),
            .RESET          (RESET),
            .FlushD         (FlushD),
            .StallD         (StallD),
            .Instr_1_in     (InstrD_1_raw),
            .Instr_2_in     (InstrD_2_raw),
            .PCD            (PCD),
            .PrPCSrcD       (PrPCSrcD),
            .Instr_1_out    (InstrD_1),
            .Instr_2_out    (InstrD_2),
            .PCD_1_out      (PCD_1_Issued),
            .PCD_2_out      (PCD_2_Issued),
            .Rollback       (Rollback),
            .Hold_PC        (Hold_PC),
            .Hold_Is_Branch (Hold_Is_Branch)
        );

    pipeline_D pipelineD (
                   .CLK        (CLK),
                   .RESET      (RESET),
                   .StallD     (StallD),
                   .FlushD     (FlushD),
                   .InstrF_1   (Instr_1),
                   .InstrF_2   (Instr_2),
                   .PCF        (PCF),
                   .PrPCSrcF   (PrPCSrcF),
                   .PrBTAF     (PrBTAF),
                   .PrPCSrcD   (PrPCSrcD),
                   .PrBTAD     (PrBTAD),
                   .InstrD_1   (InstrD_1_raw),
                   .InstrD_2   (InstrD_2_raw),
                   .PCD        (PCD)
               );

    Decoder Decoder1 (
                .Opcode           (OpcodeD_1),
                .Funct3           (Funct3D_1),
                .Funct7           (Funct7D_1),
                .PCS              (PCSD_1),
                .RegWrite         (RegWriteD_1),
                .MemWrite         (MemWriteD_1),
                .MemtoReg         (MemtoRegD_1),
                .ALUSrcA          (ALUSrcAD_1),
                .ALUSrcB          (ALUSrcBD_1),
                .ImmSrc           (ImmSrc_1),
                .ALUControl       (ALUControlD_1),
                .ComputeResultSel (ComputeResultSelD_1),
                .MCycleResultSel  (MCycleResultSelD_1),
                .MCycleStart      (MCycleStartD_1),
                .MCycleOp         (MCycleOpD_1),
                .SizeSel          (SizeSel_1)
            );

    Extend Extend1 (
               .ImmSrc   (ImmSrc_1),
               .InstrImm (InstrD_1[31:7]),
               .ExtImm   (ExtImmD_1)
           );

    Decoder Decoder2 (
                .Opcode     (OpcodeD_2),
                .Funct3     (Funct3D_2),
                .Funct7     (Funct7D_2),
                .RegWrite   (RegWriteD_2),
                .MemWrite   (MemWriteD_2),
                .ALUSrcA    (ALUSrcAD_2),
                .ALUSrcB    (ALUSrcBD_2),
                .ImmSrc     (ImmSrc_2),
                .ALUControl (ALUControlD_2),
                // Explicitly Unconnected Outputs (Pipe 1 Only Features)
                .PCS              (),
                .MemtoReg         (),
                .ComputeResultSel (),
                .MCycleResultSel  (),
                .MCycleStart      (),
                .MCycleOp         (),
                .SizeSel          ()
            );

    Extend Extend2 (
               .ImmSrc   (ImmSrc_2),
               .InstrImm (InstrD_2[31:7]),
               .ExtImm   (ExtImmD_2)
           );

    RegFile RegFile_Dual (
                .CLK   (CLK),
                .WE1   (RegWriteW_1),
                .rd1   (rdW_1),
                .WD1   (ResultW_1),
                .WE2   (RegWriteW_2),
                .rd2   (rdW_2),
                .WD2   (ResultW_2),
                .rs1_1 (rs1D_1),
                .rs2_1 (rs2D_1),
                .RD1_1 (RD1D_1),
                .RD2_1 (RD2D_1),
                .rs1_2 (rs1D_2),
                .rs2_2 (rs2D_2),
                .RD1_2 (RD1D_2),
                .RD2_2 (RD2D_2)
            );

    pipeline_E pipelineE (
                   .CLK               (CLK),
                   .RESET             (RESET),
                   .Busy              (Busy),
                   .FlushE            (FlushE),
                   .PCSD              (PCSD_1),
                   .RegWriteD_1       (RegWriteD_1),
                   .MemtoRegD_1       (MemtoRegD_1),
                   .MemWriteD_1       (MemWriteD_1),
                   .ALUControlD_1     (ALUControlD_1),
                   .ALUSrcAD_1        (ALUSrcAD_1),
                   .ALUSrcBD_1        (ALUSrcBD_1),
                   .RD1D_1            (RD1D_Forwarded_1),
                   .RD2D_1            (RD2D_Forwarded_1),
                   .ExtImmD_1         (ExtImmD_1),
                   .rs1D_1            (rs1D_1),
                   .rs2D_1            (rs2D_1),
                   .rdD_1             (rdD_1),
                   .PCD_1             (PCD_1_Issued),
                   .Funct3D_1         (Funct3D_1),
                   .MCycleOpD         (MCycleOpD_1),
                   .MCycleStartD      (MCycleStartD_1),
                   .MCycleResultSelD  (MCycleResultSelD_1),
                   .ComputeResultSelD (ComputeResultSelD_1),
                   .PrPCSrcD          (PrPCSrcD),
                   .PrBTAD            (PrBTAD),
                   .RegWriteD_2       (RegWriteD_2),
                   .MemWriteD_2       (MemWriteD_2),
                   .Funct3D_2         (Funct3D_2),
                   .ALUControlD_2     (ALUControlD_2),
                   .ALUSrcAD_2        (ALUSrcAD_2),
                   .ALUSrcBD_2        (ALUSrcBD_2),
                   .RD1D_2            (RD1D_Forwarded_2),
                   .RD2D_2            (RD2D_Forwarded_2),
                   .ExtImmD_2         (ExtImmD_2),
                   .rs1D_2            (rs1D_2),
                   .rs2D_2            (rs2D_2),
                   .rdD_2             (rdD_2),
                   .PCD_2             (PCD_2_Issued),
                   .PCSE              (PCSE),
                   .RegWriteE_1       (RegWriteE_1),
                   .MemtoRegE_1       (MemtoRegE_1),
                   .MemWriteE_1       (MemWriteE_1),
                   .ALUControlE_1     (ALUControlE_1),
                   .ALUSrcAE_1        (ALUSrcAE_1),
                   .ALUSrcBE_1        (ALUSrcBE_1),
                   .RD1E_1            (RD1E_1),
                   .RD2E_1            (RD2E_1),
                   .ExtImmE_1         (ExtImmE_1),
                   .rs1E_1            (rs1E_1),
                   .rs2E_1            (rs2E_1),
                   .rdE_1             (rdE_1),
                   .PCE_1             (PCE_1),
                   .Funct3E_1         (Funct3E_1),
                   .MCycleOpE         (MCycleOpE),
                   .MCycleStartE      (MCycleStartE),
                   .MCycleResultSelE  (MCycleResultSelE_1),
                   .ComputeResultSelE (ComputeResultSelE_1),
                   .PrPCSrcE          (PrPCSrcE),
                   .PrBTAE            (PrBTAE),
                   .RegWriteE_2       (RegWriteE_2),
                   .MemWriteE_2       (MemWriteE_2),
                   .Funct3E_2         (Funct3E_2),
                   .ALUControlE_2     (ALUControlE_2),
                   .ALUSrcAE_2        (ALUSrcAE_2),
                   .ALUSrcBE_2        (ALUSrcBE_2),
                   .RD1E_2            (RD1E_2),
                   .RD2E_2            (RD2E_2),
                   .ExtImmE_2         (ExtImmE_2),
                   .rs1E_2            (rs1E_2),
                   .rs2E_2            (rs2E_2),
                   .rdE_2             (rdE_2),
                   .PCE_2             (PCE_2)
               );

    ALU ALU1 (
            .Src_A      (Src_A_1),
            .Src_B      (Src_B_1),
            .ALUControl (ALUControlE_1),
            .ALUResult  (ALUResultE_1),
            .ALUFlags   (ALUFlagsE_1)
        );

    ALU ALU2 (
            .Src_A      (Src_A_2),
            .Src_B      (Src_B_2),
            .ALUControl (ALUControlE_2),
            .ALUResult  (ALUResultE_2),
            .ALUFlags   (ALUFlagsE_2)
        );

    MCycle #(
               .width(32)
           ) MCycle1 (
               .CLK      (CLK),
               .RESET    (RESET),
               .Start    (MCycleStartE & ~FlushE),
               .MCycleOp (MCycleOpE),
               .Operand1 (RD1E_Forwarded_1),
               .Operand2 (RD2E_Forwarded_1),
               .Result1  (MCycleResult_1),
               .Result2  (MCycleResult_2),
               .Busy     (Busy)
           );

    PC_Logic PC_Logic1 (
                 .PCS      (PCSM),
                 .Funct3   (Funct3M_1),
                 .ALUFlags (ALUFlagsM_1),
                 .PCSrc    (PCSrcM)
             );

    pipeline_M pipelineM (
                   .CLK              (CLK),
                   .RESET            (RESET),
                   .Busy             (Busy),
                   .FlushM           (FlushM),
                   .BranchMispredictM(BranchMispredictM),
                   .RegWriteE_1      (RegWriteE_1),
                   .MemtoRegE_1      (MemtoRegE_1),
                   .MemWriteE_1      (MemWriteE_1),
                   .ComputeResultE_1 (ComputeResultE_1),
                   .WriteDataE_1     (WriteDataE_1),
                   .rs2E_1           (rs2E_1),
                   .rdE_1            (rdE_1),
                   .Funct3E_1        (Funct3E_1),
                   .RD1E_Forwarded_1 (RD1E_Forwarded_1),
                   .PCE              (PCE_1),
                   .ExtImmE_1        (ExtImmE_1),
                   .PCSE             (PCSE),
                   .ALUFlagsE_1      (ALUFlagsE_1),
                   .PrPCSrcE         (PrPCSrcE),
                   .PrBTAE           (PrBTAE),
                   .RegWriteE_2      (RegWriteE_2),
                   .MemWriteE_2      (MemWriteE_2),
                   .Funct3E_2        (Funct3E_2),
                   .ComputeResultE_2 (ComputeResultE_2),
                   .WriteDataE_2     (WriteDataE_2),
                   .rs2E_2           (rs2E_2),
                   .rdE_2            (rdE_2),
                   .RegWriteM_1      (RegWriteM_1),
                   .MemtoRegM_1      (MemtoRegM_1),
                   .MemWriteM_1      (MemWriteM_1),
                   .Funct3M_1        (Funct3M_1),
                   .ComputeResultM_1 (ComputeResultM_1),
                   .WriteDataM_1     (WriteDataM_1),
                   .rs2M_1           (rs2M_1),
                   .rdM_1            (rdM_1),
                   .RD1M_1           (RD1M_1),
                   .PCM              (PCM),
                   .ExtImmM_1        (ExtImmM_1),
                   .PCSM             (PCSM),
                   .ALUFlagsM_1      (ALUFlagsM_1),
                   .PrPCSrcM         (PrPCSrcM),
                   .PrBTAM           (PrBTAM),
                   .RegWriteM_2      (RegWriteM_2),
                   .MemWriteM_2      (MemWriteM_2),
                   .Funct3M_2        (Funct3M_2),
                   .ComputeResultM_2 (ComputeResultM_2),
                   .WriteDataM_2     (WriteDataM_2),
                   .rs2M_2           (rs2M_2),
                   .rdM_2            (rdM_2)
               );

    StoreUnit StoreUnit (
                  .Funct3M       (Master_Funct3),
                  .MemWriteM     (Master_MemWrite),
                  .WriteDataM    (Master_Data),
                  .ByteOffset    (Master_Addr[1:0]),
                  .MemWrite_out  (MemWrite_out),
                  .WriteData_out (WriteData_out)
              );

    pipeline_W pipelineW (
                   .CLK              (CLK),
                   .RESET            (RESET),
                   .RegWriteM_1      (RegWriteM_1),
                   .MemtoRegM_1      (MemtoRegM_1),
                   .ReadDataM_1      (ReadData_in),
                   .ComputeResultM_1 (ComputeResultM_1),
                   .rdM_1            (rdM_1),
                   .Funct3M_1        (Funct3M_1),
                   .RegWriteM_2      (RegWriteM_2),
                   .ComputeResultM_2 (ComputeResultM_2),
                   .rdM_2            (rdM_2),
                   .RegWriteW_1      (RegWriteW_1),
                   .MemtoRegW_1      (MemtoRegW_1),
                   .ReadDataW_1      (ReadDataW_1),
                   .ComputeResultW_1 (ComputeResultW_1),
                   .rdW_1            (rdW_1),
                   .Funct3W_1        (Funct3W_1),
                   .RegWriteW_2      (RegWriteW_2),
                   .ComputeResultW_2 (ComputeResultW_2),
                   .rdW_2            (rdW_2)
               );

    LoadUnit LoadUnit (
                 .Funct3      (Funct3W_1),
                 .ByteOffset  (ComputeResultW_1[1:0]),
                 .ReadData_in (ReadDataW_1),
                 .ReadDataW   (ReadDataW_Aligned_1)
             );

    Hazard Hazard1 (
               .rs1D_1            (rs1D_1),
               .rs2D_1            (rs2D_1),
               .rs1D_2            (rs1D_2),
               .rs2D_2            (rs2D_2),
               .OpcodeD_1         (OpcodeD_1),
               .OpcodeD_2         (OpcodeD_2),
               .rs1E_1            (rs1E_1),
               .rs2E_1            (rs2E_1),
               .rdE_1             (rdE_1),
               .rs1E_2            (rs1E_2),
               .rs2E_2            (rs2E_2),
               .rdE_2             (rdE_2),
               .MemtoRegE_1       (MemtoRegE_1),
               .rs2M_1            (rs2M_1),
               .rs2M_2            (rs2M_2),
               .rdM_1             (rdM_1),
               .rdM_2             (rdM_2),
               .RegWriteM_1       (RegWriteM_1),
               .RegWriteM_2       (RegWriteM_2),
               .MemWriteM_1       (MemWriteM_1),
               .MemWriteM_2       (MemWriteM_2),
               .rdW_1             (rdW_1),
               .rdW_2             (rdW_2),
               .RegWriteW_1       (RegWriteW_1),
               .RegWriteW_2       (RegWriteW_2),
               .MemtoRegW_1       (MemtoRegW_1),
               .MemtoRegW_2       (1'b0),
               .Busy              (Busy),
               .BranchMispredictM (BranchMispredictM),
               .ForwardAE_1       (ForwardAE_1),
               .ForwardBE_1       (ForwardBE_1),
               .ForwardAE_2       (ForwardAE_2),
               .ForwardBE_2       (ForwardBE_2),
               .ForwardM_1_W1     (ForwardM_1_W1),
               .ForwardM_1_W2     (ForwardM_1_W2),
               .ForwardM_2_W1     (ForwardM_2_W1),
               .ForwardM_2_W2     (ForwardM_2_W2),
               .Forward1D_1       (Forward1D_1),
               .Forward2D_1       (Forward2D_1),
               .Forward1D_2       (Forward1D_2),
               .Forward2D_2       (Forward2D_2),
               .lwStall           (lwStall),
               .StallF            (StallF),
               .StallD            (StallD),
               .FlushE            (FlushE),
               .FlushD            (FlushD),
               .FlushM            (FlushM)
           );

    BranchHistoryTable #(
                           .ENTRIES(256)
                       ) BHT (
                           .CLK        (CLK),
                           .RESET      (RESET),
                           .PCF        (BPU_PC),
                           .PrPCSrcF   (PrPCSrcF),
                           .PCM        (PCM),
                           .WE_PrPCSrc (MispredPCSrcM),
                           .PCSrcM     (PCSrcM)
                       );

    BranchTargetBuffer #(
                           .ENTRIES(256),
                           .INDEX_BITS(8)
                       ) BTB (
                           .CLK      (CLK),
                           .RESET    (RESET),
                           .PCF      (BPU_PC),
                           .PrBTAF   (PrBTAF),
                           .PCM      (PCM),
                           .BTAM     (PC_ResolvedM),
                           .WE_PrBTA (MispredBTAM)
                       );

endmodule
