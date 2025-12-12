# AMD IP Design

As mentioned in the [previous documentation](native-design.md), if I only use the unrolling technique, it is impossible to reach higher frequency while keeping the cycles for multiplication and division low. Therefore, I decided to use the AMD IP cores (Multiplier and Divider) to implement the multiply and divide unit.

## Generate the IP Core

### Multiplier IP

The [multiplier IP core](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/multiplier.html) comes from AMD and can be used in Vivado directly.

To use the IP in Vivado, click the "IP Catalog" on the left flow navigator. Then, search for "multiplier". Click the "Multiplier" (not "Complex Multiplier"). And the configure the IP to use the following settings:

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

### Divider IP

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

## Use IP Core

To use the two IP cores that we have generated above, we just need to know the inputs and outputs of each IP core and then instantiate them in our `MCycle.v` to replace the multiple unit and the divide unit that we have implemented manually in the [previous section](./native-design.md).

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
