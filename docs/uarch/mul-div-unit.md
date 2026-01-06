# Multiply & Divide Unit

In the first two versions of the Mach-V processor, the multiply and divide unit is incorporated into one file called `MCycle.v`. The whole idea of the `MCycle` module is that, while it is doing the computation, the `Busy` signal (output) will be triggered high and this signal will be used to stall the other relevant pipeline registers so that no new instructions are fetched until the multiplication/division is complete.

## State Machine Control

The `MCycle` module utilizes a finite state machine (FSM) to coordinate the multi-cycle execution of multiplication and division operations. This FSM ensures the `Busy` signal is asserted correctly during operation and de-asserted only when the result is valid.

### FSM Architecture

The controller is designed as a **Mealy Machine**.

- The output is the `Busy` signal.
- The inputs are `Start` and `done`.

The FSM consists of two states, encoded using a single binary bit:

- **IDLE ($S_0$):** The unit is waiting for a `Start` signal.
- **COMPUTING ($S_1$):** The unit is executing the operation.

---

#### State Transition Diagram

The following diagram illustrates the transitions and output logic. The arc labels follow the convention "`Input / Output`".

![MCycle State Transition Diagram](../assets/images/MCycle.svg)
///caption
MCycle State Transition Diagram
///

---

#### State Transition & Output Table

The FSM behavior is summarized in the combined transition and output table below.

| Current State ($S$) | Input (`Start`) | Input (`done`) | Next State ($S'$) | Output (`Busy`) |
| --- | --- | --- | --- | --- |
| **IDLE** (0) | 0 | X | **IDLE** (0) | 0 |
| **IDLE** (0) | 1 | X | **COMPUTING** (1) | 1 |
| **COMPUTING** (1) | X | 0 | **COMPUTING** (1) | 1 |
| **COMPUTING** (1) | X | 1 | **IDLE** (0) | 0 |

---

#### Next State Logic

Based on the Verilog implementation, we can derive the boolean equation for the next state $S'$. We encode $S_{\text{IDLE}} = 0$ and $S_{\text{COMPUTING}} = 1$. The next state is high (COMPUTING) if we start a new operation ($Start=1$ in IDLE) or if we are currently computing and not yet finished ($done=0$ in COMPUTING).

$$\begin{align}
S' &= (\bar{S} \cdot Start) + (S \cdot \overline{done})
\end{align}$$

---

#### Output Logic

The `Busy` signal tracks the next state logic exactly in this implementation to ensure 0-cycle response latency.

$$\begin{align}
Busy &= S' \\
Busy &= (\bar{S} \cdot Start) + (S \cdot \overline{done})
\end{align}$$

!!! note "Logic Synthesis vs. Manual Equations"
    While I derived the boolean equations above to analyze the underlying logic (the **Microscopic View**), I do not hard-code these equations in Verilog. I still write the high-level case statement and the synthesis tool will convert the high-level code into the optimized logic gates based on these equations.

### Verilog Implementation

The code implements this FSM using a mixed 2-block style approach to separate the combinational logic from the sequential state updates.

---

#### Combinational Block

This block handles both **Next State Logic** (`n_state`) and **Output Logic** (`Busy`) simultaneously and strictly follows the Mealy machine template introduced in NUS CG3207.

```verilog
always @(*) begin
    // Default assignments to prevent latches
    n_state = state;
    Busy = 1'b0;

    case (state)
        IDLE: begin
            if (Start) begin
                n_state = COMPUTING;
                Busy = 1'b1;  // Mealy output behavior
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

```

---

#### Sequential Block

This block updates the state register on the rising edge of `CLK` .

```verilog
always @(posedge CLK) begin
    if (RESET) state <= IDLE;
    else       state <= n_state;
end

```

### Interaction with Datapath

The `MCycle` module is implemented as a **Finite State Machine with Datapath**. This design pattern separates the control logic (scheduling) from the data processing logic (execution), connected by specific handshake signals and it is implemented in one sequential `always` block.

---

#### The Datapath

The FSM acts as the manager. It has no knowledge of *how* the multiplication works; it simply tracks *status*. The Datapath performs the heavy lifting. It contains the "implicit state" of the operation, such as the cycle counter or the handshake status of the IP cores.

1. **Initialization (In IDLE):** When `Start` is detected, the datapath captures operands and performs sign analysis (2's complement conversion).
2. **Execution (In COMPUTING):**
    - **Multiplication:** Increments a `count` register until it matches the IP latency.
    - **Division:** Waits for the `div_out_valid` signal from the AXI-Stream IP core.
3. **Completion Signal:** When the latency target is met or valid data is received, the Datapath asserts `done`, instructing the FSM to release the `Busy` signal.

---

#### Verilog Coding Style: Mixed Assignments

`MCycle` employs a specific Verilog coding style where **blocking (`=`)** and **non-blocking (`<=`)** assignments are mixed within this sequential `always` block. This is done to perform complex data processing (like 2's complement conversion) in a single clock cycle without creating unnecessary pipeline stages.

| Assignment Type | Target Variable Examples | Hardware Inference | Purpose |
| :--- | :--- | :--- | :--- |
| **Non-Blocking (`<=`)** | `Result1`, `count`, `abs_op1` | **Physical Register** | Defines the sequential state updates. Updates happen at the end of the time step (clock edge). |
| **Blocking (`=`)** | `q_temp`, `sign_op1`, `is_signed_op` | **Combinational Logic** | Acts as "temporary variables". The value is updated immediately, allowing subsequent lines to use the calculated value within the *same* clock cycle. |

For example, during the division post processing period and in the `COMPUTING` state, we extract the quotient and correct its sign before storing it.

```verilog
// 1. Extract (Blocking: q_temp has valid data immediately)
q_temp = div_dout[63:32];

// 2. Modify (Blocking: uses the NEW q_temp value from line above)
if (is_signed_op && (sign_op1 ^ sign_op2))
    q_temp = ~q_temp + 1;

// 3. Store (Non-Blocking: Latches the FINAL calculated value)
Result1 <= q_temp;
```

## Implementation Details

I have tried two implementations for the `MCycle` module:

<div class="grid cards" markdown>

- :material-integrated-circuit-chip: __Custom RTL Design__

    ---

    Implement the multiply and divide unit by "hand-typped" Verilog code.

    [:octicons-arrow-right-24: View Documentation](#custom-rtl-design)

- :simple-circuitverse: __IP Core Integration__

    ---

    Use Xilinx IP cores to implement the multiply and divide unit.

    [:octicons-arrow-right-24: View Documentation](#ip-core-integration)

</div>

### Custom RTL Design

<!-- md:version 1.0 -->
<!-- md:experimental -->

This is a follow-up from [CG3207 Assignment 3](https://nus-cg3207.github.io/labs/asst_manuals/Asst_03/Asst_03/). More specifically, it is my try to finish the first bullet point in the [Task 3 of this assignment](https://nus-cg3207.github.io/labs/asst_manuals/Asst_03/Asst_03/#task-3-enhancements-5-points).

---

#### Multiply Unit

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
    The 8 bits design will still use more hardware than I thought, which will give around 13ns propagation delay. This will limit the Mach-V clock frequency to 50MHz max if the clock wizard is not used!

---

#### Divide Unit

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
    Using the unrolling techniue in the divider unit here will use a lot of hardware! iirc, the propagation delay is around 66ns for this design! Given that high propagation delay, it is impossible to use this design on Mach-V. So, I moved on to the next section, which is to use Xilinix IP core for the multiply and divide unit.

### IP Core Integration

<!-- md:version 1.0 -->
<!-- md:plugin -->
<!-- md:feature -->

As mentioned in the [previous documentation](#native-design), if I only use the unrolling technique, it is impossible to reach higher frequency while keeping the cycles for multiplication and division low. Therefore, I decided to use the AMD IP cores (Multiplier and Divider) to implement the multiply and divide unit.

---

#### Generate the IP Core

The [multiplier IP core](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/multiplier.html) comes from AMD and can be used in Vivado directly.

To use the IP in Vivado, click the "IP Catalog" on the left "Flow Navigator". Then, search for "multiplier". Click the "Multiplier" (not "Complex Multiplier"). And then configure the IP to use the following settings:

1. In the "Basic" tab:
    - Set Multiplier Type to "Parallel Multiplier"
    - Set `A` and `B` to be "unsigned" and "32-bit" wide
    - Set Multiplier Construction to "Use Mults"
    - Set the Optimization Options to "Speed Optimized"
2. In the "Output and Control" tab
    - Make sure the `P` (output) is 64-bit wide.
    - Set the Pipeline Stages to 4.

!!! tip
    With the above settings, the multiplier IP core will take 5 cycles to complete and the propagation is safer for the processor to reach 100MHz and higher.

Simiarly, the [divider IP core](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/divider.html) also comes from AMD and can be used in Vivado directly.

Follow the similar steps as the multiplier IP core, but configure the divider using the following settings:

1. In the "Channel Settings" tab:
    - Set Algorithm type of "Radix 2" and Operand sign to "unsigned".
    - Change dividend and divisor width to "32".
    - Set the Remainder Type to be "Remainder" and fractional width to be "32".
2. In the "Options" tab:
    - Set Clocks per Division to be "1".
    - Set the flow control under AXI4-Stream settings to "Blocking".
    - Set the optimize goal under AXI4-Stream settings to "Performance".

!!! tip
    With the above settings, the divider IP core will take 32 cycles to complete and the propagation is safer for the processor to reach 100MHz and higher.

---

#### Use IP Core

To use the two IP cores that we have generated above, we just need to know the inputs and outputs of each IP core and then instantiate them in our `MCycle.v` to replace the multiple unit and the divide unit that we have implemented manually in the [previous section](#native-design).

```verilog
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
```
