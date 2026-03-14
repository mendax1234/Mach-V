# In-Order Superscalar Architecture

This section is a brief overview of fascinating but complex topics. In my [DDCA notes](https://wenbo-notes.gitbook.io/ddca-notes/lec/lec-06-advanced-processor#multiple-issue-processors), I have some really good examples regarding the techniques introduced here. If you want to learn more details, I highly recommend to check out those notes.

**Pipelining** exploits the potential **parallelism** among instructions. This parallelism is called, naturally enough, **instruction-level parallelism (ILP)**. There are two primary methods for increasing the potential amount of instruction-level parallelism:

1. **[Deep Pipelining](https://wenbo-notes.gitbook.io/ddca-notes/lec/lec-06-advanced-processor#deep-pipelining)**
2. **Multiple Issue**: A scheme whereby multiple instructions are launched in one clock cycle.

There are also two main ways to implement a multiple-issue processor, with the major difference being the division of work between the compiler and the hardware:

1. **Static Multiple Issue**: An approach to implementing a multiple-issue processor where many decisions are made by the **compiler before execution**.
2. **Dynamic Multiple Issue**: An approach to implementing a multiple-issue processor where many decisions are made **during execution by the processor**.

Static multiple-issue processors all use the **compiler** to assist with packaging instructions and handling hazards. In a static issue processor, you can think of the set of instructions issued in a given clock cycle, which is called an **issue packet**, as one large instruction with multiple operations. This view is more than an analogy. Since a static multiple-issue processor usually restricts what mix of instructions can be initiated in a given clock cycle, it is useful to think of the issue packet as a single instruction allowing several operations in certain predefined fields. This view also led to the original name for this approach: **[Very Long Instruction Word (VLIW)](https://wenbo-notes.gitbook.io/ddca-notes/lec/lec-06-advanced-processor#vliw-processor)**.

!!! info "Use Latency"
    **Use latency** is the number of clock cycles between a **load** instruction and an instruction that can use the result of the load without stalling the pipeline. For example, loads have a use latency of one clock cycle. In the two-issue, five-stage pipieline, the result of a load instruction cannot be used on the next clock cycle. This means that the next *two* instructions cannot use the load result without stalling.

<!-- md:experimental -->

In Mach-V, instead of seeking help from the compiler, I am going to implement an **in-order superscalar processor**. There will be a hardware unit to handle the instruction packaging during the execution and some other units used for different purposes, so technically it is a **dynamic multiple-issue processor**. As this architecture is rather complex, I will explain it part-by-part.

## Instruction Issue Unit

!!! warning
    To implement the 2-way in-order superscalar architecture, the processor should be able to read two instructions simultaneously from the IROM. This is achieveable by using the [Block RAM](../mem/main-memory.md#block-ram) and the example is provided by [AMD](https://docs.amd.com/r/en-US/ug901-vivado-synthesis/True-Dual-Port-Block-RAM-Examples).

The overal architecture of the instruction issue unit (IIU) is shown below.

![Instruction Issue Unit](../../assets/images/instruction-issue-unit.svg)
///caption
Instruction Issue Unit
///

The IIU is implemented in the **Decode** stage. Whenever dependency arises between the instructions on the Instruction 1 wire and the Instruction 2 wire, the **second** instruction will be stored in a hold register and a "rollback" signal will be asserted to adjust next-PC value so that the next-PC coming into the IROM will be PC+4 instead of PC+8 (We will talk more about the Next-PC Logic in detail later). The held instruction will be issued in the next clock cycle.

!!! warning
    The Instruction 1 and 2 represent the instructions on the Instruction 1 wire and Instruction 2 wire!

The three multiplexers in the figure each has their own purpose:

- The Hold Mux (Top Left): Controls what gets saved into the Hold Register. Inputs are Instruction 1 (`0`), Instruction 2 (`1`), and NOP (`2`).
- The Pipe 1 Mux (Top Right): Controls what enters the first execution pipeline. Inputs are Instruction 1 (`0`) and held instruction (`1`).
- The Pipe 2 Mux (Bottom Right): Controls what enters the second execution pipeline. Inputs are Instruction 1 (`0`), Instruction 2 (`1`), and NOP (`2`).

And to understand its flow better, let's look at all the 4 possible cases:

=== "Hold Register is Empty"

    The IIU evaluates Instruction 1 and Instruction 2 directly from the IROM.
    
    1. **If No Dependency**: Both instructions issue normally.
        - Pipe 1 Mux Control: `0` (Selects Instruction 1)
        - Pipe 2 Mux Control: `1` (Selects Instruction 2)
        - Hold Mux Control: `2` (Selects NOP, Hold Register remains empty)
        - Rollback Signal: `0` (Next PC = PC+8)
    2. **If Dependency Detected**: Instruction 2 cannot be issued simulatenously.
        - Pipe 1 Mux Control: `0` (Selects Instruction 1)
        - Pipe 2 Mux Control: `2` (Selects NOP, Pipeline 2 is stalled)
        - Hold Mux Control: `1` (Selects Instruction 2 to be held)
        - Rollback Signal: `1` (Next PC = PC+4)

=== "Hold Register is Full"

    In this case, the hold register has already contained a **valid** instruction. Because the processor issues in-order, the Held Instruction **must** go to Pipe 1. The IIU now evaluates dependencies between the Held Instruction and the instruction on the Instruction 1 wire.

    1. **If No Dependency between Hold and Instr 1**: Both can be issued.
        - Pipe 1 Mux Control: `1` (Selects Held Instruction)
        - Pipe 2 Mux Control: `0` (Selects Instruction 1)
        - Hold Mux Control: `2` (Selects NOP, Hold Register is cleared)
        - Rollback Signal: `0` (Next PC = PC+8)
    2. **If Dependency Detected between Hold and Instr 1**: Only the held instruction can be issued.
        - Pipe 1 Mux Control: `1` (Selects Held Instruction)
        - Pipe 2 Mux Control: `2` (Selects NOP)
        - Hold Mux Control: `0` (Selects Instruction 1 to be held)
        - Rollback Signal: `1` (Next PC = PC+4)

The behavior of superscalar instruction fecthin mechanism is illustrated in the following table assuming only the first two instructions are having dependency.

| Cycle | Fetch Stage | Decode Stage |
| ----- | ----------- | ------------ |
| 1 | **Current Instructions**: I0, I1<br>**Next Instructions**: I2, I3<br>*rollback* = 0 | **First Instruction**: Null<br>**Second Instruction**: Null<br>**held instruction**: Null |
| 2 | **Current Instructions**: I2, I3<br>**Next Instructions**: I3, I4<br>*rollback* = 1 | **First Instruction**: I0<br>**Second Instruction**: Null<br>**held instruction**: I1 |
| 3 | **Current Instructions**: I3, I4<br>**Next Instructions**: I5, I6<br>*rollback* = 0 | **First Instruction**: I1<br>**Second Instruction**: I2<br>**held instruction**: Null |

From this table, we can see clearly that the instructions on the Instruction 1 and Instruction 2 wires in the IIU in the Decode Stage are actually the **current instructions** in the Fetch Stage in the previous cycle. In the Decode Stage, a rollback signal will be generated **combinationally** and this immediately affects the **next instructions** in the current clock cycle.

!!! tip "Debugging Tips"
    A good way to debug the IIU is to draw a table like above manually. The procedure is as follows:

    1. Assume we are in cycle 2 now, first write the **current instructions** out first.
    2. The `Instr_1` and `Instr_2` in the Decode stage of cycle 2 should come from the **current instructions** in the Fetch stage in the previous cycle, which is cycle 1.
    3. The rollback signal in cycle 2 is generated based on the dependency between `Instr_1` and `Instr_2` in the Decode stage of cycle 2.
    4. Based on this rollback signal, write the **next instructions** in the Fetch stage of cycle 2.
    5. Move to cycle 3 and the current instructions will be just the **next instructions** in the Fetch stage of cycle 2. Repeat the same procedure.

### Instruction Dependency Detection

In the IIU, the following conventions are used for the instruction dependency detection:

- Two instructions are issued to the pipeline only if the **second instruction** does not have any dependency on the **first instruction**. In case of dependencies, only the first instruction is issued and the second instruction is held at the Decode stage.
- Two **memory access** instructions (load or store) or two **branch** instructions are never issued together.
- **Load, branch, multiply/divide** instructions are issued **only** through the first pipeline. In other words, **only one** load, branch, or multiply/divide instruction can be issued a time.

!!! warning
    In the design of IIU, only one multiply/divide instruction can exist in one issue packet. This is because if there is some other instruction issued together with the multiply/divide instruction, as the multiply/divide instruction is a multi-cycle instruction, that instruction will finish before the multiply/divide instruction. To solve this issue, in Mach-V V2.0, I just simply replace the second instruction with a NOP whenever the first instruction is a multiply/divide instruction.

    The same thing applies to the branch/jump instruction as well. If the branch instruction is mispredicted, the second instruction in the issue packet must be flushed.

    Also if the first pipe is a jump instruction, the second pipe should always be filled with a NOP.

With these conventions, besides the change of the IROM we have mentioned at the [beginning](#instruction-issue-unit), the rest of changes for the Mach-V microarchitecture are:

1. Add two read ports and one write port to the register file.
2. Add one more ALUs so now we have two ALUs.

## Next-PC Logic

As the normal Next-PC Logic, this part will cover several pipeline stages and which stages are covered really depends on the program execution flow. The architecture for the Next-PC logic is shown below.

![Next-PC Logic](../../assets/images/next-pc-logic.svg)
///caption
Next-PC Logic
///

The Next-PC Logic has two paths:

1. The upper path: This is to deal with the "rollback" signal from the IIU, which is already explained in the previous section.
2. The lower path: This is to deal with the superscalar branch prediction unit.

The structure of the BPU Issuing Unit is shown below.

![BPU Issuing Unit](../../assets/images/bpu-issue.svg)
///caption
BPU Issuing Unit
///

The BPU Issuing Unit is implemented in the **Fetch Stage** for feeding the PC value to the BPU.

1. If the held instruction is a branch, the PC value from the hold register in the **Decode Stage** is fed to the BPU.
2. Otherwise, the `PCF` will be fed to the BPU as normal.

!!! success
    The spirit for having this unit is that in the in-order superscalar architecture, the **next** issue packet can be either `PCF+4`, `PCF+8` or the **BTA** of the PC value of the held instruction if it is a branch or the `PCF`.

Coming back to the Next-PC Logic, we have three multiplexers:

1. The Rollback Mux (Top Left): Whenever the rollback signal is asserted in the Decode Stage, the next PC value will be `PCF+4`; otherwise, it will be `PCF+8`.
2. The Prediction Mux (Middle): In the Fetch Stage, if the BPU predicts the target PC value of an instruction (`PrPCSrcF == 1'b1`), the predicted PC from the BPU (`PrBTAF`) will be loaded. Otherwise, it passes the sequential PC through.
3. The Correction Mux (Right): If the prediction goes wrong (`BranchMispredictM == 1'b1`), then the correct PC value will be loaded from the Memory Stage (`PC_ResolvedM`). This overrides everything else fetched in the current cycle.

## Forwarding Unit

The forwarding unit is implemented in the Decode, Execute and Memory stages to handle the data hazards arising from the dependencies between instructions.

!!! warning
    If instructions in both the pipelines make a hazard situation, then the data from the second pipeline taks priority, since at any stage, the instruction in the second pipeline is the latest one. For example, if two `add` instructions write to the same register, then the result from the second `add` instruction will be forwarded.
