# Microarchitecture

## Performance Benchmark

Here is the performance scaling of the Mach-V core running the CoreMark benchmark.

![CoreMark Performance](../assets/images/mach-v-coremark-performance-light.png#only-light)
![CoreMark Performance](../assets/images/mach-v-coremark-performance-dark.png#only-dark)

## Microarchitecture Overview

The microarchitecture of Mach-V has currently evolved through two distinct iterations:

=== "Mach-V Version 1"

    ![Mach-V V1 Microarchitecture](../assets/images/Mach-V-V1.svg)
    ///caption
    Mach-V Microarchitecture - Version 1
    ///

    Mach-V Version 1 serves as the baseline implementation, featuring a classic RISC-V scalar architecture:

    1. **Classic 5-Stage Pipeline:** Implements the standard Fetch, Decode, Execute, Memory, and Writeback stages for balanced throughput.
    2. **Comprehensive Hazard Management:** Dedicated hardware for data forwarding and hazard detection resolves data and control hazards automatically.
    3. **Scalar In-Order Execution:** Issues, executes, and commits instructions sequentially (single-issue) to ensure deterministic behavior and architectural simplicity.

=== "Mach-V Version 2"

    ![Mach-V V2 Microarchitecture](../assets/images/Mach-V-V2.svg)
    ///caption
    Mach-V Microarchitecture - Version 2
    ///

    Mach-V Version 2 focuses on timing optimization and hardware acceleration, introducing the following enhancements:
    
    1. **Enhanced Clock Frequency:** Integrated Clock Wizard boosts the operating frequency to **115 MHz** (surpassing the 100 MHz baseline).
    2. **Critical Path Optimization:** PC logic is relocated from the Execute (EXE) stage to the Memory (MEM) stage to relax timing constraints.
    3. **Hardware-Accelerated Arithmetic:** Replaces native design with optimized AMD/Xilinx IP cores for high-performance integer multiplication and division.
