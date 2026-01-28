/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   Wrapper
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   System Wrapper for Mach-V RISC-V Processor.
--
-- Credits:       Based on the original CG3207 project architecture designed by 
--                Prof. Rajesh Panicker. This implementation is a clean-room 
--                rewrite in Verilog to support the Mach-V open-source project.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

`timescale 1ns / 1ps

module Wrapper #(
    parameter N_LEDS = 16,
    parameter N_DIPS = 16,
    parameter N_PBS  = 3
) (
    input wire              CLK,
    input wire              RESET,
    input wire [N_DIPS-1:0] DIP,
    input wire [ N_PBS-1:0] PB,

    output reg  [ 7:0] LED_OUT,
    output wire [ 6:0] LED_PC,
    output reg  [31:0] SEVENSEGHEX,

    output reg  [7:0] UART_TX_DATA,
    output reg        UART_TX_VALID,
    input  wire       UART_TX_READY,
    input  wire [7:0] UART_RX_DATA,
    input  wire       UART_RX_VALID,
    output reg        UART_RX_ACK,

    output reg        OLED_WRITE,
    output reg [ 6:0] OLED_COL,
    output reg [ 5:0] OLED_ROW,
    output reg [23:0] OLED_PIXEL_DATA,

    input wire [31:0] ACCEL_DATA,
    input wire        ACCEL_READY
);

    // =========================================================================
    // Memory & Offsets
    // =========================================================================
    localparam IMEM_BASE = 32'h0040_0000;
    localparam DMEM_BASE = 32'h1001_0000;
    localparam MMIO_BASE = 32'hFFFF_0000;

    localparam IMEM_DEPTH = 15;
    localparam DMEM_DEPTH = 14;

    localparam OFF_UART_RX_VALID = 8'h00;
    localparam OFF_UART_RX_DATA = 8'h04;
    localparam OFF_UART_TX_READY = 8'h08;
    localparam OFF_UART_TX_DATA = 8'h0C;
    localparam OFF_OLED_COL = 8'h20;
    localparam OFF_OLED_ROW = 8'h24;
    localparam OFF_OLED_DATA = 8'h28;
    localparam OFF_OLED_CTRL = 8'h2C;
    localparam OFF_ACCEL_DATA = 8'h40;
    localparam OFF_ACCEL_READY = 8'h44;
    localparam OFF_LEDS = 8'h60;
    localparam OFF_DIPS = 8'h64;
    localparam OFF_PBS = 8'h68;
    localparam OFF_SEVENSEG = 8'h80;
    localparam OFF_CYCLE_COUNT = 8'hA0;

    // =========================================================================
    // Internal Signals
    // =========================================================================
    reg  [31:0] imem                                              [0:(2**(IMEM_DEPTH-2))-1];
    reg  [31:0] dmem                                              [0:(2**(DMEM_DEPTH-2))-1];

    wire [31:0] rv_pc;
    wire [31:0] rv_instr;
    wire [31:0] rv_addr;
    wire [31:0] rv_wdata;
    wire [ 3:0] rv_be;  // Byte Enable (From Processor)
    wire        rv_memwrite;  // Write Enable (Derived from rv_be)
    wire        rv_memread;

    reg  [31:0] mem_rdata;
    reg  [31:0] cycle_count;

    // Derive Memory Write Signal from Byte Enables
    assign rv_memwrite = |rv_be;  // (rv_be != 0)

    initial begin
        $readmemh("AA_IROM.mem", imem);
        $readmemh("AA_DMEM.mem", dmem);
    end

    // =========================================================================
    // Decoding
    // =========================================================================
    wire is_imem = (rv_pc[31:IMEM_DEPTH] == IMEM_BASE[31:IMEM_DEPTH]);
    wire is_dmem = (rv_addr[31:DMEM_DEPTH] == DMEM_BASE[31:DMEM_DEPTH]);
    wire is_mmio = (rv_addr[31:8] == MMIO_BASE[31:8]);

    // IROM Read
    // This can be changed to trigger an exception instead if need be.
    reg [31:0] rv_instr_reg;
    
    // Assign the registered output to the processor wire
    assign rv_instr = rv_instr_reg;

    always @(negedge CLK) begin
        if (is_imem) begin
            // Synchronous Read: Data available on NEXT clock edge
            rv_instr_reg <= imem[rv_pc[IMEM_DEPTH-1:2]]; 
        end else begin
            // Return NOP if address is invalid
            rv_instr_reg <= 32'h00000013; 
        end
    end

    // =========================================================================
    // Data Memory Access (Synchronous Read)
    // =========================================================================
    integer i;
    reg [31:0] dmem_rdata;
    always @(negedge CLK) begin
        if (rv_memwrite && is_dmem) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (rv_be[i]) begin
                    dmem[rv_addr[DMEM_DEPTH-1:2]][8*i+:8] <= rv_wdata[8*i+:8];
                end
            end
        end
        dmem_rdata <= is_dmem ? dmem[rv_addr[DMEM_DEPTH-1:2]] : 32'b0;
    end

    // =========================================================================
    // MMIO Read Logic
    // =========================================================================
    reg [31:0] mmio_rdata;
    always @(*) begin
        mmio_rdata = 32'd0;
        if (is_mmio) begin
            case (rv_addr[7:0])
                OFF_UART_RX_VALID: mmio_rdata = {31'b0, UART_RX_VALID};
                OFF_UART_RX_DATA: mmio_rdata = {24'b0, UART_RX_DATA};
                OFF_UART_TX_READY: mmio_rdata = {31'b0, UART_TX_READY};
                OFF_ACCEL_DATA: mmio_rdata = ACCEL_DATA;
                OFF_ACCEL_READY: mmio_rdata = {31'b0, ACCEL_READY};
                OFF_DIPS: mmio_rdata = {16'b0, DIP};
                OFF_PBS: mmio_rdata = {29'b0, PB};
                OFF_CYCLE_COUNT: mmio_rdata = cycle_count;
                default: mmio_rdata = 32'd0;
            endcase
        end
    end

    always @(*) begin
        if (is_dmem) mem_rdata = dmem_rdata;
        else if (is_mmio) mem_rdata = mmio_rdata;
        else mem_rdata = 32'd0;
    end

    // =========================================================================
    // MMIO Write Logic
    // =========================================================================
    always @(posedge CLK) begin
        if (RESET) cycle_count <= 0;
        else cycle_count <= cycle_count + 1;
    end

    always @(posedge CLK) begin
        UART_TX_VALID <= 1'b0;
        UART_RX_ACK <= 1'b0;

        if (RESET) begin
            LED_OUT <= 8'b0;
            SEVENSEGHEX <= 32'b0;
            UART_TX_DATA <= 8'b0;
        end else if (rv_memwrite && is_mmio) begin
            if (rv_addr[7:0] == OFF_LEDS && rv_be[0]) LED_OUT <= rv_wdata[7:0];
            if (rv_addr[7:0] == OFF_SEVENSEG) begin
                if (rv_be[0]) SEVENSEGHEX[7:0] <= rv_wdata[7:0];
                if (rv_be[1]) SEVENSEGHEX[15:8] <= rv_wdata[15:8];
                if (rv_be[2]) SEVENSEGHEX[23:16] <= rv_wdata[23:16];
                if (rv_be[3]) SEVENSEGHEX[31:24] <= rv_wdata[31:24];
            end
            if (rv_addr[7:0] == OFF_UART_TX_DATA && UART_TX_READY) begin
                UART_TX_DATA <= rv_wdata[7:0];
                UART_TX_VALID <= 1'b1;
            end
        end
        if (rv_memread && is_mmio && (rv_addr[7:0] == OFF_UART_RX_DATA)) begin
            if (UART_RX_VALID) UART_RX_ACK <= 1'b1;
        end
    end

    // =========================================================================
    // OLED Controller
    // =========================================================================
    reg [7:0] oled_ctrl;

    always @(posedge CLK) begin
        OLED_WRITE <= 1'b0;
        if (RESET) begin
            OLED_COL <= 0;
            OLED_ROW <= 0;
            oled_ctrl <= 0;
        end else if (rv_memwrite && is_mmio) begin
            case (rv_addr[7:0])
                OFF_OLED_CTRL: if (rv_be[0]) oled_ctrl <= rv_wdata[7:0];
                OFF_OLED_ROW: if (rv_be[0]) OLED_ROW <= rv_wdata[5:0];
                OFF_OLED_COL: if (rv_be[0]) OLED_COL <= rv_wdata[6:0];
                OFF_OLED_DATA: begin
                    if (oled_ctrl[7:4] == 4'b0001) begin  // 16-bit
                        if (rv_be[0] && rv_be[1])
                            OLED_PIXEL_DATA <= {rv_wdata[15:11], 3'b0, rv_wdata[10:5], 2'b0, rv_wdata[4:0], 3'b0};
                    end else if (oled_ctrl[7:4] == 4'b0010) begin  // 24-bit
                        if (rv_be[0]) OLED_PIXEL_DATA[7:0] <= rv_wdata[7:0];
                        if (rv_be[1]) OLED_PIXEL_DATA[15:8] <= rv_wdata[15:8];
                        if (rv_be[2]) OLED_PIXEL_DATA[23:16] <= rv_wdata[23:16];
                    end else begin  // Default 8-bit
                        if (rv_be[0])
                            OLED_PIXEL_DATA <= {rv_wdata[7:5], 5'b0, rv_wdata[4:2], 5'b0, rv_wdata[1:0], 6'b0};
                    end

                    OLED_WRITE <= 1'b1;

                    if (oled_ctrl[3:0] == 4'b0100) begin  // Row Major
                        if (OLED_COL >= 95) begin
                            OLED_COL <= 0;
                            OLED_ROW <= (OLED_ROW == 63) ? 0 : OLED_ROW + 1;
                        end else begin
                            OLED_COL <= OLED_COL + 1;
                        end
                    end else if (oled_ctrl[3:0] == 4'b0101) begin  // Col Major
                        if (OLED_ROW >= 63) begin
                            OLED_ROW <= 0;
                            OLED_COL <= (OLED_COL >= 95) ? 0 : OLED_COL + 1;
                        end else begin
                            OLED_ROW <= OLED_ROW + 1;
                        end
                    end
                end
            endcase
        end
    end

    assign LED_PC = rv_pc[8:2];

    RV #(
        .PC_INIT(IMEM_BASE)
    ) rv_core (
        .CLK           (CLK),
        .RESET         (RESET),
        .Instr         (rv_instr),
        .ReadData_in   (mem_rdata),
        .MemRead       (rv_memread),
        .MemWrite_out  (rv_be),
        .PC            (rv_pc),
        .ComputeResultM(rv_addr),
        .WriteData_out (rv_wdata)
    );

endmodule
