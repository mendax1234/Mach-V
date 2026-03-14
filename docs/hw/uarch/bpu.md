# Branch Prediction Unit

The branch prediction unit (BPU) consists of two parts

1. Branch Target Buffer (BTB)
2. Branch History Table (BHT)

This section will serve to explain the different branch prediction strategies I have tried on Mach-V.

## 1-bit Branch Predictor

<!-- md:version 1.2 -->

To implement a 1-bit branch predictor, the design uses two structures:

- [Branch History Table (BHT)](#branch-history-table-bht)
- [Branch Target Buffer (BTB)](#branch-target-buffer-btb)

The architecture of the 1-bit branch predictor is shown as follows:

![1-bit Branch Predictor Block Diagram](../../assets/images/1-bit-branch-predictor-structure.svg)
///caption
1-bit Branch Predictor Block Diagram
///

The main change is in the `PC_In` signal selection, I have separated it into two stages:

1. **Speculative Execution (Fetch Stage)**: The speculative next PC is chosen based on the BHT prediction.
    - If `PrPCSrcF= 1` (predicted taken), the speculative next PC is `PrBTAF`.
    - Else, the speculative next PC is `PCPlus4F`.
2. **Resolution (Memory Stage)**: The actual branch outcome is evaluated against the speculative prediction to catch and correct errors.
    - If the `BranchMispredictM == 1`, the next PC is corrected to `PC_ResolvedM`, which is the correct next PC based on the actual branch outcome. This is becauase a misprediction occurred due to an error in either:
        - Branch decision (`MispredPCSrcM`): The CPU guessed the wrong action. This ensures that the instruction was actually a branch/jump (not just a normal instruction like `ADD`) and that the Taken/Not Taken prediction was correct.
        - Branch target (`MispredBTAM`): The CPU guessed the wrong destination. This checks if the predicted address matches the actual resolved target address.
    - Otherwise, we use the speculative next PC value from step 1.

Another important thing is how the `BranchMispredictM` signal affects the `Hazard.v` unit. So, what is done here is that I use `BranchMispredictM` to replace the `PCSrcM[0]` in the [non branch predictor unit](./hazard-unit.md#priority-inversion-the-lost-jump-scenario) version.

!!! note "Why the BHT does not care about the instruction type?"
    The BHT's only job is to provide a fast, speculative prediction based on the instruction address during the Fetch stage, without needing to know the actual instruction type. If a non-branch instruction is incorrectly predicted as a branch, the Memory stage catches this by comparing the authoritative, decoded `PCSrc[0]` against the prediction (`PrPCSrcM`). This mismatch automatically triggers a misprediction flush (`BranchMispredictM = 1`), seamlessly correcting the PC.

### Branch History Table (BHT)

The Branch History Table stores 1-bit `PCSrc[0]` for any type of instruction.

![BHT Block Diagram](../../assets/images/Branch-History-Table-1-bit.svg)
///caption
Branch History Table (1-bit) Block Diagram
///

#### Functionality

- In the Fetch stage, `PCF` indexes the BHT to produce `PrPCSrcF`, which predicts whether the current instruction will take a branch.
- In the Memory stage, if a branch instruction is resolved and found to be mispredicted, the corresponding BHT entry is updated using `PCM`.

---

#### Inputs

- `PCF`: Index used to read the BHT and generate a prediction in the Fetch stage.
- `PCM`: Index used to update the BHT when the actual branch outcome is known.
- `PCSrcM`: The actual branch outcome (taken or not taken) determined in the Memory stage.
- `WE_PrPCSrc`: Write enable signal, asserted only when a branch is mispredicted and the BHT entry must be corrected.

---

#### Output

- `PrPCSrcF`: Predicted PCSrc value for the instruction in the Fetch stage.

---

!!! note
    `PCSrc[1:0]` indicates whether an instruction is a branch/jump instuction and it so, it also indicates whether the branch is taken (`1`) or not taken (`0`).

### Branch Target Buffer (BTB)

The Branch Target Buffer stores the target address of previously taken branches.

![BTB Block Diagram](../../assets/images/Branch-Target-Buffer-1-bit.svg)
///caption
Branch Target Buffer (1-bit) Block Diagram
///

#### Functionality

- In the Fetch stage, `PCF` indexes the BTB to obtain `PrBTAF`, the predicted branch target address.
- In the Memory stage, if a branch is mispredicted or newly encountered, the BTB entry is updated with the correct target address using `PCM`.

---

#### Inputs

- `PCF`: Index used to read the BTB in the Fetch stage.
- `PCM`: Index used to update the BTB entry in the Memory stage.
- `BTAM`: The actual branch target address computed when the branch is resolved.
- `WE_PrBTA`: Write enable signal, asserted only when the BTB needs to be updated.

---

#### Output

- `PrBTAF`: Predicted branch target address for the instruction in the Fetch stage.