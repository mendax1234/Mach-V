# PC Logic

This section details the implementation of the Program Counter (PC) logic, covering [`PC_Logic.v`](https://github.com/mendax1234/Mach-V/blob/main/rtl/core/PC_Logic.v), [`ProgramCounter.v`](https://github.com/mendax1234/Mach-V/blob/main/rtl/core/ProgramCounter.v), and the relevant multiplexing logic for the PC adder within [`RV.v`](https://github.com/mendax1234/Mach-V/blob/main/rtl/core/RV.v#L136-L150).

## Branch Resolution

<!-- md:version 2.0 -->
<!-- md:default -->

In Mach-V Version 2, branch and jump instructions are **committed in the Mem stage**. Moving this logic from Execute to Memory improved timing performance, allowing the design to achieve a clock frequency of **115 MHz**.

The microarchitecture consists of two main components:

1. **PC Logic Unit**: Determines whether a branch is taken based on ALU flags and branch conditions.
2. **PC Adder**: Computes the next PC value based on the current PC, branch targets, and jump addresses.

### PC Logic Unit

The PC Logic Unit decides how the next PC value is formed. It uses instruction type and ALU comparison results to generate a 2-bit control signal `PCSrc[1:0]`, which selects the PC update behavior.

!!! note
    As `PCSrc[1:0]` controls the next PC value and it is generated in the Mem stage, we say that our branch/jump instructions are "committed" in the Mem stage.

1. `PCS` (Input)
    - Encodes the instruction category (sequential, branch, JAL, JALR).
    - Combined with ALU flags to decide whether a control transfer is taken.
2. `ALUFlags[2:0] = {eq, lt, ltu}` (Input)
    - Result of comparisons performed by the ALU.
    - Used mainly for conditional branches (e.g., BEQ, BLT, BLTU).
3. `PCSrc[1:0]` (Output)
    - Controls how the next PC is computed.

The logic of PC Logic can be summarized in the following table:

| PCS | Instruction | Funct3 | PCSrc[1]   | PCSrc[0]     |
|-----|-------------|--------|------------|--------------|
| 00  | Non control | x      | 0          | 0            |
| 01  | beq         | 000    | 0          | ALUFlags[2]  |
| 01  | bne         | 001    | 0          | ALUFlags[2]' |
| 01  | blt         | 100    | 0          | ALUFlags[1]  |
| 01  | bge         | 101    | 0          | ALUFlags[1]' |
| 01  | bltu        | 110    | 0          | ALUFlags[0]  |
| 01  | bgeu        | 111    | 0          | ALUFlags[0]' |
| 10  | jal         | x      | 0          | 1            |
| 11  | jalr        | x      | 1          | 1            |

### PC Adder

The PC Adder computes the next address (including the branch target or jump address). Because the commitment happens in the Mem stage, the inputs must be sourced correctly to avoid hazards:

- `PC_Base`: Selects between the current PC (`PCF`, `PCM`) or a register value (`RD1M`). Note that `RD1M` is derived from `RD1E_Forwarded` and latched into the Mem stage pipeline register.
- `PC_Offset`: Selects between sequential increment (`+4`) or the branch offset (`+ExtImmM`).

| `PCSrc` | Base (`PC_Base`) | Offset (`PC_Offset`) | Meaning                    |
| ------- | ---------------- | -------------------- | -------------------------- |
| `00`    | `PCF`            | `+4`                 | Sequential execution       |
| `01`    | `PCM`            | `+ExtImm`            | Taken branch or JAL        |
| `10`    | `RD1M`           | `+4`                 | JALR (no immediate offset) |
| `11`    | `RD1M`           | `+ExtImm`            | JALR with immediate        |

!!! warning
    Simply delaying the control signals is insufficient for this microarchitectural change. The [Hazard Unit](hazard-unit.md) must also be updated to handle the new branch resolution timing correctly.

!!! info
    The updated microarchitecture diagram illustrating the move of PC Logic to the Mem stage can be found [in Mach-V Version 2's microarchitecture diagram](./index.md/#mach-v-version-2).
