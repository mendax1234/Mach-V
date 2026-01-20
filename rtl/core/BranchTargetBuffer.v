module BranchTargetBuffer #(
    parameter ENTRIES    = 64,
    parameter INDEX_BITS = 6
) (
    input wire CLK,
    input wire RESET,

    // FETCH STAGE (Looking up the target)
    input  wire [31:0] PCF,
    output wire [31:0] PrBTAF,

    // MEMORY STAGE (Updating the target)
    input wire [31:0] PCM,
    input wire [31:0] BTAM,     // The calculated/actual Target Address
    input wire        WE_PrBTA  // High when we need to update the target (e.g., Branch Taken)
);

    // --- Memory Array ---
    // Stores 32-bit Target Addresses
    reg  [          31:0] btb     [0:ENTRIES-1];

    // --- Index Calculation ---
    // Extracting bits [7:2] since instructions are 4-byte aligned
    wire [INDEX_BITS-1:0] index_f;
    wire [INDEX_BITS-1:0] index_m;

    assign index_f = PCF[INDEX_BITS+1:2];
    assign index_m = PCM[INDEX_BITS+1:2];

    // --- Prediction Logic (Combinational) ---
    // Read the predicted target address based on Fetch PC
    assign PrBTAF = btb[index_f];

    // --- Update Logic (Synchronous) ---
    integer i;

    always @(posedge CLK) begin
        if (RESET) begin
            // Reset all entries to 0
            for (i = 0; i < ENTRIES; i = i + 1) begin
                btb[i] <= 32'd0;
            end
        end else if (WE_PrBTA) begin
            // Update the target address for the instruction in Memory stage
            btb[index_m] <= BTAM;
        end
    end

endmodule
