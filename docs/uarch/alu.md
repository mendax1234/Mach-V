# Arithmetic & Logic Unit (ALU)

The Mach-V ALU is a streamlined execution unit derived from the reference design used in [NUS CG3207](https://github.com/NUS-CG3207/labs/blob/main/docs/code_templates/Asst_02/ALU.v). It implements standard RISC-V integer arithmetic and logical operations, utilizing a [barrel shifter](https://github.com/NUS-CG3207/labs/blob/main/docs/code_templates/Asst_02/Shifter.v) designed by NUS CG3207 teaching team for efficient single-cycle shift operations.

## Zero Flag Optimization

<!-- md:version 2.0 -->
<!-- md:feature -->

While the base architecture is inherited, a critical timing optimization was introduced to the **Zero (Z) flag generation**. In the [reference design](https://github.com/NUS-CG3207/labs/blob/main/docs/code_templates/Asst_02/ALU.v#L79), the Z flag is typically derived from the final `ALUResult` (after the result multiplexer). This creates a long logic chain: `Adder -> Result Mux -> Zero Check`.

To reduce the critical path, Mach-V computes the Z flag directly from the 33-bit adder output (`Sum`) **in parallel** with the result multiplexer. This decouples the flag generation from the multiplexing logic, significantly reducing propagation delay.

```verilog
// Critical Path Optimization: 
// Calculate Zero flag from the intermediate Sum rather than the final ALUResult
assign Z = (Sum[31:0] == 32'b0);
```

!!! Failure "Timing Closure"
    This optimization is mandatory for Mach-V to achieve timing closure at 115 MHz. Reverting to the standard post-mux Zero generation will cause setup time violations on the Vivado tool.
