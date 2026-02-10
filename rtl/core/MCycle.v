/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   MCycle (Non-IP Version)
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Multi-Cycle Unit implementing multiplication and division 
--                using iterative add-shift and subtract-shift logic (no IP cores).
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module Multiplier32x8 (
        input  [31:0] A,       // The 32-bit full operand
        input  [ 7:0] B,       // The 8-bit slice
        output [39:0] Product  // Result (32 + 8 = 40 bits max)
    );

    // // Generate Partial Products (Shift A based on bit position of B)
    wire [39:0] pp0 = B[0] ? {8'b0, A} : 40'b0;
    wire [39:0] pp1 = B[1] ? {7'b0, A, 1'b0} : 40'b0;
    wire [39:0] pp2 = B[2] ? {6'b0, A, 2'b0} : 40'b0;
    wire [39:0] pp3 = B[3] ? {5'b0, A, 3'b0} : 40'b0;
    wire [39:0] pp4 = B[4] ? {4'b0, A, 4'b0} : 40'b0;
    wire [39:0] pp5 = B[5] ? {3'b0, A, 5'b0} : 40'b0;
    wire [39:0] pp6 = B[6] ? {2'b0, A, 6'b0} : 40'b0;
    wire [39:0] pp7 = B[7] ? {1'b0, A, 7'b0} : 40'b0;

    // Sum them up (Tree adder is faster, but this simple chain works also)
    assign Product = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;

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
            end
            else begin
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
    reg  [        7:0] current_byte_op2;

    // --- Sub-Module Connections ---
    wire [2*width-1:0] next_rem;
    wire [2*width-1:0] next_div;
    wire [  width-1:0] next_quot;
    wire [       39:0] partial_product_out;

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

    Multiplier32x8 mul_unit (
                       .A      (abs_op1),
                       .B      (current_byte_op2),
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
        case (count[1:0])
            2'b00:
                current_byte_op2 = abs_op2[7:0];
            2'b01:
                current_byte_op2 = abs_op2[15:8];
            2'b10:
                current_byte_op2 = abs_op2[23:16];
            2'b11:
                current_byte_op2 = abs_op2[31:24];
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
                    1:
                        mult_acc = mult_acc + partial_product_out;
                    2:
                        mult_acc = mult_acc + (partial_product_out << 8);
                    3:
                        mult_acc = mult_acc + (partial_product_out << 16);
                    4:
                        mult_acc = mult_acc + (partial_product_out << 24);
                endcase
            end

            if (count == 4) begin
                done <= 1'b1;
                // Sign Correction
                if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1]))
                    final_product = ~mult_acc + 1;
                else
                    final_product = mult_acc;
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
        end
        else begin  // Divide Output
            Result1 <= div_result_buf[width-1:0];  // Quotient
            Result2 <= div_result_buf[2*width-1:width];  // Remainder
        end
    end

endmodule
