# Hazard Handling Unit

The Hazard Handling Unit manages the data and control hazards inherent in Mach-V's 5-stage pipeline architecture. Its primary responsibilities are divided into two logic blocks:

1. **Data Forwarding Logic**: Resolves data hazards by bypassing results from later stages.
2. **Stall & Flush Logic**: Resolves load-use and control hazards by stalling or clearing pipeline registers.

## Forwarding Logic

The stall & flush logic mainly deals with the load-use hazard and control hazard. The version that Mach-V Version 1 uses are also strictly following the rules introduced in NUS CG3207 or in Harris & Harris DDCA.

Specific implementation details can be found in the source code Hazard.v and strictly follow the datapath connections shown in the microarchitecture diagram.

## Stall & Flush Logic

The base implementation of the Stall & Flush logic handles standard Load-Use hazards and Control hazards, also following NUS CG3207 and DDCA (Harris & Harris) model.

### Modifications for Mem Stage Branching

To support moving the PC Logic to the Memory (Mem) stage, significant modifications were required to the interaction between the Hazard Unit, the Stall signals, and the Multi-Cycle Unit.

---

#### Priority Inversion: The "Lost Jump" Scenario

**The problem**: When a branch/jump instruction reaches the Mem stage and resolves to branch/jump, the instruction immediately following it (the "ghost" instruction) is already in the Execute or Decode stage. If this ghost instruction triggers a Hazard Stall (e.g., a Load-Use stall or a Multi-Cycle Busy signal), a conflict arises.

In the previous design, the PC update logic prioritized `StallF` over the new PC target (`PC_IN`). Because `StallF` was high (caused by the ghost instruction), the PC retained its current value, effectively ignoring the jump request. This caused the CPU to "fall through" and execute instructions that should have been skipped.

**The Solution**: Control flow changes must be prioritized over stall signals. I modified the logic to force stall signals to `0` whenever a branch or jump is confirmed (`PCSrcM` is active). This ensures that if the processor is jumping, hazards caused by instructions in the flush shadow are ignored.

```verilog
// Before: Stall logic only looked at hazards
// assign StallF = lwStall | Busy;
// assign StallD = lwStall | Busy;

// After: Force Stall to 0 if a branch (PCSrcM[0]) is happening
assign StallF = (lwStall | Busy) & ~PCSrcM[0];
assign StallD = (lwStall | Busy) & ~PCSrcM[0];
```

---

#### Spurious Execution in Mul/Div Operations

**The Problem**: When a branch/jump instruction takes a branch/jump in the Mem stage, the subsequent instruction (e.g., a `mul`) may have already advanced to the Execute stage.

Although the Hazard Unit asserts `FlushE` to kill the `mul` for the next clock cycle, the MCycle Unit is combinational logic that reacts to its inputs instantly. It sees the `Start` signal immediately in the current cycle, begins the calculation, and raises the `Busy` flag. This stalls the entire processor to perform a "fake" multiplication that is about to be flushed.

The Solution: I modified the instantiation of the MCycle Unit in `RV.v` to logically "gate" the start signal. If the Execute stage is currently being flushed (`FlushE` is high), the `.Start` input is forced to `0`. This prevents the unit from activating on instructions that are being discarded.

```verilog
MCycle #(
    .width(32)
) MCycle1 (
    // ... other ports ...
    
    // Before: The unit starts immediately, ignoring the flush
    // .Start   (MCycleStartE),

    // After: The unit only starts if we are NOT flushing the stage
    .Start   (MCycleStartE & ~FlushE), 
    
    .Busy    (Busy)
);
```
