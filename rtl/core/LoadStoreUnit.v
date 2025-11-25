`timescale 1ns / 1ps

module LoadStoreUnit (
    input  [ 2:0] Funct3,
    input         MemWriteM,
    input  [31:0] WriteDataM,
    input  [31:0] ReadData_in,    // Raw data from memory
    input  [ 1:0] ByteOffset,     // Address[1:0]
    output [ 3:0] MemWrite_out,   // The mask sent to memory
    output [31:0] WriteData_out,  // The aligned data sent to memory
    output [31:0] ReadDataM       // The processed data sent to Writeback
);

    // --- STORE PATH (Alignment & Masking) ---
    wire [4:0] shamt = {ByteOffset, 3'b000};  // Offset * 8

    // Align Data
    assign WriteData_out = WriteDataM << shamt;

    // Generate Mask
    reg [3:0] BaseMask;
    always @(*) begin
        case (Funct3)
            3'b000: BaseMask = 4'b0001;  // SB
            3'b001: BaseMask = 4'b0011;  // SH
            default: BaseMask = 4'b1111;  // SW
        endcase
    end

    // Shift Mask
    assign MemWrite_out = (MemWriteM) ? (BaseMask << ByteOffset) : 4'b0000;

    // --- LOAD PATH (Shifting & Extension) ---
    wire [31:0] data_shifted = ReadData_in >> shamt;
    reg  [31:0] loaded_val;

    always @(*) begin
        case (Funct3)
            3'b000: loaded_val = {{24{data_shifted[7]}}, data_shifted[7:0]};  // LB
            3'b001: loaded_val = {{16{data_shifted[15]}}, data_shifted[15:0]};  // LH
            3'b100: loaded_val = {24'b0, data_shifted[7:0]};  // LBU
            3'b101: loaded_val = {16'b0, data_shifted[15:0]};  // LHU
            default: loaded_val = data_shifted;  // LW
        endcase
    end

    assign ReadDataM = loaded_val;

endmodule
