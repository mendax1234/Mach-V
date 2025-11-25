`timescale 1ns / 1ps

module PC_Logic (  // This is a combinational module, unlike ARM. See the note below.
    input      [1:0] PCS,       // 00 for non-control, 01 for conditional branch, 10 for jal, 11 for jalr
    input      [2:0] Funct3,    // condition specified in the instruction (eq / ne / lt / ge / ltu / geu)
    input      [2:0] ALUFlags,  // {eq, lt, ltu}
    output reg [1:0] PCSrc      // will need to be expanded to 2 bits to support jalr
);

    /* 
    Important Note : ALUFlags are not *stored* in flag registers in RISC-V, unlike ARM and most other processors.
    In RISC-V, the flags are produced and consumed in the same branch instruction. 
    The effect of CMP R1, R2 and BEQ LABEL in ARM is beq x1, x2, LABEL in RISC-V.
  */

    // Conditional logic goes here
    always @(*) begin
        case (PCS)
            2'b00: PCSrc = 2'b00;  // Non-control -> don't branch
            2'b01: begin  // Conditional branch
                case (Funct3)
                    3'b000: PCSrc = {1'b0, ALUFlags[2]};  // beq
                    3'b001: PCSrc = {1'b0, ~ALUFlags[2]};  // bne
                    3'b100: PCSrc = {1'b0, ALUFlags[1]};  // blt
                    3'b101: PCSrc = {1'b0, ~ALUFlags[1]};  // bge
                    3'b110: PCSrc = {1'b0, ALUFlags[0]};  // bltu
                    3'b111: PCSrc = {1'b0, ~ALUFlags[0]};  // bgeu
                    default: PCSrc = 2'b00;
                endcase
            end
            2'b10: PCSrc = 2'b01;  // jal
            2'b11: PCSrc = 2'b11;  // jalr
            default: PCSrc = 2'b00;
        endcase
    end

endmodule
