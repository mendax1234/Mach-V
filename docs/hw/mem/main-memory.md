# Main Memory

## Memory Map

The Mach-V processor's main memory consists of Instruction Memory (IROM) and Data Memory (DMEM).

- IROM starts at address `0x00400000`.
- DMEM starts at address `0x10010000`.

And their memory map is as follows:

| Address Range              | Name                        | Permissions        | Description                                                                                               |
|----------------------------|-----------------------------|--------------------|-----------------------------------------------------------------------------------------------------------|
| `0x00400000 – 0x00407FFF`  | IROM (Instruction Memory)   | RO (Read-Only)     | Capacity: 8,192 words (32 KB). Based on `IROM_DEPTH_BITS = 15`.                                           |
| `0x10010000 – 0x10013FFF`  | DMEM (Data Memory)          | RW (Read-Write)    | Capacity: 4,096 words (16 KB). Used for storing constants and variables. Based on `DMEM_DEPTH_BITS = 14`. |

!!! warning "Addressing Constraints"
    Accesses must be aligned to 4-byte boundaries.

## Memory Implementation

In the earlier design of the Mach-V processor (e.g., Mach-V V1 and V2), both IROM and DMEM were implemented using the distributed memory resources available in the FPGA. However, starting from Mach-V V3, I transitioned to using Block RAM (BRAM) for both IROM and DMEM to enhance performance and resource efficiency.

### Block RAM

In Nexys 4 DDR FPGA, there are a certain number of Block RAM (BRAM) resources available. These Block RAMs are read **synchronously**. The easiest way to implement a Block RAM in Verilog is to use explicitly the synchronous read style, as shown below:

```verilog
// Single-port synchronous RAM with read-first behavior
module rams_sp_rf (
    clk,    // Clock input
    en,     // Memory enable
    we,     // Write enable
    addr,   // Memory address
    di,     // Data input (write data)
    dout    // Data output (read data)
);

    input        clk;
    input        we;
    input        en;
    input  [9:0] addr;   // 10-bit address: 1024 words
    input  [15:0] di;    // 16-bit data input
    output [15:0] dout;  // 16-bit data output

    reg [15:0] RAM  [1023:0]; // 1024 × 16-bit memory array
    reg [15:0] dout;         // Registered read data

    // Synchronous read/write operation
    always @(posedge clk) begin
        if (en) begin
            if (we)
                RAM[addr] <= di; // Write data on write enable
            dout <= RAM[addr];   // Read data (read-first behavior)
        end
    end

endmodule
```

In this example (from the official [AMD documentation](https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Single-Port-RAM-with-Read-First-VHDL)), we implement a **single-port Block RAM (Read First)**.

- **Single Port**: There is only one port for both read and write operations.
- **Read First**: When a read and write operation occur simultaneously at the same address, the data read is the old data before the write.

One important characteristic of **Block RAM (BRAM)** is that its **read operation is synchronous** and therefore incurs a **one-clock-cycle latency**. In a pipelined processor, this has direct implications for the **instruction fetch stage**.

![BRAM Explanation](../../assets/images/BRAM-Explanation.svg)
///caption
Block RAM Read Operation Timing
///

During the Fetch stage, the program counter `PCF` is presented to the instruction memory (IROM). However, if the IROM is implemented using BRAM, the memory does not produce valid read data in the same cycle. Instead, the read is initiated at the next edge clock edge (the rising edge of the second clock cycle), and the instruction word becomes available only **after the next clock edge**. Consequently, the fetched instruction `InstrF` is not available until the **end of the following clock cycle**, which corresponds to the **end of the Decode stage**.

??? note "Block RAM vs. Normal Synchronous RAM"
    Unlike the Block RAM, in a synchronous RAM, the working principle is shown below:

    ![Synchronous RAM Read Timing](../../assets/images/synchronous-ram.svg)
    ///caption
    Synchronous RAM Read Operation Timing
    ///

    In a normal synchronous RAM implemented using flip-flops and LUTs, the data read is available at the **next** clock edge after both the `RAM_En` is high and the address is presented to the memory. So, the one cycle delay for reading operation basically means that the data is available at the **next clock edge**.

### Distributed RAM

In contrast, distributed memory resources in the FPGA uses **asynchronous reads**, allowing instruction fetches to complete within the same clock cycle. The implementation of the RAM using distributed memory would look like this:

```verilog
// Single-port asynchronous RAM
module rams_sp_async (
    clk,    // Clock input
    we,     // Write enable
    addr,   // Memory address
    di,     // Data input (write data)
    dout    // Data output (read data)
);

    input        clk;
    input        we;
    input  [9:0] addr;   // 10-bit address: 1024 words
    input  [15:0] di;    // 16-bit data input
    output [15:0] dout;  // 16-bit data output

    reg [15:0] RAM  [1023:0]; // 1024 × 16-bit memory array

    // Asynchronous read operation
    assign dout = RAM[addr];

    // Synchronous write operation
    always @(posedge clk) begin
        if (we)
            RAM[addr] <= di; // Write data on write enable
    end
endmodule
```

One disadvantage of using distributed memory is that it consumes more of the FPGA's lookup tables (LUTs) compared to Block RAM, which is a dedicated memory resource.

??? note "Distributed vs Block RAM"
    Both types write data synchronously into the RAM. Distributed RAM and dedicated block RAM differ primarily in how they read data. See the following table.

    | Action | Distributed RAM | Dedicated Block RAM |
    |--------|-----------------|---------------------|
    | Write  | Synchronous     | Synchronous         |
    | Read   | Asynchronous    | Synchronous         |
