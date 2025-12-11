# Native Design of Multiply & Divide Unit

This is a follow-up from [CG3207 Assignment 3](https://nus-cg3207.github.io/labs/asst_manuals/Asst_03/Asst_03/). More specifically, it is my try to finish the first bullet point in the [Task 3 of this assignment](https://nus-cg3207.github.io/labs/asst_manuals/Asst_03/Asst_03/#task-3-enhancements-5-points).

## Multiply Unit

For the multiply unit, the idea is to "unroll" the loop. For the 32-bit multiplication, instead of using 32 cycles to compute the result by shifting 1 bit a time, I generate the partial products for every 8 bits of the multiplier in parallel. So, the temporal product here will be $32+8=40$ bits wide.

```verilog
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
```

In this module, the input `A` is the full 32-bit multiplicand, while `B` is an 8-bit slice of the multiplier. The output `Product` is the 40-bit partial product. For the sliced version of the multiplier, it can be implemented as follows in the state machine control:

```verilog
case (count[1:0])
    2'b00: current_byte_op2 = abs_op2[7:0];
    2'b01: current_byte_op2 = abs_op2[15:8];
    2'b10: current_byte_op2 = abs_op2[23:16];
    2'b11: current_byte_op2 = abs_op2[31:24];
endcase
```

The final product is then obtained by summing up the 4 partial products with appropriate shifts, which can be implemented as follows:

```verilog
case (count)
    1: mult_acc = mult_acc + partial_product_out;
    2: mult_acc = mult_acc + (partial_product_out << 8);
    3: mult_acc = mult_acc + (partial_product_out << 16);
    4: mult_acc = mult_acc + (partial_product_out << 24);
endcase
```

And lastly, this module is instantiated in the `MCycle` module as follows:

```verilog
Multiplier32x8 mul_unit (
    .A      (abs_op1),
    .B      (current_byte_op2),
    .Product(partial_product_out)
);
```

???+ tip
    This technique can indeed be implementated using `for` loop in Verilog as follows:

    ```verilog
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
    ```

    This is totally valid. However, the smart synthesizer will generate the same hardware for both implementations.

!!! warning
    The 8 bits design will still use more hardware than I thought, which will give around 13ns propagation delay. This will limit the Hydra-V clock frequency to 50MHz max if the clock wizard is not used!

## Divide Unit

Similarly, I did the unrolling for the divider unit as well. So, instead of getting at most 1 bit of quotient and remainder per cycle. Now, I can get at most 8 bits of quotient and remainder per cycle. This divider unit is implemented using the `for` loop in Verilog as follows:

```verilog
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
```

To use the result from the divider unit, the state machine control can just be modified by updating the current remainder and quotient to be the result from the divider unit after each cycle:

```verilog
if (count > 0) begin
    rem = next_rem;
    div = next_div;
    div_result_buf[width-1:0] = next_quot;
    div_result_buf[2*width-1:width] = rem[width-1:0];
end
```

And finally, this divider unit is implemented as follows in the `MCycle` module:

```verilog
DivSlice8 div_unit (
    .rem_in  (rem),
    .div_in  (div),
    .quot_in (div_result_buf[width-1:0]),
    .rem_out (next_rem),
    .div_out (next_div),
    .quot_out(next_quot)
);
```

!!! warning
    Using the unrolling techniue in the divider unit here will use a lot of hardware! iirc, the propagation delay is around 66ns for this design! Given that high propagation delay, it is impossible to use this design on Hydra-V. So, I moved on to the next section, which is to use Xilinix IP core for the multiply and divide unit.
