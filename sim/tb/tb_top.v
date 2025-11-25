`timescale 1ns / 1ps

module benchmark_sim ();
    // Inputs to the DUT
    reg  [15:0] DIP = 0;
    reg  [ 2:0] PB = 0;
    reg         UART_TX_ready = 1'b1;  // CRITICAL: Must be 1 so the CPU doesn't wait forever
    reg  [ 7:0] UART_RX = 8'd0;
    reg         UART_RX_valid = 1'b0;  // CoreMark does not expect any RX input
    reg  [31:0] ACCEL_Data = 32'd0;
    reg         RESET = 0;
    reg         CLK = 0;

    // Outputs from the DUT
    wire [ 7:0] LED_OUT;
    wire [ 6:0] LED_PC;
    wire [31:0] SEVENSEGHEX;
    wire [ 7:0] UART_TX;
    wire        UART_TX_valid;
    wire        UART_RX_ack;
    wire        OLED_Write;
    wire [ 6:0] OLED_Col;
    wire [ 5:0] OLED_Row;
    wire [23:0] OLED_Data;
    wire        ACCEL_DReady;


    Wrapper dut (
        .DIP          (DIP),
        .PB           (PB),
        .LED_OUT      (LED_OUT),
        .LED_PC       (LED_PC),
        .SEVENSEGHEX  (SEVENSEGHEX),
        .UART_TX      (UART_TX),
        .UART_TX_ready(UART_TX_ready),  // Connected to our 'always ready' reg
        .UART_TX_valid(UART_TX_valid),
        .UART_RX      (UART_RX),
        .UART_RX_valid(UART_RX_valid),
        .UART_RX_ack  (UART_RX_ack),
        .OLED_Write   (OLED_Write),
        .OLED_Col     (OLED_Col),
        .OLED_Row     (OLED_Row),
        .OLED_Data    (OLED_Data),
        .ACCEL_Data   (ACCEL_Data),
        .ACCEL_DReady (ACCEL_DReady),
        .RESET        (RESET),
        .CLK          (CLK)
    );

    // 1. Clock Generator (100MHz)
    always #5 CLK = ~CLK;

    // 2. Main Simulation Thread
    initial begin
        // Initialize all inputs
        DIP = 16'd0;
        PB = 3'd0;
        UART_TX_ready = 1'b1;  // Signal that UART is always ready to receive
        UART_RX = 8'd0;
        UART_RX_valid = 1'b0;  // We are not sending any data to the CPU
        ACCEL_Data = 32'd0;

        // Pulse reset to start the CPU
        RESET = 1;
        #50;
        RESET = 0;

        // Set a timeout for the simulation.
        // 50ms (5 million 10ns-cycles) should be more than enough for 1 iteration.
        #5_000_000_000;

        $display("SIMULATION TIMEOUT: Program did not finish or is stuck.");
        $stop;
    end

    // 3. UART Output Monitor
    // This block watches for the CPU to send a character.
    always @(posedge CLK) begin
        if (UART_TX_valid) begin
            // $display("UART_TX: %c", UART_TX); // Use %c to print as ASCII

            // Or, to avoid simulation formatting issues, just print the hex value
            $display("UART_TX: %h", UART_TX);
        end
    end

endmodule
