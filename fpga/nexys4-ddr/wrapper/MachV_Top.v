/*
----------------------------------------------------------------------------------
-- Company:       National University of Singapore
-- Engineer:      Zhu Wenbo
-- 
-- Create Date:   2026-01-06
-- Module Name:   MachV_Top
-- Project Name:  Mach-V
-- Target Devices: Nexys 4 DDR
-- Description:   Top Level for Mach-V.
-- 
-- Credits:       Based on the original CG3207 project architecture designed by 
--                Prof. Rajesh Panicker. This implementation is a clean-room 
--                rewrite in Verilog to support the Mach-V open-source project.
-- 
-- License:       MIT License
----------------------------------------------------------------------------------
*/

module MachV_Top (
        // Clock
        input wire CLK_undiv,  // Matches pins.xdc (100MHz)

        // Switches & Buttons
        input wire [15:0] DIP,    // Matches pins.xdc
        input wire [ 2:0] PB,     // Matches pins.xdc (Center, Left, Right)
        input wire        PAUSE,  // Matches pins.xdc (BTNU)
        input wire        RESET,  // Matches pins.xdc (BTND)

        // LEDs & Display
        output wire [15:0] LED,         // Matches pins.xdc
        output wire [ 7:0] SevenSegAn,  // Matches pins.xdc
        output wire [ 6:0] SevenSegCat, // Matches pins.xdc

        // UART
        input  wire RX,  // Matches pins.xdc
        output wire TX,  // Matches pins.xdc

        // PMOD OLED (Header JB/JC mapped in XDC)
        output wire PMOD_CS,
        output wire PMOD_MOSI,
        output wire PMOD_SCK,
        output wire PMOD_DC,
        output wire PMOD_RES,
        output wire PMOD_VCCEN,
        output wire PMOD_EN,

        // Accelerometer
        input  wire aclMISO,  // Matches pins.xdc
        output wire aclMOSI,  // Matches pins.xdc
        output wire aclSCK,   // Matches pins.xdc
        output wire aclSS     // Matches pins.xdc
    );

    // =========================================================================
    // 1. System Signals
    // =========================================================================
    localparam SYS_FREQ_HZ = 100000000;
    wire clk_sys;
    wire clk_locked;
    wire sys_reset;
    wire reset_eff;  // Effective Reset

    // Reset Logic
    assign sys_reset = RESET;
    assign reset_eff = sys_reset || (!clk_locked);

    // Wrapper Interconnects
    wire [ 7:0] led_out_data;
    wire [ 6:0] led_pc_data;
    wire [31:0] seven_seg_hex;

    wire [ 7:0] uart_tx_data;
    wire        uart_tx_valid;  // From Wrapper
    reg         uart_tx_ready = 1'b1;  // To Wrapper (Init to 1 to avoid Deadlock)
    wire [ 7:0] uart_data_out;  // From UART Core
    reg         uart_rx_valid;  // To Wrapper
    wire        uart_rx_ack;  // From Wrapper

    wire        oled_write;
    wire [ 6:0] oled_col;
    wire [ 5:0] oled_row;
    wire [23:0] oled_pixel_data;
    wire [15:0] oled_pixel_formatted;

    wire [31:0] accel_data_packed;
    wire        accel_ready;
    wire [11:0] acc_x, acc_y, acc_z, acc_tmp;

    // =========================================================================
    // 2. Clocking Wizard
    // =========================================================================
    // CRITICAL: You MUST configure 'clk_wiz_0' in Vivado to output 115 MHz!
    clk_wiz_0 clk_gen (
                  .clk_in1 (CLK_undiv),
                  .clk_out1(clk_sys),
                  .reset   (RESET),
                  .locked  (clk_locked)
              );

    // =========================================================================
    // 3. UART Logic (Exact VHDL Translation)
    // =========================================================================

    // UART Core Signals
    reg  [7:0] uart_data_in;
    reg        uart_data_in_stb;
    wire       uart_data_in_ack;
    wire       uart_data_out_stb;
    reg        uart_data_out_ack;

    // Internal State Registers
    reg RX_MSF1 = 1'b1, RX_MSF2 = 1'b1;
    reg       uart_tx_valid_prev = 1'b0;
    reg       uart_rx_ack_prev = 1'b0;
    reg       uart_data_out_stb_prev = 1'b0;

    reg [1:0] recv_state = 0;
    localparam RX_STATE_WAITING = 0;
    localparam RX_STATE_ACTIVE = 1;

    always @(posedge clk_sys) begin
        if (RESET) begin
            uart_data_in_stb <= 1'b0;
            uart_data_out_ack <= 1'b0;
            uart_data_in <= 8'b0;
            recv_state <= RX_STATE_WAITING;
            uart_data_out_stb_prev <= 1'b0;
            RX_MSF1 <= 1'b1;
            RX_MSF2 <= 1'b1;
            uart_tx_ready <= 1'b1;
            uart_rx_valid <= 1'b0;

            uart_tx_valid_prev <= 1'b0;
            uart_rx_ack_prev <= 1'b0;
        end
        else begin
            // Metastable Filter
            RX_MSF1 <= RX;
            RX_MSF2 <= RX_MSF1;

            // -----------------------------------------------------
            // Sending (TX)
            // -----------------------------------------------------
            uart_data_out_ack <= 1'b0;

            // Edge Detection on Valid Signal
            if (uart_tx_valid && !uart_tx_valid_prev) begin
                uart_data_in <= uart_tx_data;
                uart_data_in_stb <= 1'b1;
                uart_tx_ready <= 1'b0;
            end

            if (uart_data_in_ack) begin
                uart_data_in_stb <= 1'b0;
                uart_tx_ready <= 1'b1;
            end

            // -----------------------------------------------------
            // Receiving (RX)
            // -----------------------------------------------------
            case (recv_state)
                RX_STATE_WAITING: begin
                    if (uart_data_out_stb && !uart_data_out_stb_prev) begin
                        uart_data_out_ack <= 1'b1;
                        recv_state <= RX_STATE_ACTIVE;
                        uart_rx_valid <= 1'b1;
                    end
                end

                RX_STATE_ACTIVE: begin
                    if (uart_data_out_stb && !uart_data_out_stb_prev) begin
                        uart_data_out_ack <= 1'b1;  // Consume and ignore
                    end

                    if (uart_rx_ack && !uart_rx_ack_prev) begin
                        recv_state <= RX_STATE_WAITING;
                        uart_rx_valid <= 1'b0;
                    end
                end
            endcase

            // Update History
            uart_data_out_stb_prev <= uart_data_out_stb;
            uart_tx_valid_prev <= uart_tx_valid;
            uart_rx_ack_prev <= uart_rx_ack;
        end
    end

    // =========================================================================
    // 4. Wrapper Instantiation
    // =========================================================================
    Wrapper mach_v_wrapper (
                .CLK        (clk_sys),
                .RESET      (reset_eff),
                .DIP        (DIP),
                .PB         (PB),
                .LED_OUT    (led_out_data),
                .LED_PC     (led_pc_data),
                .SEVENSEGHEX(seven_seg_hex),

                // UART
                .UART_TX_DATA (uart_tx_data),
                .UART_TX_VALID(uart_tx_valid),
                .UART_TX_READY(uart_tx_ready),
                .UART_RX_DATA (uart_data_out),
                .UART_RX_VALID(uart_rx_valid),
                .UART_RX_ACK  (uart_rx_ack),

                // OLED
                .OLED_WRITE     (oled_write),
                .OLED_COL       (oled_col),
                .OLED_ROW       (oled_row),
                .OLED_PIXEL_DATA(oled_pixel_data),

                // Accel
                .ACCEL_DATA (accel_data_packed),
                .ACCEL_READY(accel_ready)
            );

    // =========================================================================
    // 5. Output Mapping
    // =========================================================================
    assign LED[7:0] = led_out_data;
    assign LED[8] = clk_sys;
    assign LED[15:9] = led_pc_data;

    // =========================================================================
    // 6. Peripherals (VHDL Instantiation)
    // =========================================================================

    // UART
    UART #(
             .BAUD_RATE      (115200),
             .CLOCK_FREQUENCY(SYS_FREQ_HZ)  // CRITICAL: Matches clk_wiz_0 output
         ) uart_inst (
             .CLOCK              (clk_sys),
             .RESET              (RESET),              // Uses Raw Reset (Matches VHDL)
             .DATA_STREAM_IN     (uart_data_in),
             .DATA_STREAM_IN_STB (uart_data_in_stb),
             .DATA_STREAM_IN_ACK (uart_data_in_ack),
             .DATA_STREAM_OUT    (uart_data_out),
             .DATA_STREAM_OUT_STB(uart_data_out_stb),
             .DATA_STREAM_OUT_ACK(uart_data_out_ack),
             .TX                 (TX),
             .RX                 (RX_MSF2)             // Uses the filtered signal
         );

    // Accelerometer
    ADXL362Ctrl #(
                    .SYSCLK_FREQUENCY_HZ(SYS_FREQ_HZ)  // Matches clk_wiz_0 output
                ) accel_inst (
                    .SYSCLK    (clk_sys),
                    .RESET     (RESET),
                    .ACCEL_X   (acc_x),
                    .ACCEL_Y   (acc_y),
                    .ACCEL_Z   (acc_z),
                    .ACCEL_TMP (acc_tmp),
                    .Data_Ready(accel_ready),
                    .SCLK      (aclSCK),
                    .MOSI      (aclMOSI),
                    .MISO      (aclMISO),
                    .SS        (aclSS)
                );

    assign accel_data_packed = {acc_tmp[11:4], acc_x[11:4], acc_y[11:4], acc_z[11:4]};

    // OLED
    assign oled_pixel_formatted = {oled_pixel_data[23:19], oled_pixel_data[15:10], oled_pixel_data[7:3]};

    PmodOLEDrgb_bitmap #(
                           .CLK_FREQ_HZ(SYS_FREQ_HZ)  // Matches clk_wiz_0 output
                       ) oled_inst (
                           .clk        (clk_sys),
                           .reset      (RESET),
                           .pix_write  (oled_write),
                           .pix_col    (oled_col),
                           .pix_row    (oled_row),
                           .pix_data_in(oled_pixel_formatted),
                           .PMOD_CS    (PMOD_CS),
                           .PMOD_MOSI  (PMOD_MOSI),
                           .PMOD_SCK   (PMOD_SCK),
                           .PMOD_DC    (PMOD_DC),
                           .PMOD_RES   (PMOD_RES),
                           .PMOD_VCCEN (PMOD_VCCEN),
                           .PMOD_EN    (PMOD_EN)
                       );

    // =========================================================================
    // 7. 7-Segment Controller
    // =========================================================================
    reg [19:0] refresh_counter;
    reg [ 3:0] hex_digit;
    reg [ 7:0] anode_reg;

    always @(posedge clk_sys) refresh_counter <= refresh_counter + 1;

    wire [2:0] sel = refresh_counter[19:17];

    always @(*) begin
        anode_reg = 8'hFF;
        anode_reg[sel] = 1'b0;
        case (sel)
            3'd0:
                hex_digit = seven_seg_hex[3:0];
            3'd1:
                hex_digit = seven_seg_hex[7:4];
            3'd2:
                hex_digit = seven_seg_hex[11:8];
            3'd3:
                hex_digit = seven_seg_hex[15:12];
            3'd4:
                hex_digit = seven_seg_hex[19:16];
            3'd5:
                hex_digit = seven_seg_hex[23:20];
            3'd6:
                hex_digit = seven_seg_hex[27:24];
            3'd7:
                hex_digit = seven_seg_hex[31:28];
        endcase
    end

    assign SevenSegAn = anode_reg;

    reg [6:0] cath;
    always @(*) begin
        case (hex_digit)
            4'h0:
                cath = 7'b1000000;
            4'h1:
                cath = 7'b1111001;
            4'h2:
                cath = 7'b0100100;
            4'h3:
                cath = 7'b0110000;
            4'h4:
                cath = 7'b0011001;
            4'h5:
                cath = 7'b0010010;
            4'h6:
                cath = 7'b0000010;
            4'h7:
                cath = 7'b1111000;
            4'h8:
                cath = 7'b0000000;
            4'h9:
                cath = 7'b0010000;
            4'hA:
                cath = 7'b0001000;
            4'hB:
                cath = 7'b0000011;
            4'hC:
                cath = 7'b1000110;
            4'hD:
                cath = 7'b0100001;
            4'hE:
                cath = 7'b0000110;
            4'hF:
                cath = 7'b0001110;
        endcase
    end
    assign SevenSegCat = cath;

endmodule
