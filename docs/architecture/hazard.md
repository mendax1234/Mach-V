# Hazards & Complex Logic

This section details how the Hydra-V processor handles data and control hazards to maintain pipeline throughput.

## Data Hazards

Data hazards occur when an instruction depends on the result of a previous instruction that has not yet been committed to the Register File.

### Forwarding Unit

To resolve Read-After-Write (RAW) hazards without stalling, we implement a **Full Forwarding Unit**. This unit bypasses data from the `EX` or `MEM` stages directly to the ALU inputs.

| Source Stage | Condition | Forwarding Path | Priority |
| :--- | :--- | :--- | :--- |
| **EX/MEM** | `rd == rs1` or `rd == rs2` | ALU Result $\rightarrow$ ALU Input | High |
| **MEM/WB** | `rd == rs1` or `rd == rs2` | Writeback Data $\rightarrow$ ALU Input | Low |

### Load-Use Hazard

Forwarding cannot solve a "Load-Use" hazard because the data comes from Data Memory (available in WB) but is needed immediately in EX.

* **Solution:** The pipeline **stalls for 1 cycle**.
* **Signal:** `stall_IF_ID` and `stall_ID_EX` go HIGH; `flush_EX` goes HIGH.

---

## Control Hazards (Branching)

The pipeline needs to know the next PC address in the Fetch stage, but the Branch/Jump decision is made in the **Execute (EX)** stage.

!!! warning "Static Prediction"
    The current implementation uses **"Assume Not Taken"** static prediction.

### Flushing Logic

If a branch is taken:

1. The instructions currently in **Fetch** and **Decode** are wrong.
2. The Control Unit asserts `flush_ID` and `flush_EX`.
3. These instructions become `NOP` (bubbles).
4. The PC is updated to the `Branch Target`.

---

## Verilog Implementation Details

Here is a snippet of the Forwarding Logic implemented in the Core:

```verilog
// Forwarding Logic for Operand A
always @(*) begin
    if ((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) begin
        // Forward from ALU Result (EX/MEM pipeline register)
        forward_a = 2'b10;
    end
    else if ((mem_wb_reg_write) && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1)) begin
        // Forward from Writeback (MEM/WB pipeline register)
        forward_a = 2'b01;
    end
    else begin
        // No forwarding (use Register File output)
        forward_a = 2'b00;
    end
end
```
