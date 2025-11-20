`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: RV
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: RISC-V Processor Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface SHOULD NOT be modified (except making output reg) unless you modify Wrapper.v/vhd too. 
                        The implementation can be modified.
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file as well as any files derived from this.
----------------------------------------------------------------------------------
*/

// Change wire to reg if assigned inside a procedural (always) block. However, where it is easy enough, use assign instead of always.
// A 2-1 multiplexing can be done easily using an assign with a ternary operator
// For multiplexing with number of inputs > 2, a case construct within an always block is a natural fit. DO NOT to use nested ternary assignment operator as it hampers the readability of your code.


module RV #(
    parameter PC_INIT = 32'h00400000
) (
    input CLK,
    input RESET,
    //input Interrupt,      // for optional future use.
    input [31:0] Instr,
    input [31:0] ReadData_in,  // Name mangled to support lb/lbu/lh/lhu
    output MemRead,
    output [3:0] MemWrite_out,		// Column-wise write enable to support sb/sw. Each column is a byte.
    output [31:0] PC,
    output wire [31:0] ComputeResultM,  // after ALU and Mcycle should be M version?
    output [31:0] WriteData_out  // Name mangled to support sb/sw
);
    // pipelining 
    /**
        IF/ID stage, Decode
    **/
    // into
    wire [31:0] PCF;     // current PC fetch
    wire [31:0] InstrF;  // fetched instr
    // out
    wire [31:0] PCD;     // PC from D to E
    wire [31:0] InstrD;  // instr out of D

    /** 
        ID/E stage, Execute
    **/
    // into
    // wire [1:0] PCSD ;
    // wire RegWriteD ;
    // wire MemWrite ;
    // wire MemtoRegD ;
    // wire [1:0] ALUSrcAD ;
    // wire [1:0] ALUSrcBD ;
    // wire [3:0] ALUControlD ;
    // wire [31:0] RD1D, RD2D, ExtimmD;
    // wire [4:0] rdD;
    // reg [31:0] PCD;
    // wire [31:0] ExtImmD
    
    // out
    // wire [31:0] WriteDataE   // declared in RV signals
    wire [1:0] PCSE;
    wire [31:0] RD1E, RD2E, ExtImmE; 
    wire RegWriteE, MemtoRegE, MemWriteE;
    wire [1:0] ALUSrcAE;
    wire [1:0] ALUSrcBE;
    wire [3:0] ALUControlE;
    wire [31:0] PCE;
    wire [2:0] Funct3E;

    /**
       E/M stage memory 
    **/
    // into
    // wire RegWriteE, MemtoRegE, MemWriteE;
    // wire [31:0] ComputeResultE; should be compute result after fixing mcycle
    // wire [31:0] WriteDataE;
    // wire [4:0] rdE;

    // out
    wire RegWriteM, MemtoRegM, MemWriteM;
    //wire [31:0] ComputeResultM; // declared as RV output
    wire [31:0] WriteDataM;
    wire [4:0] rdM;
    /**
       M/W stage writeback 
    **/
    // into
    // wire RegWriteM, MemtoRegM;
    wire [31:0] ReadDataM;
    // wire [31:0] ComputeResultM;
    // wire [4:0] rdM;

    // out
    wire RegWriteW;
    wire MemtoRegW;
    wire [31:0] ReadDataW;
    wire [2:0] Funct3M;
    wire [31:0] ComputeResultW;
    wire [4:0] rdW;

    //////////////////////////////
    // end of pipelining

    // Please read Lab 4 Enhancement: Implementing additional instructions on how to support lb/lbu/lh/lhu/sb/sh

    //RV Signals
    wire [2:0] SizeSel;     //to support lb/lbu/lh/lhu/sb/sh
    wire [31:0] ReadData;
    wire [31:0] WriteDataE;
    wire MemWriteD;
    wire [4:0] rdD;
    wire [4:0] rdE;
    //reg [4:0] rdM;
    //reg [4:0] rdW;

    // The signals that are commented out (except CLK) will need to be uncommented and attached a stage suffix for pipelining,
    //  except if the connection is within the same stage.

    // RegFile signals
    //wire CLK ;
    wire WE ;
    wire [4:0] rs1D ;
    wire [4:0] rs2D ;
    wire [4:0] rs1E;
    wire [4:0] rs2E;
    wire [4:0] rs2M;

    //wire [4:0] rdW ;
    wire [31:0] WD ;
    wire [31:0] R15 ;
    wire [31:0] RD1D ;
    wire [31:0] RD2D ;

    // Extend Module signals
    wire [2:0] ImmSrc ;
    wire [24:0] InstrImm ;
    wire [31:0] ExtImmD ;

    // Decoder signals
    wire [6:0] OpcodeD ;
    wire [2:0] Funct3D ;
    wire [6:0] Funct7D ;
    wire [1:0] PCSD ;
    wire RegWriteD ;
    //wire MemWrite ;
    wire MemtoRegD ;
    wire [1:0] ALUSrcAD ;
    wire [1:0] ALUSrcBD ;
    //wire [2:0] ImmSrc ;
    wire [3:0] ALUControlD ;
    wire MulDivD ;
    wire MCycleStartD;
    wire [1:0] MCycleOpD;

    // PC_Logic signals
    //wire [1:0] PCS
    //wire [2:0] Funct3;
    //wire [2:0] ALUFlags;
    wire [1:0] PCSrcE;

    // ALU signals
    wire [31:0] Src_A ;
    wire [31:0] Src_B ;
    reg [31:0] Src_A_mux ;
    reg [31:0] Src_B_mux ;
    //wire [3:0] ALUControl ;
    wire [31:0] ALUResultE;
    wire [2:0] ALUFlags ;

    // Hazard signals
    wire [1:0] ForwardAE; 
    wire [1:0] ForwardBE;
    wire ForwardM;
    wire lwStall;
    wire StallF;
    wire StallD;
    wire FlushD;
    wire FlushE;
    wire Forward1D;
    wire Forward2D;

    // W & D Forwarding Mux
    wire [31:0] RD1D_forward;
    wire [31:0] RD2D_forward;

    assign RD1D_forward = Forward1D ? WD : RD1D;
    assign RD2D_forward = Forward2D ? WD : RD2D;

    // MCycle signals
    wire [31:0] MCycleResult_1;
    wire [31:0] MCycleResult_2;
    wire [31:0] MCycleResult;
    wire Busy;
    wire [1:0] MCycleOpE;
    wire MCycleStartE;
    wire MulDivE;
    wire [31:0] ComputeResultE;

    // ProgramCounter signals
    //wire CLK ;
    //wire RESET ;
    wire WE_PC;
    wire [31:0] PC_IN;
    //wire [31:0] PC ; 

    // Other internal signals here
    wire [31:0] PC_Offset;
    wire [31:0] PC_Base;
    wire [31:0] PC_Sum;
    // wire [31:0] Result ;
    
    // lb/sb support
    wire [1:0] ByteOffset;  // Last 2 bits of address for byte/halfword access
    reg [31:0] ReadData_extracted;
    reg [31:0] WriteData_aligned;
    reg [3:0]  MemWrite_enable;
    // Byte offset from address
    assign ByteOffset = ComputeResultM[1:0];

    // LOAD DATA PATH
    // Extract and extend loaded data based on SizeSel and ByteOffset
    always @(*) begin
        case (Funct3M)
            3'b000: case (ByteOffset)   // lb
                2'b00: ReadData_extracted = {{24{ReadData_in[7]}},  ReadData_in[7:0]};
                2'b01: ReadData_extracted = {{24{ReadData_in[15]}}, ReadData_in[15:8]};
                2'b10: ReadData_extracted = {{24{ReadData_in[23]}}, ReadData_in[23:16]};
                2'b11: ReadData_extracted = {{24{ReadData_in[31]}}, ReadData_in[31:24]};
            endcase
            3'b001: case (ByteOffset[1])    // lh
                1'b0: ReadData_extracted = {{16{ReadData_in[15]}}, ReadData_in[15:0]};
                1'b1: ReadData_extracted = {{16{ReadData_in[31]}}, ReadData_in[31:16]};
            endcase
            3'b010: ReadData_extracted = ReadData_in;  // LW
            3'b100: case (ByteOffset)   //lbu
                2'b00: ReadData_extracted = {24'b0, ReadData_in[7:0]};
                2'b01: ReadData_extracted = {24'b0, ReadData_in[15:8]};
                2'b10: ReadData_extracted = {24'b0, ReadData_in[23:16]};
                2'b11: ReadData_extracted = {24'b0, ReadData_in[31:24]};
            endcase
            3'b101: case (ByteOffset[1])    //lhu
                1'b0: ReadData_extracted = {16'b0, ReadData_in[15:0]};
                1'b1: ReadData_extracted = {16'b0, ReadData_in[31:16]};
            endcase
            default: ReadData_extracted = ReadData_in;
        endcase
    end

    assign ReadDataM = ReadData_extracted;

    // STORE DATA PATH
    // Align store data and generate write enables based on SizeSel and ByteOffset
    always @(*) begin
        WriteData_aligned = 32'h0;
        MemWrite_enable   = 4'b0000;

        case (Funct3M)
            3'b000: begin  // SB
                case (ByteOffset)
                    2'b00: begin
                        WriteData_aligned = {24'b0, WriteDataM[7:0]};
                        MemWrite_enable   = 4'b0001;
                    end
                    2'b01: begin
                        WriteData_aligned = {16'b0, WriteDataM[7:0], 8'b0};
                        MemWrite_enable   = 4'b0010;
                    end
                    2'b10: begin
                        WriteData_aligned = {8'b0, WriteDataM[7:0], 16'b0};
                        MemWrite_enable   = 4'b0100;
                    end
                    2'b11: begin
                        WriteData_aligned = {WriteDataM[7:0], 24'b0};
                        MemWrite_enable   = 4'b1000;
                    end
                endcase
            end

            3'b001: begin  // SH
                case (ByteOffset[1])
                    1'b0: begin
                        WriteData_aligned = {16'b0, WriteDataM[15:0]};
                        MemWrite_enable   = 4'b0011;
                    end
                    1'b1: begin
                        WriteData_aligned = {WriteDataM[15:0], 16'b0};
                        MemWrite_enable   = 4'b1100;
                    end
                endcase
            end

            3'b010: begin  // SW
                WriteData_aligned = WriteDataM;
                MemWrite_enable   = 4'b1111;
            end

            default: begin
                WriteData_aligned = WriteDataM;
                MemWrite_enable   = 4'b1111;
            end
        endcase
    end

    // for D pipeline
    assign PC = PCF;        // from RV output
    assign InstrF = Instr;  // from RV input

    assign MemRead = MemtoRegM; // This is needed for the proper functionality of some devices such as UART CONSOLE
    assign WE_PC = ~Busy ;  // Will need to control it for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.

    //assign ReadDataM = ReadData_in;  // Change datapath as appropriate if supporting lb/lbu/lh/lhu
    
    // assign WriteData_out = WriteData_aligned;
    assign WriteData_out = ForwardM ? WD : WriteData_aligned;  // Change datapath as appropriate if supporting sb/sh

    // needs to change Memwrite to MemWrite_?
    assign MemWrite_out = (MemWriteM) ? MemWrite_enable : 4'b0000;
    //assign SizeSel = 3'b010;             // Change this to be generated by the Decoder (control) as appropriate if 
                                         // supporting lb/sb/lbu/lh/sh/lhu/lw/sw. Hint: funct3

    // Instruction Decoder
    assign OpcodeD  = InstrD[6:0];
    assign rdD      = InstrD[11:7];
    assign Funct3D   = InstrD[14:12];
    assign rs1D     = InstrD[19:15];
    assign rs2D     = InstrD[24:20];
    assign Funct7D   = InstrD[31:25];
    assign InstrImm = InstrD[31:7];
    
    // MUX for HazardUnit
    always @(*) begin
        case (ForwardAE)
            2'b00: Src_A_mux = RD1E; // No forwarding
            2'b01: Src_A_mux = WD; // Forward from Writeback stage
            2'b10: Src_A_mux = ComputeResultM; // Forward from Memory stage
            default: Src_A_mux = RD1E; // default safe
        endcase

        case (ForwardBE)
            2'b00: Src_B_mux = RD2E; // No forwarding
            2'b01: Src_B_mux = WD; // Forward from Writeback stage
            2'b10: Src_B_mux = ComputeResultM; // Forward from Memory stage
            default: Src_B_mux = RD2E; // default safe
        endcase 
    end

    // ALU inputs ** NEED TO CHANGE Src_A and logic
    assign Src_A = (ALUSrcAE == 2'b00) ? Src_A_mux :  // rs1
        (ALUSrcAE == 2'b01) ? 32'b0 :  // zero (lui)
        (ALUSrcAE == 2'b11) ? PCE :  // PC (auipc, jalr, jal)
        Src_A_mux;  // default safe
    assign Src_B = (ALUSrcBE == 2'b00) ? Src_B_mux :  // rs2
        (ALUSrcBE == 2'b01) ? 32'd4 :  // 4 (for jal and jalr to compute return address)
        (ALUSrcBE == 2'b11) ? ExtImmE:  // ExtImm (for DP Imm, load, store)
        Src_B_mux;  // default

    //needs to fix
    // compute result multiplexed by the MulDiv signal
    // MUL, DIV, DIVU instructions use Result1 (LSW / Quotient)
    // The rest use Result2
    assign MCycleResult = (Funct3E == 3'b000 || Funct3E == 3'b100 || Funct3E == 3'b101) ?  MCycleResult_1 : MCycleResult_2;  // LSW/Quotient or MSW/Remainder depending on instruction
    assign ComputeResultE = (MulDivE == 1) ? MCycleResult : ALUResultE;

    // Memory Interface
    assign WriteDataE = Src_B_mux; //change in W

    // Writeback mux
    assign WD = MemtoRegW ? ReadDataW : ComputeResultW;

    // 00: sequential use pcf
    // 01: branch or jal, extimm and PCE
    // 11: jalr, extimm and RD1E
    // PC Update
    assign PC_Base = (PCSrcE[1] == 1) ? Src_A_mux // JALR
        : (PCSrcE[0] == 1) ? PCE            // JAL/ branch
        : PCF;                              // sequential
    assign PC_Offset = (PCSrcE[0] == 1) ? ExtImmE : 32'd4;
    // RISC-V must set LSB of jalr address to 0?
    // assign PC_Sum = PC_Base + PC_Offset;
    // assign PC_IN = (PCSrc == 2'b11) ? {PC_Sum[31:1], 1'b0} : PC_Sum;  // Only clear for JALR
    assign PC_IN = PC_Base + PC_Offset;

    // Control Signals
    assign WE = RegWriteW;


    // pipeline register instantiate
    
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
        .RD1D(RD1D_forward),
        .RD2D(RD2D_forward),
        .ExtImmD(ExtImmD),
        .rs1D(rs1D),
        .rs2D(rs2D),
        .rdD(rdD),
        .PCD(PCD),
        .Funct3D(Funct3D),
        .MCycleOpD(MCycleOpD),
        .MCycleStartD(MCycleStartD),
        .MulDivD(MulDivD),
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
        .MulDivE(MulDivE)
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
        .RegWriteM(RegWriteM),
        .MemtoRegM(MemtoRegM),
        .MemWriteM(MemWriteM),
        .Funct3M(Funct3M),
        .ComputeResultM(ComputeResultM),
        .WriteDataM(WriteDataM),
        .rs2M(rs2M),
        .rdM(rdM)
    );
    
    pipeline_W pipelineW (
        .CLK(CLK),
        .RESET(RESET),
        .RegWriteM(RegWriteM),
        .MemtoRegM(MemtoRegM),
        .ReadDataM(ReadDataM),
        .ComputeResultM(ComputeResultM),
        .rdM(rdM),
        .RegWriteW(RegWriteW),
        .MemtoRegW(MemtoRegW),
        .ReadDataW(ReadDataW),
        .ComputeResultW(ComputeResultW),
        .rdW(rdW)
    );

    // Instantiate RegFile
    RegFile RegFile1 (
        .CLK    (CLK),
        .WE     (WE),
        .rs1    (rs1D),
        .rs2    (rs2D),
        .rd     (rdW),
        .WD     (WD),
        .RD1    (RD1D),
        .RD2    (RD2D)
    );

    // Instantiate Extend Module
    Extend Extend1 (
        .ImmSrc     (ImmSrc),
        .InstrImm   (InstrImm),
        .ExtImm     (ExtImmD)
    );

    // Instantiate Decoder
    Decoder Decoder1 (
        .Opcode     (OpcodeD),
        .Funct3     (Funct3D),
        .Funct7     (Funct7D),
        .PCS        (PCSD),
        .RegWrite   (RegWriteD),
        .MemWrite   (MemWriteD),
        .MemtoReg   (MemtoRegD),
        .ALUSrcA    (ALUSrcAD),
        .ALUSrcB    (ALUSrcBD),
        .ImmSrc     (ImmSrc),
        .ALUControl (ALUControlD),
        .MulDiv     (MulDivD),
        .MCycleStart(MCycleStartD),
        .MCycleOp   (MCycleOpD),
        .SizeSel    (SizeSel)
    );

    // Instantiate PC_Logic // * will probably have to change
    PC_Logic PC_Logic1 (
        .PCS        (PCSE),
        .Funct3     (Funct3E),
        .ALUFlags   (ALUFlags),
        .PCSrc      (PCSrcE)
    );

    // Instantiate ALU        
    ALU ALU1 (
        .Src_A      (Src_A),
        .Src_B      (Src_B),
        .ALUControl (ALUControlE),
        .ALUResult  (ALUResultE),
        .ALUFlags   (ALUFlags)
    );

    Hazard Hazard1 (
        .rs1D       (rs1D),
        .rs2D       (rs2D),
        .rs1E       (rs1E),
        .rs2E       (rs2E),
        .rs2M       (rs2M),
        .rdE        (rdE),
        .rdM        (rdM),
        .rdW        (rdW),
        .RegWriteM  (RegWriteM),
        .RegWriteW  (RegWriteW),
        .MemWriteM  (MemWriteM),
        .MemtoRegW  (MemtoRegW),
        .MemtoRegE  (MemtoRegE),
        .Busy       (Busy),
        .PCSrcE     (PCSrcE),
        .ForwardAE  (ForwardAE),
        .ForwardBE  (ForwardBE),
        .ForwardM   (ForwardM),
        .lwStall    (lwStall),
        .StallF     (StallF),
        .StallD     (StallD),
        .FlushE     (FlushE),
        .FlushD     (FlushD),
        .Forward1D   (Forward1D),
        .Forward2D   (Forward2D)
    );

    // Instantiate MCycle Unit  // not adapted for pipeline yet
    MCycle #(
        .width(32)
    ) MCycle1 (
        .CLK     (CLK),
        .RESET   (RESET),
        .Start   (MCycleStartE),   // from Decoder
        .MCycleOp(MCycleOpE),      // from Decoder
        .Operand1(Src_A_mux),           // rs1 value
        .Operand2(Src_B_mux),           // rs2 value
        .Result1 (MCycleResult_1),  // LSW of mul or quotient
        .Result2 (MCycleResult_2),  // MSW of mul or remainder
        .Busy    (Busy)           // signal to stall PC while busy
    );

    // Instantiate ProgramCounter    
    ProgramCounter #(
        .PC_INIT(PC_INIT)
    ) ProgramCounter1 (
        .CLK    (CLK),
        .RESET  (RESET),
        .StallF (StallF),
        .PC_IN  (PC_IN),
        .PC     (PCF)
    );

endmodule
