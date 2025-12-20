# PC Logic

This section details the implementation of the Program Counter (PC) logic, covering `PC_Logic.v`, `ProgramCounter.v`, and the relevant multiplexing logic for the PC adder within `RV.v`.

## Moving PC Logic to the Mem Stage

In Mach-V Version 2, the PC logic was relocated from the Execute (Exe) stage to the Memory (Mem) stage. This architectural change implies that branch and jump instructions are now committed in the Mem stage. This optimization significantly improved timing performance, allowing Mach-V to achieve a clock frequency of 115 MHz (utilizing the Clocking Wizard IP).

To support this transition, the input logic for the PC Adder was redesigned as follows:

1. **`PC_Base` Selection**: The base address multiplexer now accepts three new inputs:
    - `PCF`: For sequential execution (Branch Not Taken).
    - `PCM`: For conditional branches (Branch Taken).
    - `RD1M`: For jump instructions. Note that `RD1M` is derived from `RD1E_Forwarded` and latched into the Mem stage pipeline register.
2. **`PC_Offset` Selection**: The offset multiplexer now selects between `4` (sequential) or `ExtImmM` (branch/jump targets).

Following the PC adder updates, the `PC_Logic` module itself was simplified. The control signals `PCSE` and `ALUFlagsE` are propagated through the pipeline registers to become `PCSM` and `ALUFlagsM`. These are then fed into the PC Logic unit in the Mem stage, generating the final branch decision signal, `PCSrcM`.

!!! info
    The updated microarchitecture diagram illustrating the move of PC Logic to the Mem stage can be found [here](index.md/#mach-v-version-2).

!!! warning
    Simply delaying the control signals is insufficient for this architectural change. The [Hazard Unit](hazard.md) must also be updated to handle the new branch resolution timing correctly.
