# Pipeline Design

The Hydra-V uses a classic 5-stage pipeline.

## Datapath Diagram

![System Architecture](../assets/images/Hydra-V-0.1.svg)

## Stage Breakdown

### 1. Instruction Fetch (IF)

* **PC Logic**: Updates program counter by $+4$ or branch target.
* **Instruction Memory**: Single-cycle read latency.

### 2. Decode (ID)

* **Register File**: Dual read ports, single write port.
* **Control Unit**: Generates signals based on Opcode/Funct3.

```mermaid
graph LR
    IF[Fetch] --> ID[Decode];
    ID --> EX[Execute];
    EX --> MEM[Memory];
    MEM --> WB[Writeback];
    style EX fill:#f9f,stroke:#333,stroke-width:2px
```

### 3. Execute (EX)

The computational heart of the processor.

* **ALU (Arithmetic Logic Unit)**: Performs Add, Sub, AND, OR, XOR, SLL, SRL, SRA.
* **Branch Comparator**: Compares operands for `BEQ`, `BNE`, `BLT`, etc.
* **Branch Target Calculation**:

    $$ \text{Target} = PC_{\text{current}} + (\text{Immediate} \ll 1) $$

### 4. Memory Access (MEM)

Handles Load and Store instructions.

* **Data Memory**: Reads or writes data if `MemRead` or `MemWrite` is high.
* **IO Mapping**: Addresses in the `0x8000_XXXX` range bypass RAM and go to MMIO (Memory Mapped IO) for peripherals like LEDs and UART.

### 5. Writeback (WB)

The final stage where results are committed.

* **Multiplexer**: Selects data from either **ALU Result**, **Data Memory**, or **PC+4** (for JAL/JALR).
* **Register Write**: The selected data is written back to the destination register `rd`.
