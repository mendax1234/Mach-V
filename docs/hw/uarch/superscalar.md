# Superscalar Architecture

This section is a brief overview of fascinating but complex topics. In my [DDCA notes](https://wenbo-notes.gitbook.io/ddca-notes/lec/lec-06-advanced-processor#multiple-issue-processors), I have some really good examples regarding the techniques introduced here. If you want to learn more details, I highly recommend checking out those notes.

**Pipelining** exploits the potential **parallelism** among instructions. This parallelism is called, naturally enough, **instruction-level parallelism (ILP)**. There are two primary methods for increasing the potential amount of instruction-level parallelism:

1. **[Deep Pipelining](https://wenbo-notes.gitbook.io/ddca-notes/lec/lec-06-advanced-processor#deep-pipelining)**
2. **Multiple Issue**: A scheme whereby multiple instructions are launched in one clock cycle.

There are also two main ways to implement a multiple-issue processor, with the major difference being the division of work between the compiler and the hardware:

1. **Static Multiple Issue**: An approach to implementing a multiple-issue processor where many decisions are made by the compiler before execution.
2. **Dynamic Multiple Issue**: An approach to implementing a multiple-issue processor where many decisions are made during execution by the processor.

In Mach-V, instead of seeking help from the compiler, I am going to implement an **in-order superscalar processor**. There will be a hardware unit to handle the instruction packaging during the execution, so technically it is a **dynamic multiple-issue processor**.

!!! info "Use Latency"
    Use latency is the number of clock cycles between a load instruction and an instruction that can use the result of the load without stalling the pipeline. For example, loads have a use latency of one clock cycle. In the two-issue, five-stage pipieline, the result of a load instruction cannot be used on the next clock cycle. This means that the next *two* instructions cannot use the load result without stalling.
