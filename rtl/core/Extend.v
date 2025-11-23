`timescale 1ns / 1ps

module Extend (
    input [2:0] ImmSrc,
    input [31:7] InstrImm,  //maintaining the numbering in the instruction for comprehensibility
    output reg [31:0] ExtImm
);

  // ImmSrc pattern chosen (not optimally) such that single bit changes for more similar immediates, which can simplify the logic.
  // For example, SB and S are very similar, so they are assigned 110 and 111 respectively.

  always @(ImmSrc, InstrImm)
    case (ImmSrc)
      3'b000: ExtImm = {InstrImm[31:12], 12'h000};  // U type
      3'b010:
      ExtImm = {{12{InstrImm[31]}}, InstrImm[19:12], InstrImm[20], InstrImm[30:21], 1'b0};  // UJ   
      3'b011: ExtImm = {{20{InstrImm[31]}}, InstrImm[31:20]};  // I    
      3'b110: ExtImm = {{20{InstrImm[31]}}, InstrImm[31:25], InstrImm[11:7]};  // S    
      3'b111:
      ExtImm = {{20{InstrImm[31]}}, InstrImm[7], InstrImm[30:25], InstrImm[11:8], 1'b0};  // SB    
      default: ExtImm = 32'bx;  // undefined     
    endcase

endmodule
