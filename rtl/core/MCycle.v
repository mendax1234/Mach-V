`timescale 1ns / 1ps

module Multiplier32x16 (
    input      [31:0] A,       // The 32-bit full operand
    input      [15:0] B,       // The 16-bit slice
    output reg [47:0] Product  // Result (32 + 16 = 48 bits max)
);

    integer i;

    always @(*) begin
        Product = 48'b0;

        for (i = 0; i < 16; i = i + 1) begin
            if (B[i]) begin
                // Shift A by 'i' and add to Product.
                Product = Product + ({16'b0, A} << i);
            end
        end
    end

endmodule

module DivSlice8 #(
    parameter width = 32
) (
    input      [2*width-1:0] rem_in,   // Current Remainder
    input      [2*width-1:0] div_in,   // Current Divisor
    input      [  width-1:0] quot_in,  // Current Quotient (LSW of buffer)
    output reg [2*width-1:0] rem_out,  // Next Remainder
    output reg [2*width-1:0] div_out,  // Next Divisor
    output reg [  width-1:0] quot_out  // Next Quotient
);

    // Temporary variable for subtraction
    integer             i;
    reg     [2*width:0] diff_ext;

    always @(*) begin
        // Initialize temporary variables with inputs
        rem_out = rem_in;
        div_out = div_in;
        quot_out = quot_in;

        // Perform 8 iterations of division logic (Combinational Loop)
        for (i = 0; i < 8; i = i + 1) begin
            // 1. Subtract: Remainder - Divisor
            diff_ext = {1'b0, rem_out} + {1'b0, ~div_out} + 1'b1;

            // 2. Check Sign
            if (diff_ext[2*width] == 1'b1) begin
                // Result Positive: Update Remainder, Shift 1 into Quotient
                rem_out = diff_ext[2*width-1:0];
                quot_out = {quot_out[width-2:0], 1'b1};
            end else begin
                // Result Negative: Keep Remainder, Shift 0 into Quotient
                quot_out = {quot_out[width-2:0], 1'b0};
            end

            // 3. Shift Divisor Right for the next step
            div_out = {1'b0, div_out[2*width-1:1]};
        end
    end
endmodule

module MCycle #(
    parameter width = 32
) (
    input                  CLK,
    input                  RESET,
    input                  Start,     // Trigger
    input      [      1:0] MCycleOp,  // 00: Mul(s), 01: Mul(u), 10: Div(s), 11: Div(u)
    input      [width-1:0] Operand1,
    input      [width-1:0] Operand2,
    output reg [width-1:0] Result1,   // LSW / Quotient
    output reg [width-1:0] Result2,   // MSW / Remainder
    output reg             Busy       // Stall Signal
);

    // ========================================================================
    // Internal Signals & Constants
    // ========================================================================

    localparam IDLE = 1'b0;
    localparam COMPUTING = 1'b1;

    reg                state = IDLE;
    reg                n_state = IDLE;
    reg                done;
    reg  [        7:0] count = 0;

    // --- Division Variables ---
    reg  [2*width-1:0] div_result_buf = 0;  // Buffer for [Remainder (MSW) | Quotient (LSW)]
    reg  [2*width-1:0] rem = 0;  // Current Remainder (Initialized with Dividend)
    reg  [2*width-1:0] div = 0;  // Current Divisor (Shifted right every cycle)
    reg  [  width-1:0] abs_op1 = 0;  // Absolute value of Dividend (Operand1)
    reg  [  width-1:0] abs_op2 = 0;  // Absolute value of Divisor (Operand2)

    // --- Multiplication Variables ---
    reg  [2*width-1:0] mult_acc;  // 64-bit Accumulator
    reg  [2*width-1:0] final_product;
    reg  [        15:0] current_half_word_op2;

    // --- Sub-Module Connections ---
    wire [2*width-1:0] next_rem;
    wire [2*width-1:0] next_div;
    wire [  width-1:0] next_quot;
    wire [       47:0] partial_product_out;

    // ========================================================================
    // Sub-Module Instantiation
    // ========================================================================

    DivSlice8 div_unit (
        .rem_in  (rem),
        .div_in  (div),
        .quot_in (div_result_buf[width-1:0]),
        .rem_out (next_rem),
        .div_out (next_div),
        .quot_out(next_quot)
    );

    Multiplier32x16 mul_unit (
        .A      (abs_op1),
        .B      (current_half_word_op2),
        .Product(partial_product_out)
    );

    // ========================================================================
    // FSM: State Transition (Combinational)
    // ========================================================================

    always @(state, done, Start, RESET) begin : IDLE_PROCESS
        // Default values
        Busy <= 1'b0;
        n_state <= IDLE;

        if (~RESET) begin
            case (state)
                IDLE: begin
                    if (Start) begin
                        n_state <= COMPUTING;
                        Busy <= 1'b1;
                    end
                end
                COMPUTING: begin
                    if (~done) begin
                        n_state <= COMPUTING;
                        Busy <= 1'b1;
                    end
                end
            endcase
        end
    end

    always @(posedge CLK) begin : STATE_UPDATE_PROCESS
        state <= n_state;
    end

    // ========================================================================
    // Datapath: Computation Logic
    // ========================================================================
    // NOTE: This block uses Blocking Assignments (=) intentionally.
    // The logic depends on variables being updated immediately within the cycle.

    always @(posedge CLK) begin : COMPUTING_PROCESS

        // ----------------------------------------
        // Initialization Phase
        // ----------------------------------------
        // This runs at the transition from IDLE to COMPUTING (Cycle 0)
        // It initializes variables, and execution FALLS THROUGH to step 2 immediately.
        if (RESET | (n_state == COMPUTING & state == IDLE)) begin
            count = 0;
            div_result_buf = 0;
            mult_acc = 0;

            // Handle Signs for Division
            abs_op1 = (~MCycleOp[0] && Operand1[width-1]) ? ~Operand1 + 1 : Operand1;
            abs_op2 = (~MCycleOp[0] && Operand2[width-1]) ? ~Operand2 + 1 : Operand2;

            // Align Divisor and Remainder
            div = {1'b0, abs_op2, {(width - 1) {1'b0}}};
            rem = {{width{1'b0}}, abs_op1};
        end

        // --- Logic Selection ---
        // Prepare input for Multiplier Module (Select Byte based on Count)
        case (count[0])
            1'b0: current_half_word_op2 = abs_op2[15:0];
            1'b1: current_half_word_op2 = abs_op2[31:16];
        endcase

        // Reset done flag every cycle (will be set to 1 if finished)
        done <= 1'b0;

        // ----------------------------------------
        // Arithmetic Phase
        // ----------------------------------------

        // --- Multiply ---
        if (~MCycleOp[1]) begin
            // Add the result of the combinational multiplier to the accumulator.
            if (count > 0) begin
                // Start accumulating from Cycle 1 as abs_op1 and abs_op2
                // are available from Cycle 1, so Cycle 0 does nothing
                case (count)
                    1: mult_acc = mult_acc + partial_product_out;
                    2: mult_acc = mult_acc + (partial_product_out << 16);
                endcase
            end

            if (count == 2) begin
                done <= 1'b1;
                // Sign Correction
                if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1])) final_product = ~mult_acc + 1;
                else final_product = mult_acc;
            end
            count = count + 1;
        end  // --- Divide (Shift & Subtract) ---
        else begin
            if (count > 0) begin
                rem = next_rem;
                div = next_div;
                div_result_buf[width-1:0] = next_quot;
                div_result_buf[2*width-1:width] = rem[width-1:0];
            end

            if (count == 4) begin
                done <= 1'b1;
                // Sign Correction
                if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1]))
                    div_result_buf[width-1:0] = ~div_result_buf[width-1:0] + 1;
                if (~MCycleOp[0] && (Operand1[width-1]))
                    div_result_buf[2*width-1:width] = ~div_result_buf[2*width-1:width] + 1;
            end

            count = count + 1;
        end

        // ----------------------------------------
        // Output Phase
        // ----------------------------------------
        if (~MCycleOp[1]) begin  // Multiply Output
            Result1 <= final_product[width-1:0];
            Result2 <= final_product[2*width-1:width];
        end else begin  // Divide Output
            Result1 <= div_result_buf[width-1:0];  // Quotient
            Result2 <= div_result_buf[2*width-1:width];  // Remainder
        end
    end

endmodule
