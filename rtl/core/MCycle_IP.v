/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   MCycle (IP Version)
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Multi-Cycle Unit implementing multiplication and division.
--                Uses Xilinx IP cores (mult_gen_0 and div_gen_0) for operations.
-- 
-- Credits:       Based on the CG3207 project (Prof. Rajesh Panicker).
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

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
    localparam MUL_LATENCY = 4;  // Adjust based on IP configuration

    reg              state = IDLE;
    reg              n_state = IDLE;
    reg              done;
    reg  [      4:0] count = 0;  // Latency counter

    // --- Input Processing (Sign Handling) ---
    reg  [width-1:0] abs_op1;
    reg  [width-1:0] abs_op2;
    reg              sign_op1;
    reg              sign_op2;
    reg              is_signed_op;

    // --- IP Interface Signals ---
    wire [     63:0] mul_dout;  // Output from Multiplier IP
    wire [     63:0] div_dout;  // Output from Divider IP {Remainder, Quotient}
    wire             div_out_valid;  // "Done" signal from Divider
    reg              div_in_valid;  // "Start" signal for Divider

    // --- Intermediate Results ---
    reg  [     31:0] q_temp;
    reg  [     31:0] r_temp;

    // ========================================================================
    // IP Instantiations
    // ========================================================================

    // Multiplier IP: 32x32 Unsigned -> 64-bit Product
    mult_gen_0 my_multiplier (
        .CLK(CLK),
        .A  (abs_op1),
        .B  (abs_op2),
        .P  (mul_dout)
    );

    // Divider IP: 32/32 Unsigned -> 32 Quot, 32 Rem
    div_gen_0 my_divider (
        .aclk                  (CLK),
        .s_axis_divisor_tvalid (div_in_valid),
        .s_axis_divisor_tdata  (abs_op2),
        .s_axis_dividend_tvalid(div_in_valid),
        .s_axis_dividend_tdata (abs_op1),
        .m_axis_dout_tvalid    (div_out_valid),
        .m_axis_dout_tdata     (div_dout)
    );

    // ========================================================================
    // FSM: State Transition
    // ========================================================================

    always @(posedge CLK) begin
        if (RESET) begin
            state <= IDLE;
        end else begin
            state <= n_state;
        end
    end

    // Logic for Next State and Busy
    always @(*) begin
        // Default
        n_state = state;
        Busy = 1'b0;

        case (state)
            IDLE: begin
                if (Start) begin
                    n_state = COMPUTING;
                    Busy = 1'b1;  // Become Busy immediately on Start
                end
            end
            COMPUTING: begin
                if (done) begin
                    n_state = IDLE;
                    Busy = 1'b0;
                end else begin
                    n_state = COMPUTING;
                    Busy = 1'b1;
                end
            end
        endcase
    end

    // ========================================================================
    // Datapath & Control Logic
    // ========================================================================

    always @(posedge CLK) begin
        if (RESET) begin
            div_in_valid <= 1'b0;
            Result1 <= 0;
            Result2 <= 0;
            count <= 0;
            done <= 1'b0;
            abs_op1 <= 0;
            abs_op2 <= 0;
        end else begin
            // Default: Reset done flag every cycle (unless set below)
            done <= 1'b0;

            // Default: clear divider valid pulse (it only needs to be high for 1 cycle)
            div_in_valid <= 1'b0;

            case (state)
                IDLE: begin
                    if (Start) begin
                        // --- Initialization Phase ---
                        count <= 0;

                        // Sign Analysis
                        is_signed_op = ~MCycleOp[0];  // Even Ops (00, 10) are signed
                        sign_op1 = Operand1[width-1];
                        sign_op2 = Operand2[width-1];

                        // Absolute Value Calculation (Pre-processing)
                        if (is_signed_op && sign_op1) abs_op1 <= ~Operand1 + 1;
                        else abs_op1 <= Operand1;

                        if (is_signed_op && sign_op2) abs_op2 <= ~Operand2 + 1;
                        else abs_op2 <= Operand2;

                        // Trigger Logic
                        if (MCycleOp[1]) begin
                            // Op 10/11 -> Division (Set valid high for next cycle)
                            div_in_valid <= 1'b1;
                        end
                    end
                end

                COMPUTING: begin
                    // --- Arithmetic Phase ---

                    if (~MCycleOp[1]) begin
                        // Multiplication Logic
                        // Wait for fixed latency of Multiplier IP
                        if (count == MUL_LATENCY) begin
                            done <= 1'b1;

                            // Sign Correction (Post-processing)
                            if (is_signed_op && (sign_op1 ^ sign_op2)) begin
                                {Result2, Result1} <= ~mul_dout + 1;
                            end else begin
                                {Result2, Result1} <= mul_dout;
                            end
                        end else begin
                            count <= count + 1;
                        end

                    end else begin
                        // Division Logic
                        // Wait for AXI Stream Valid signal
                        if (div_out_valid) begin
                            done <= 1'b1;

                            // Extract outputs
                            q_temp = div_dout[63:32];  // Quotient
                            r_temp = div_dout[31:0];  // Remainder

                            // Sign Correction (Post-processing)
                            // Quotient is negative if signs differ
                            if (is_signed_op && (sign_op1 ^ sign_op2)) q_temp = ~q_temp + 1;

                            // Remainder takes the sign of the Dividend (Operand1)
                            if (is_signed_op && sign_op1) r_temp = ~r_temp + 1;

                            Result1 <= q_temp;  // Quotient
                            Result2 <= r_temp;  // Remainder
                        end
                    end
                end
            endcase
        end
    end

endmodule
