# Load & Store Unit

Unlike the baseline design from NUS CG3207, Mach-V extends memory support beyond full-word operations. The Load Store Unit (LSU) module handles byte (`lb`/`lbu`/`sb`) and half-word (`lh`/`lhu`/`sh`) transactions, ensuring correct data alignment and sign extension.

The LSU will take 5 inputs and produce 3 outputs:

## Interface Definition

The LSU locates in the Mem stage. It processes raw addresses and data to align them with the memory's 32-bit word boundaries.

| Direction | Signal | Width | Description |
| :--- | :--- | :---: | :--- |
| **Input** | Funct3 | 3 | Instruction function code (determines size and signing). |
| **Input** | MemWriteM | 1 | Write Enable signal from the Control Unit. |
| **Input** | WriteDataM | 32 | Raw data to be written. |
| **Input** | ReadData_in | 32 | Raw 32-bit word read from Data Memory. |
| **Input** | ByteOffset | 2 | The 2 Least Significant Bits (LSB) of the memory address. |
| **Output** | MemWrite_out | 4 | Byte-enable mask sent to Data Memory (1 bit per byte). |
| **Output** | WriteData_out | 32 | Aligned data sent to Data Memory. |
| **Output** | ReadDataM | 32 | Processed data (shifted/extended) sent to Writeback. |

!!! warning "Naming Convention"
    The term "Load Store Unit" typically refers to a complex buffer system in Out-of-Order processors. In the context of the current Mach-V (Scalar In-Order), it refers specifically to the alignment and formatting logic within the Memory stage.

## Store Alignment Logic

The Store Unit is responsible for placing data into the correct "byte lane" before writing to memory. Since memory is word-addressed (32-bit width), sub-word stores (like `sb`) must be shifted to the correct position within the word.

1. **Calculate Shift Amount:** The `ByteOffset` is multiplied by 8 (concatenated with `3'b000`) to convert the byte index into a bit index.
2. **Align Data:** The raw `WriteDataM` is logically left-shifted (`<<`) by this amount.
3. **Generate Mask**: A base mask is selected based on the instruction type (e.g., `0001` for Byte, `0011` for Half-word) and then shifted to the active position.

!!! example "Exmaple from NUS CG3207 Teaching Team"
    `WriteData_out` is a word, with word/byte/half-word aligned to where you wish to write it to within the word. The `MemWrite_out` bits of every byte to be modified should be 1. For example, when running `sb` (store byte) instruction, if the last 2 bits of the address is `2'b10` and the byte to be written (`WriteDataM`) is `8'hAB` (or `32'b000000AB`), `WriteData_out` should be `32'hxxABxxxx` and `MemWrite_out` should be `4'h0100`.

```verilog
// --- STORE PATH (Alignment & Masking) ---
wire [4:0] shamt = {ByteOffset, 3'b000};  // Offset * 8

// Align Data
assign WriteData_out = WriteDataM << shamt;

// Generate Mask
reg [3:0] BaseMask;
always @(*) begin
    case (Funct3)
        3'b000: BaseMask = 4'b0001;  // SB
        3'b001: BaseMask = 4'b0011;  // SH
        default: BaseMask = 4'b1111;  // SW
    endcase
end

// Shift Mask
assign MemWrite_out = (MemWriteM) ? (BaseMask << ByteOffset) : 4'b0000;
```

## Load Extension Logic

The Load Unit performs the inverse operation. It takes a full 32-bit word from memory and extracts the relevant byte or half-word.

1. **Re-Align**: The raw `ReadData_in` is right-shifted (`>>`) by `ByteOffset` bits so that the desired data sits in the Least Significant Bits (LSB).
2. **Sign Extension**: Based on `Funct3`, the logic decides whether to zero-extend (for `lbu`, `lhu`) or sign-extend (for `lb`, `lh`) the result to fill the 32-bit register.

!!! example "Example from NUS CG3207 Teaching Team"
    `ReadData_in` is the whole word that contains the word/half-word/byte you want. You need to extract what you want, with a sign/zero(`u`) extension as required by the instruction. For example, when running `lbu` (load byte unsigned) instruction, if the last 2 bits of the address is `2'b01`, and the address location specified in the instruction has `8'hAB`, `ReadData_in` is `32'hxxxxABxx`. `ReadDataM`, the word to be written into the destination register is `32'h000000AB` (`0`s as MSBs as it is `lbu`).

```verilog
wire [31:0] data_shifted = ReadData_in >> shamt;
reg  [31:0] loaded_val;

always @(*) begin
    case (Funct3)
        3'b000: loaded_val = {{24{data_shifted[7]}}, data_shifted[7:0]};  // LB
        3'b001: loaded_val = {{16{data_shifted[15]}}, data_shifted[15:0]};  // LH
        3'b100: loaded_val = {24'b0, data_shifted[7:0]};  // LBU
        3'b101: loaded_val = {16'b0, data_shifted[15:0]};  // LHU
        default: loaded_val = data_shifted;  // LW
    endcase
end

assign ReadDataM = loaded_val;
```
