module BranchHistoryTable #(
        parameter ENTRIES    = 64,
        parameter INDEX_BITS = 6
    ) (
        input wire CLK,
        input wire RESET,

        // FETCH STAGE (Looking up the prediction)
        input  wire [31:0] PCF,
        output wire        PrPCSrcF,

        // MEMORY STAGE (Training the predictor)
        input wire [31:0] PCM,
        input wire        WE_PrPCSrc, // Connected to MispredPCSrcM (High only on error)
        input wire [ 1:0] PCSrcM      // Real outcome: Taken (1) or Not Taken (0)
    );

    // --- Memory Array ---
    // 1-bit wide memory (Stores 0 for Not Taken, 1 for Taken)
    reg bht [0:ENTRIES-1];

    // --- Index Calculation ---
    // Extracting bits [7:2] since instructions are 4-byte aligned
    wire [INDEX_BITS-1:0] index_f;
    wire [INDEX_BITS-1:0] index_m;

    assign index_f = PCF[INDEX_BITS+1:2];
    assign index_m = PCM[INDEX_BITS+1:2];

    // --- Prediction Logic ---
    // Simply read the bit.
    // 1 = Predict Taken, 0 = Predict Not Taken
    assign PrPCSrcF = bht[index_f];

    // --- Update Logic ---
    integer i;
    always @(posedge CLK) begin
        if (RESET) begin
            // Initialize all entries to Not Taken (0)
            // This will make the memory be inferred using FFs instead of LUTs
            for (i = 0; i < ENTRIES; i = i + 1) begin
                bht[i] <= 1'b0;
            end
        end
        else if (WE_PrPCSrc) begin
            // LOGIC: Update on Mispredict Only
            // If WE_PrPCSrc is High, it means our table was WRONG.
            // We overwrite the entry with what actually happened (PCSrcM[0]).
            bht[index_m] <= PCSrcM[0];
        end
    end

endmodule
