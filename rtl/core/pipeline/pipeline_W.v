`timescale 1ns / 1ps

module pipeline_W (
    input             CLK,
    input             RESET,
    input             RegWriteM,
    input             MemtoRegM,
    input      [31:0] ReadDataM,
    input      [31:0] ComputeResultM,
    input      [ 4:0] rdM,
    output reg        RegWriteW,
    output reg        MemtoRegW,
    output reg [31:0] ReadDataW,
    output reg [31:0] ComputeResultW,
    output reg [ 4:0] rdW
);

    always @(posedge CLK)
        if (RESET) begin
            RegWriteW <= 1'b0;
            MemtoRegW <= 1'b0;
            ReadDataW <= 32'b0;
            ComputeResultW <= 32'b0;
            rdW <= 5'b0;
        end else begin  // do not stall M/W stage for MCycle
            RegWriteW <= RegWriteM;
            MemtoRegW <= MemtoRegM;
            ReadDataW <= ReadDataM;
            ComputeResultW <= ComputeResultM;
            rdW <= rdM;
        end

endmodule
