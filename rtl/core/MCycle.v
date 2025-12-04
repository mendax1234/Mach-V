`timescale 1ns / 1ps

module Multiplier32x8 (
    input  wire [31:0] A,       // The 32-bit full operand
    input  wire [ 7:0] B,       // The 8-bit slice
    output wire [39:0] Product  // Result (32 + 8 = 40 bits max)
);

    // -------------------------------------------------------------------------
    // Partial Product Generation
    // -------------------------------------------------------------------------
    // If B[i] is 1, take (A << i). If 0, take 0.
    wire [39:0] pp0 = B[0] ? {8'b0, A} : 40'b0;
    wire [39:0] pp1 = B[1] ? {7'b0, A, 1'b0} : 40'b0;
    wire [39:0] pp2 = B[2] ? {6'b0, A, 2'b0} : 40'b0;
    wire [39:0] pp3 = B[3] ? {5'b0, A, 3'b0} : 40'b0;
    wire [39:0] pp4 = B[4] ? {4'b0, A, 4'b0} : 40'b0;
    wire [39:0] pp5 = B[5] ? {3'b0, A, 5'b0} : 40'b0;
    wire [39:0] pp6 = B[6] ? {2'b0, A, 6'b0} : 40'b0;
    wire [39:0] pp7 = B[7] ? {1'b0, A, 7'b0} : 40'b0;

    // -------------------------------------------------------------------------
    // Summation
    // -------------------------------------------------------------------------
    assign Product = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;

endmodule

module DivSlice8 #(
    parameter width = 32
) (
    input  wire [2*width-1:0] rem_in,   // Current Remainder
    input  wire [2*width-1:0] div_in,   // Current Divisor
    input  wire [  width-1:0] quot_in,  // Current Quotient (LSW of buffer)
    output reg  [2*width-1:0] rem_out,  // Next Remainder
    output reg  [2*width-1:0] div_out,  // Next Divisor
    output reg  [  width-1:0] quot_out  // Next Quotient
);

    integer             i;
    reg     [2*width:0] diff_ext;  // Extended difference for carry check

    always @(*) begin
        // Initialize temporary variables with inputs
        rem_out = rem_in;
        div_out = div_in;
        quot_out = quot_in;

        // Perform 8 iterations of division logic (Combinational Loop)
        for (i = 0; i < 8; i = i + 1) begin
            // Subtract: Remainder - Divisor
            // Note: {1'b0, ~div_out} + 1'b1 is equivalent to -div_out (2's complement)
            diff_ext = {1'b0, rem_out} + {1'b0, ~div_out} + 1'b1;

            // Check Sign
            if (diff_ext[2*width] == 1'b1) begin
                // Result Positive: Update Remainder, Shift 1 into Quotient
                rem_out = diff_ext[2*width-1:0];
                quot_out = {quot_out[width-2:0], 1'b1};
            end else begin
                // Result Negative: Keep Remainder, Shift 0 into Quotient
                quot_out = {quot_out[width-2:0], 1'b0};
            end

            // Shift Divisor Right for the next step
            div_out = {1'b0, div_out[2*width-1:1]};
        end
    end

endmodule

module MCycle #(
    parameter width = 32
) (
    input  wire             CLK,
    input  wire             RESET,
    input  wire             Start,     // Trigger
    input  wire [      1:0] MCycleOp,  // 00: Mul(s), 01: Mul(u), 10: Div(s), 11: Div(u)
    input  wire [width-1:0] Operand1,  // Dividend / Multiplicand
    input  wire [width-1:0] Operand2,  // Divisor / Multiplier
    output reg  [width-1:0] Result1,   // LSW / Quotient
    output reg  [width-1:0] Result2,   // MSW / Remainder
    output reg              Busy       // Stall Signal
);

    // ========================================================================
    // Parameters & Internal Signals
    // ========================================================================
    localparam IDLE = 1'b0;
    localparam COMPUTING = 1'b1;

    reg state, n_state;
    reg                done;
    reg  [        7:0] count;

    // Arithmetic Registers
    reg  [2*width-1:0] div_result_buf;  // Buffer for [Remainder | Quotient]
    reg  [2*width-1:0] rem;  // Current Remainder
    reg  [2*width-1:0] div;  // Current Divisor
    reg  [  width-1:0] abs_op1;  // Abs value of Operand1
    reg  [  width-1:0] abs_op2;  // Abs value of Operand2

    // Multiplication Accumulators
    reg  [2*width-1:0] mult_acc;
    reg  [2*width-1:0] final_product;

    // Sub-module Interconnects
    reg  [        7:0] current_byte_op2;
    wire [       39:0] partial_product_out;
    wire [2*width-1:0] next_rem;
    wire [2*width-1:0] next_div;
    wire [  width-1:0] next_quot;

    // ========================================================================
    // Sub-Module Instantiations
    // ========================================================================

    // Multiplier Unit
    Multiplier32x8 mul_unit (
        .A      (abs_op1),
        .B      (current_byte_op2),
        .Product(partial_product_out)
    );

    // Division Unit
    DivSlice8 #(
        .width(width)
    ) div_unit (
        .rem_in  (rem),
        .div_in  (div),
        .quot_in (div_result_buf[width-1:0]),
        .rem_out (next_rem),
        .div_out (next_div),
        .quot_out(next_quot)
    );

    // ========================================================================
    // Combinational Logic
    // ========================================================================

    // FSM Next State Logic
    always @(*) begin
        n_state = IDLE;
        Busy = 1'b0;

        case (state)
            IDLE: begin
                if (Start) begin
                    n_state = COMPUTING;
                    Busy = 1'b1;
                end
            end
            COMPUTING: begin
                if (~done) begin
                    n_state = COMPUTING;
                    Busy = 1'b1;
                end
            end
        endcase
    end

    // Input Selector for Multiplier (Combinational)
    always @(*) begin
        case (count[1:0])
            2'b00: current_byte_op2 = abs_op2[7:0];
            2'b01: current_byte_op2 = abs_op2[15:8];
            2'b10: current_byte_op2 = abs_op2[23:16];
            2'b11: current_byte_op2 = abs_op2[31:24];
            default: current_byte_op2 = 8'b0;
        endcase
    end

    // ========================================================================
    // Sequential Logic (State Updates & Arithmetic)
    // ========================================================================

    // State Register
    always @(posedge CLK) begin
        if (RESET) state <= IDLE;
        else state <= n_state;
    end

    // Arithmetic Datapath
    // Note: Using blocking assignments (=) here to maintain the logic flow 
    // defined in the original design (software-like execution sequence).
    always @(posedge CLK) begin
        if (RESET | (n_state == COMPUTING && state == IDLE)) begin
            // --- Initialization Phase (Cycle 0) ---
            count = 0;
            div_result_buf = 0;
            mult_acc = 0;
            done <= 1'b0;

            // Handle Signed/Unsigned Inputs
            // If Signed Op (MCycleOp[0]==0) and Operand is negative, take 2's comp
            abs_op1 = (~MCycleOp[0] && Operand1[width-1]) ? (~Operand1 + 1) : Operand1;
            abs_op2 = (~MCycleOp[0] && Operand2[width-1]) ? (~Operand2 + 1) : Operand2;

            // Align Divisor and Remainder for Division
            div = {abs_op2, {width{1'b0}}};
            rem = {{width{1'b0}}, abs_op1};
        end else if (state == COMPUTING) begin

            // --- Multiply Logic ---
            if (~MCycleOp[1]) begin
                if (count > 0) begin
                    // Shift and Accumulate Partial Products
                    case (count)
                        1: mult_acc = mult_acc + partial_product_out;
                        2: mult_acc = mult_acc + (partial_product_out << 8);
                        3: mult_acc = mult_acc + (partial_product_out << 16);
                        4: mult_acc = mult_acc + (partial_product_out << 24);
                    endcase
                end

                if (count == 4) begin
                    done <= 1'b1;
                    // Sign Correction for Result
                    if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1])) begin
                        final_product = ~mult_acc + 1;
                    end else begin
                        final_product = mult_acc;
                    end

                    // Output Assignment
                    Result1 <= final_product[width-1:0];
                    Result2 <= final_product[2*width-1:width];
                end
            end else begin
                // Division Logic
                if (count > 0) begin
                    rem = next_rem;
                    div = next_div;
                    div_result_buf[width-1:0] = next_quot;
                    div_result_buf[2*width-1:width] = rem[width-1:0];
                end

                if (count == 4) begin
                    done <= 1'b1;
                    // Sign Correction for Quotient
                    if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1]))
                        div_result_buf[width-1:0] = ~div_result_buf[width-1:0] + 1;

                    // Sign Correction for Remainder (Matches Dividend Sign)
                    if (~MCycleOp[0] && (Operand1[width-1]))
                        div_result_buf[2*width-1:width] = ~div_result_buf[2*width-1:width] + 1;

                    // Output Assignment
                    Result1 <= div_result_buf[width-1:0];  // Quotient
                    Result2 <= div_result_buf[2*width-1:width];  // Remainder
                end
            end

            // Increment Cycle Count
            count = count + 1;
        end
    end

endmodule
