`timescale 1ns / 1ps

module pipeline_D (
    input             CLK,
    input             RESET,
    input             StallD,
    input             FlushD,
    input      [31:0] InstrF,
    input      [31:0] PCF,
    output reg [31:0] InstrD
    output reg [31:0] PCD
);

    always @(posedge CLK) begin
        if (RESET || FlushD) begin
            InstrD <= 32'b0;
            PCD <= 32'b0;
        end else if (~StallD) begin
            InstrD <= InstrF;
            PCD <= PCF;
        end
    end

endmodule


