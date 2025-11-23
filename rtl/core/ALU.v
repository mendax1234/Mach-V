`timescale 1ns / 1ps

module ALU (
    input [31:0] Src_A,
    input [31:0] Src_B,
    input [3:0] ALUControl,  // 0000:add, 0001:sub, 1110:and, 1100:or, 0010:sll, 1010:srl, 1011:sra
    output reg [31:0] ALUResult,
    output reg [2:0] ALUFlags  // {eq, lt, ltu}
);

  // ========================================================================
  //                          INTERNAL SIGNALS
  // ========================================================================
  // Shifter Signals
  reg  [ 1:0] Sh;  // Shifter Control: 00:sll, 10:srl, 11:sra
  wire [31:0] ShOut;  // Output from Shifter Module
  wire [ 4:0] Shamt5;  // Shift Amount

  // Arithmetic Signals
  reg  [32:0] S_wider;  // 33-bit Sum for Carry calculation
  reg  [32:0] Src_A_comp;
  reg  [32:0] Src_B_comp;
  reg  [32:0] C_0;  // Carry In

  // Flags
  reg N, Z, C, V;  // Negative, Zero, Carry, Overflow

  // ========================================================================
  //                          SHIFTER CONTROL
  // ========================================================================
  // Decodes ALUControl to generate Shifter signals
  assign Shamt5 = Src_B[4:0];

  always @(*) begin
    case (ALUControl)
      4'b0010: Sh = 2'b00;  // SLL
      4'b1010: Sh = 2'b10;  // SRL
      4'b1011: Sh = 2'b11;  // SRA
      default: Sh = 2'b00;  // Default
    endcase
  end

  Shifter Shifter1 (
      .Sh(Sh),
      .Shamt5(Shamt5),
      .ShIn(Src_A),
      .ShOut(ShOut)
  );

  // ========================================================================
  //                          ALU MAIN LOGIC
  // ========================================================================
  always @(*) begin
    // --- Operand Preparation (Adder Inputs) ---
    // Default: Positive operands, Carry-in 0
    Src_A_comp = {1'b0, Src_A};
    Src_B_comp = {1'b0, Src_B};
    C_0        = 33'd0;

    // If we are subtracting, we need to add the 2's complement: (~B + 1)
    if (ALUControl == 4'b0001 || ALUControl == 4'b0100 || ALUControl == 4'b0110) begin
      Src_B_comp = {1'b0, ~Src_B};  // Invert bits
      C_0[0]     = 1'b1;  // Add 1 (Carry In)
    end

    // --- Execute Addition/Subtraction ---
    S_wider = Src_A_comp + Src_B_comp + C_0;

    // --- Intermediate Flag Calculation ---
    // Determine C and V based on the Adder result
    // Note: These flags are only valid for arithmetic ops, masked later if needed
    C = S_wider[32];  // Carry Out
    V = (Src_A[31] ^ S_wider[31]) & ~(Src_A[31] ^ Src_B[31] ^ (ALUControl == 4'b0000));

    // Overflow = (Src_A and ~Src_B have same sign) AND (Result sign differs)
    if (ALUControl == 4'b0001 || ALUControl == 4'b0100 || ALUControl == 4'b0110) begin
      V = (Src_A[31] != Src_B[31]) && (S_wider[31] != Src_A[31]);
    end else begin
      // For Addition
      V = (Src_A[31] == Src_B[31]) && (S_wider[31] != Src_A[31]);
    end

    // --- Result Multiplexer ---
    case (ALUControl)
      // Arithmetic
      4'b0000: ALUResult = S_wider[31:0];  // ADD
      4'b0001: ALUResult = S_wider[31:0];  // SUB

      // Logic
      4'b1110: ALUResult = Src_A & Src_B;  // AND
      4'b1100: ALUResult = Src_A | Src_B;  // OR
      4'b1000: ALUResult = Src_A ^ Src_B;  // XOR

      // Comparisons
      4'b0100: ALUResult = {31'b0, (S_wider[31] ^ V)};  // SLT (Signed: N ^ V)
      4'b0110: ALUResult = {31'b0, ~C};  // SLTU (Unsigned: ~Carry)

      // Shifts (Pass through Shifter output)
      4'b0010,  // SLL
      4'b1010,  // SRL
      4'b1011:  // SRA
      ALUResult = ShOut;

      default: ALUResult = 32'b0;
    endcase

    // --- Final Flag Generation ---
    Z = (ALUResult == 32'b0);
    N = ALUResult[31];

    // Note: C and V calculated above are raw adder flags. 
    // We strictly only need them for the Branch checks, but we output them generally here.
    ALUFlags = {Z, (S_wider[31] ^ V), ~C};
  end

endmodule
