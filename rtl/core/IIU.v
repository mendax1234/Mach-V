`timescale 1ns / 1ps

module IIU (
        input  wire        CLK,
        input  wire        RESET,
        input  wire        FlushD,
        input  wire        StallD,
        input  wire [31:0] Instr_1_in,
        input  wire [31:0] Instr_2_in,
        input  wire [31:0] PCD,
        input  wire        PrPCSrcD,

        output reg  [31:0] Instr_1_out,
        output reg  [31:0] Instr_2_out,
        output reg  [31:0] PCD_1_out,
        output reg  [31:0] PCD_2_out,
        output reg         Rollback,

        output wire [31:0] Hold_PC,
        output wire        Hold_Is_Branch
    );

    localparam NOP = 32'h00000013;

    // Only kill Slot 2 if the INCOMING Slot 1 is a jumping branch.
    wire instr1_is_branch = (Instr_1_in[6:0] == 7'b1100011) ||
         (Instr_1_in[6:0] == 7'b1101111) ||
         (Instr_1_in[6:0] == 7'b1100111);
    wire kill_incoming_slot2 = instr1_is_branch && PrPCSrcD;
    wire [31:0] safe_Instr_2_in = kill_incoming_slot2 ? NOP : Instr_2_in;

    // Hold Register State
    reg [31:0] hold_reg    = 32'h00000013;
    reg [31:0] hold_pc_reg = 32'b0;
    reg        hold_valid  = 1'b0;

    // Update the Hold check to include JAL and JALR
    assign Hold_Is_Branch = hold_valid && (
               (hold_reg[6:0] == 7'b1100011) ||
               (hold_reg[6:0] == 7'b1101111) ||
               (hold_reg[6:0] == 7'b1100111)
           );

    assign Hold_PC = hold_pc_reg;

    // Mux Selections
    reg [1:0] pipe1_sel;
    reg [1:0] pipe2_sel;
    reg [1:0] hold_sel;

    wire [31:0] eval_1 = hold_valid ? hold_reg : Instr_1_in;
    wire [31:0] eval_2 = hold_valid ? Instr_1_in : safe_Instr_2_in;

    // --- Dependency Decoding Logic ---
    wire [6:0] op_1 = eval_1[6:0];
    wire [4:0] rd_1 = eval_1[11:7];
    wire [6:0] f7_1 = eval_1[31:25];

    wire [6:0] op_2 = eval_2[6:0];
    wire [4:0] rs1_2 = eval_2[19:15];
    wire [4:0] rs2_2 = eval_2[24:20];
    wire [6:0] f7_2 = eval_2[31:25];

    // Instruction type flags for Eval 1
    wire is_load_1     = (op_1 == 7'b0000011);
    wire is_store_1    = (op_1 == 7'b0100011);
    wire is_b_branch_1 = (op_1 == 7'b1100011); // Conditional Branch
    wire is_j_branch_1 = (op_1 == 7'b1101111) || (op_1 == 7'b1100111); // JAL, JALR
    wire is_ctrl_1     = is_b_branch_1 || is_j_branch_1; // ANY Control Flow
    wire is_muldiv_1   = (op_1 == 7'b0110011) && (f7_1 == 7'b0000001);

    // JAL/JALR write to RD. B-type branches do not.
    wire writes_rd_1   = (rd_1 != 5'b0) && !is_store_1 && !is_b_branch_1;

    // Instruction type flags for Eval 2
    wire is_load_2     = (op_2 == 7'b0000011);
    wire is_store_2    = (op_2 == 7'b0100011);
    wire is_b_branch_2 = (op_2 == 7'b1100011);
    wire is_j_branch_2 = (op_2 == 7'b1101111) || (op_2 == 7'b1100111);
    wire is_ctrl_2     = is_b_branch_2 || is_j_branch_2;
    wire is_muldiv_2   = (op_2 == 7'b0110011) && (f7_2 == 7'b0000001);

    // Check if Eval 2 reads registers
    wire uses_rs1_2 = (op_2 == 7'b0110011) || (op_2 == 7'b0010011) || is_load_2 || is_store_2 || is_b_branch_2 || (op_2 == 7'b1100111);
    wire uses_rs2_2 = (op_2 == 7'b0110011) || is_store_2 || is_b_branch_2;

    // --- Collision Conditions ---
    wire hazard_rs1 = writes_rd_1 && uses_rs1_2 && (rd_1 == rs1_2);
    wire hazard_rs2 = writes_rd_1 && uses_rs2_2 && (rd_1 == rs2_2);
    wire hazard_rd  = writes_rd_1 && (op_2 != 7'b1100011) && (op_2 != 7'b0100011) && (rd_1 == eval_2[11:7]); // WAW

    wire mem_conflict         = (is_load_1 || is_store_1) && (is_load_2 || is_store_2);
    wire branch_conflict      = is_ctrl_1 && is_ctrl_2;
    wire pipe1_only_violation = is_load_2 || is_ctrl_2 || is_muldiv_2; // Force ALL jumps to Pipe 1

    wire dependency = hazard_rs1 || hazard_rs2 || hazard_rd || mem_conflict || branch_conflict || pipe1_only_violation || is_muldiv_1;

    // --- Control Logic ---
    always @(*) begin
        if (!hold_valid) begin
            if (!dependency) begin
                pipe1_sel = 2'd0;
                pipe2_sel = 2'd1;
                hold_sel = 2'd2;
                Rollback = 1'b0;
            end
            else begin
                pipe1_sel = 2'd0;
                pipe2_sel = 2'd2;
                hold_sel = 2'd1;
                Rollback = 1'b1;
            end
        end
        else begin
            if (!dependency) begin
                pipe1_sel = 2'd1;
                pipe2_sel = 2'd0;
                hold_sel = 2'd2;
                Rollback = 1'b0;
            end
            else begin
                pipe1_sel = 2'd1;
                pipe2_sel = 2'd2;
                hold_sel = 2'd0;
                Rollback = 1'b1;
            end
        end
    end

    // --- Mux Implementations ---
    always @(*) begin
        // Pipeline 1 PC Tracking
        if (pipe1_sel == 2'd0) begin
            Instr_1_out = Instr_1_in;
            PCD_1_out   = PCD;
        end
        else begin
            Instr_1_out = hold_reg;
            PCD_1_out   = hold_pc_reg;
        end
        // Pipeline 2 PC Tracking
        if (pipe2_sel == 2'd0) begin
            Instr_2_out = Instr_1_in;
            PCD_2_out   = PCD;
        end
        else if (pipe2_sel == 2'd1) begin
            Instr_2_out = safe_Instr_2_in;
            PCD_2_out   = PCD + 32'd4;
        end
        else begin
            Instr_2_out = NOP;
            PCD_2_out   = PCD + 32'd4; // Default safe value
        end
    end

    // --- Sequential Hold Register ---
    always @(posedge CLK) begin
        if (RESET || FlushD) begin
            hold_reg    <= NOP;
            hold_pc_reg <= 32'b0;
            hold_valid  <= 1'b0;
        end
        else if (~StallD) begin
            if (hold_sel == 2'd0) begin
                hold_reg    <= Instr_1_in;
                hold_pc_reg <= PCD;
                hold_valid  <= 1'b1;
            end
            else if (hold_sel == 2'd1) begin
                hold_reg    <= safe_Instr_2_in;
                hold_pc_reg <= PCD + 32'd4;
                hold_valid  <= 1'b1;
            end
            else begin
                hold_reg    <= NOP;
                hold_valid  <= 1'b0;
            end
        end
    end
endmodule
