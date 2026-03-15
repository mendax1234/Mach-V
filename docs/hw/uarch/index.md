# Microarchitecture

## Microarchitecture Overview

The microarchitecture of Mach-V has currently evolved through two distinct iterations:

### Mach-V Version 2

The second major version of Mach-V features a significant architectural shift towards an in-order superscalar design. This version emphasizes modularity so that the RTL transformation skills in EE4415 can be applied easily to improve the throughput.

=== "Mach-V V2.0"

    ![Mach-V V2.0 Microarchitecture](../../assets/images/Mach-V-V2-0.svg)
    ///caption
    Mach-V Microarchitecture - Version 2.0
    ///

    Mach-V Version 2.0 focuses on the in-order superscalar architecture, more specifically, the 2-issue in-order superscalar architecture. The main features of this version include:

    1. **In-Order Superscalar Architecture:** Implements a 2-issue in-order superscalar architecture to allow 2 instructions to be issued and executed simultaneously, get 1.17x coremark improvement compared to the single-issue (V1.0).


### Mach-V Version 1

The first major version of Mach-V focuses on implementing a baseline RISC-V processor. As a result, the entire microarchitecture is presented as one large, monolithic diagram, without grouping the blocks according to their respective functions.

=== "Mach-V V1.0"

    ![Mach-V V1.0 Microarchitecture](../../assets/images/Mach-V-V1-0.svg)
    ///caption
    Mach-V Microarchitecture - Version 1.0
    ///

    Mach-V Version 1.0 serves as the baseline implementation, featuring a classic RISC-V scalar architecture:

    1. **Classic 5-Stage Pipeline:** Implements the standard Fetch, Decode, Execute, Memory, and Writeback stages for balanced throughput.
    2. **Comprehensive Hazard Management:** Dedicated hardware for data forwarding and hazard detection resolves data and control hazards automatically.
    3. **Scalar In-Order Execution:** Issues, executes, and commits instructions sequentially (single-issue) to ensure deterministic behavior and architectural simplicity.

=== "Mach-V V1.1"

    ![Mach-V V1.1 Microarchitecture](../../assets/images/Mach-V-V1-1.svg)
    ///caption
    Mach-V Microarchitecture - Version 1.1
    ///

    Mach-V Version 1.1 focuses on timing optimization and hardware acceleration, introducing the following enhancements:
    
    1. **Enhanced Clock Frequency:** Integrated Clock Wizard boosts the operating frequency to **115 MHz** (surpassing the 100 MHz baseline).
    2. **Critical Path Optimization:** PC logic is relocated from the Execute (EXE) stage to the Memory (MEM) stage to relax timing constraints.
    3. **Hardware-Accelerated Arithmetic:** Replaces native design with optimized AMD/Xilinx IP cores for high-performance integer multiplication and division.

=== "Mach-V V1.2"

    ![Mach-V V1.2 Microarchitecture](../../assets/images/Mach-V-V1-2.svg)
    ///caption
    Mach-V Microarchitecture - Version 1.2
    ///

    Mach-V Version 1.2 focuses on the 1-bit Branch Predictor, introducing the following enhancements:

    1. **1-bit Branch Predictor:** Implements a simple 1-bit branch predictor to improve control flow efficiency by predicting the outcome of branch instructions and achieves a 15% improvement in Coremark scores.
    2. **The usage of Block RAM:** Utilizes Block RAM for IROM and DMEM and reduces the area of the design by 50% compared to the previous version.
