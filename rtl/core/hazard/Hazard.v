module Hazard (
    input [4:0] rs1D,
    input [4:0] rs2D,
    input [4:0] rs1E,
    input [4:0] rs2E,
    input [4:0] rs2M,
    input [4:0] rdE,
    input [4:0] rdM,
    input [4:0] rdW,
    input RegWriteM,
    input RegWriteW,
    input MemWriteM,
    input MemtoRegW,
    input MemtoRegE,
    input Busy,
    input [1:0] PCSrcE,
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output ForwardM,
    output lwStall,
    output StallF,
    output StallD,
    output FlushE,
    output FlushD,
    output Forward1D,
    output Forward2D
);
  // forward AE
  always @(*) begin
    if ((rs1E == rdM) && RegWriteM && (rdM != 0)) begin
      ForwardAE = 2'b10;  // Forward from Memory stage
    end else if ((rs1E == rdW) && RegWriteW && (rdW != 0)) begin
      ForwardAE = 2'b01;  // Forward from Writeback stage
    end else begin
      ForwardAE = 2'b00;  // No forwarding
    end
  end

  // forward BE
  always @(*) begin
    if ((rs2E == rdM) && RegWriteM && (rdM != 0)) begin
      ForwardBE = 2'b10;  // Forward from Memory stage
    end else if ((rs2E == rdW) && RegWriteW && (rdW != 0)) begin
      ForwardBE = 2'b01;  // Forward from Writeback stage
    end else begin
      ForwardBE = 2'b00;  // No forwarding
    end
  end

  //forwardM for mem-mem copy hazard
  assign ForwardM = (rs2M == rdW) && MemWriteM && MemtoRegW && (rdW != 0);

  //lwstall load and use hazard 
  assign lwStall = ((rs1D == rdE) | (rs2D == rdE)) & MemtoRegE;
  assign StallF = lwStall | Busy;
  assign StallD = lwStall | Busy;

  // flushE and flushD for branch hazard
  assign FlushE = lwStall | PCSrcE[0];
  assign FlushD = PCSrcE[0];

  // W&D Forwarding
  assign Forward1D = (rs1D == rdW) & RegWriteW & (rdW != 0);
  assign Forward2D = (rs2D == rdW) & RegWriteW & (rdW != 0);

endmodule
