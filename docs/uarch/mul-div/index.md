# Multiply & Divide Unit

In this version of the Mach-V processor, the multiply and divide unit is incorporated into one file called `MCycle.v`. The whole idea of the `MCycle` module is that, while it is doing the computation, the `Busy` signal (output) will be triggered high and this signal will be used to stall the other relevant pipeline registers so that no new instructions are fetched until the multiplication/division is complete.

This module is implemented using the mealy state machine.

## State Machine Control

## Implementation Details

I have tried two implementations for the `MCycle` module:

<div class="grid cards" markdown>

- :material-integrated-circuit-chip: __Native Design__

    ---

    Implement the multiply and divide unit by "hand-typped" Verilog code.

    [:octicons-arrow-right-24: View Documentation](native-design.md)

- :simple-circuitverse: __Using IP Cores__

    ---

    Use Xilinx IP cores to implement the multiply and divide unit.

    [:octicons-arrow-right-24: View Documentation](vendor-ip.md)

</div>
