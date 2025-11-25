`timescale 1ns / 1ps

module ProgramCounter #(
    parameter PC_INIT = 32'h00400000
) (
    input             CLK,
    input             RESET,
    input             StallF,  // stall signal for fetch stage
    input      [31:0] PC_IN,
    output reg [31:0] PC
);

    initial begin
        PC <= PC_INIT;
    end

    always @(posedge CLK) begin
        if (RESET) PC <= PC_INIT;
        else if (~StallF) PC <= PC_IN;
    end

endmodule
