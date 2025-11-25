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

    reg               state = IDLE;
    reg               n_state = IDLE;
    reg               done;
    reg [        7:0] count = 0;

    // --- Division Variables ---
    reg [2*width-1:0] div_result_buf = 0;  // Buffer for [Remainder (MSW) | Quotient (LSW)]
    reg [2*width-1:0] rem = 0;  // Current Remainder (Initialized with Dividend)
    reg [2*width-1:0] div = 0;  // Current Divisor (Shifted right every cycle)
    reg [  width-1:0] abs_op1 = 0;  // Absolute value of Dividend (Operand1)
    reg [  width-1:0] abs_op2 = 0;  // Absolute value of Divisor (Operand2)
    reg [  2*width:0] diff_ext = 0;  // Extended difference (rem - div) to check Carry bit

    // --- Multiplication Variables (Booth's) ---
    reg [    width:0] A;  // Accumulator
    reg [  width-1:0] Q;  // Multiplier
    reg [  width-1:0] M;  // Multiplicand
    reg               Qm;  // Q[-1]
    reg               correction;  // Unsigned correction flag

    // ========================================================================
    // FSM: State Transition (Combinational)
    // ========================================================================

    always @(state, done, Start, RESET) begin : IDLE_PROCESS
        // Default values
        Busy    <= 1'b0;
        n_state <= IDLE;

        if (~RESET) begin
            case (state)
                IDLE: begin
                    if (Start) begin
                        n_state <= COMPUTING;
                        Busy    <= 1'b1;
                    end
                end
                COMPUTING: begin
                    if (~done) begin
                        n_state <= COMPUTING;
                        Busy    <= 1'b1;
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
            count          = 0;
            div_result_buf = 0;

            // Handle Signs for Division
            abs_op1        = (~MCycleOp[0] && Operand1[width-1]) ? ~Operand1 + 1 : Operand1;
            abs_op2        = (~MCycleOp[0] && Operand2[width-1]) ? ~Operand2 + 1 : Operand2;

            // Align Divisor and Remainder
            div            = {abs_op2, {width{1'b0}}};
            rem            = {{width{1'b0}}, abs_op1};

            // Init Booth's Algo
            A              = 0;
            M              = Operand1;
            Q              = Operand2;
            Qm             = 0;
            correction     = 0;
        end

        // Reset done flag every cycle (will be set to 1 if finished)
        done <= 1'b0;

        // ----------------------------------------
        // Arithmetic Phase
        // ----------------------------------------

        // --- Multiply (Booth's Algorithm) ---
        if (~MCycleOp[1]) begin
            if (~correction) begin
                // Booth's Add/Sub Step
                case ({
                    Q[0], Qm
                })
                    2'b01:   A = A + {M[width-1], M};
                    2'b10:   A = A - {M[width-1], M};
                    default: A = A;
                endcase

                // Arithmetic Shift Right {A, Q, Qm}
                Qm = Q[0];
                Q  = {A[0], Q[width-1:1]};
                A  = {A[width], A[width:1]};

                // Check Termination
                if (count == width - 1) begin
                    if (MCycleOp[0]) correction = 1'b1;  // Need extra cycle for Unsigned
                    else done <= 1'b1;
                end
                count = count + 1;
            end else begin
                // Correction Cycle (for Unsigned Mul)
                if (Operand2[width-1]) A = A + {1'b0, M};
                if (Operand1[width-1]) A = A + {1'b0, Operand2};
                correction = 1'b0;
                done <= 1'b1;
            end
        end  // --- Divide (Shift & Subtract) ---
    else begin
            // Subtract divisor from remainder
            diff_ext = {1'b0, rem} + {1'b0, ~div} + 1'b1;

            if (diff_ext[2*width] == 1'b1) begin
                // Carry=1 -> Result Positive
                // Update Rem, Shift 1 into Quotient.
                rem                       = diff_ext[2*width-1:0];
                div_result_buf[width-1:0] = {div_result_buf[width-2:0], 1'b1};
            end else begin
                // Carry=0 -> Result Negative
                // Restore Rem (do nothing), Shift 0 into Quotient.
                div_result_buf[width-1:0] = {div_result_buf[width-2:0], 1'b0};
            end

            // Shift Divisor Right
            div                             = {1'b0, div[2*width-1:1]};

            // Update upper half of div_result_buf with Remainder
            div_result_buf[2*width-1:width] = rem[width-1:0];

            // Check Termination
            if (count == width) begin
                done <= 1'b1;
                // Sign Correction
                if (~MCycleOp[0] && (Operand1[width-1] ^ Operand2[width-1]))
                    div_result_buf[width-1:0] = ~div_result_buf[width-1:0] + 1;  // Negate Quotient
                if (~MCycleOp[0] && (Operand1[width-1]))
                    div_result_buf[2*width-1:width] = ~div_result_buf[2*width-1:width] + 1;  // Negate Remainder
            end
            count = count + 1;
        end

        // ----------------------------------------
        // Output Phase
        // ----------------------------------------
        if (~MCycleOp[1]) begin  // Multiply Output
            Result1 <= Q;  // LSW
            Result2 <= A[width-1:0];  // MSW
        end else begin  // Divide Output
            Result1 <= div_result_buf[width-1:0];  // Quotient
            Result2 <= div_result_buf[2*width-1:width];  // Remainder
        end
    end

endmodule
