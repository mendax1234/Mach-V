`timescale 1ns / 1ps

module benchmark_sim ();
    // Inputs to the DUT
    reg  [15:0] DIP = 0;
    reg  [ 2:0] PB = 0;
    reg         UART_TX_READY = 1'b1;  // Updated Name
    reg  [ 7:0] UART_RX_DATA = 8'd0;   // Updated Name
    reg         UART_RX_VALID = 1'b0;  // Updated Name
    reg  [31:0] ACCEL_DATA = 32'd0;    // Updated Name
    reg         ACCEL_READY = 1'b0;    // Updated Name
    reg         RESET = 0;
    reg         CLK = 0;

    // Outputs from the DUT
    wire [ 7:0] LED_OUT;
    wire [ 6:0] LED_PC;
    wire [31:0] SEVENSEGHEX;
    wire [ 7:0] UART_TX_DATA;          // Updated Name
    wire        UART_TX_VALID;         // Updated Name
    wire        UART_RX_ACK;           // Updated Name
    wire        OLED_WRITE;            // Updated Name
    wire [ 6:0] OLED_COL;              // Updated Name
    wire [ 5:0] OLED_ROW;              // Updated Name
    wire [23:0] OLED_PIXEL_DATA;       // Updated Name


    // Instantiate the NEW Wrapper
    Wrapper dut (
                .CLK           (CLK),
                .RESET         (RESET),
                .DIP           (DIP),
                .PB            (PB),
                .LED_OUT       (LED_OUT),
                .LED_PC        (LED_PC),
                .SEVENSEGHEX   (SEVENSEGHEX),

                // UART
                .UART_TX_DATA  (UART_TX_DATA),   // Matches new Wrapper port
                .UART_TX_VALID (UART_TX_VALID),  // Matches new Wrapper port
                .UART_TX_READY (UART_TX_READY),  // Matches new Wrapper port
                .UART_RX_DATA  (UART_RX_DATA),   // Matches new Wrapper port
                .UART_RX_VALID (UART_RX_VALID),  // Matches new Wrapper port
                .UART_RX_ACK   (UART_RX_ACK),    // Matches new Wrapper port

                // OLED
                .OLED_WRITE    (OLED_WRITE),       // Matches new Wrapper port
                .OLED_COL      (OLED_COL),         // Matches new Wrapper port
                .OLED_ROW      (OLED_ROW),         // Matches new Wrapper port
                .OLED_PIXEL_DATA (OLED_PIXEL_DATA),// Matches new Wrapper port

                // Accel
                .ACCEL_DATA    (ACCEL_DATA),      // Matches new Wrapper port
                .ACCEL_READY   (ACCEL_READY)      // Matches new Wrapper port
            );

    // 1. Clock Generator (100MHz)
    always #5 CLK = ~CLK;

    // 2. Main Simulation Thread
    initial begin
        // Initialize all inputs
        DIP = 16'd0;
        PB = 3'd0;
        UART_TX_READY = 1'b1;  // Signal that UART is always ready to receive
        UART_RX_DATA = 8'd0;
        UART_RX_VALID = 1'b0;  // We are not sending any data to the CPU
        ACCEL_DATA = 32'd0;
        ACCEL_READY = 1'b0;

        // Pulse reset to start the CPU
        RESET = 1;
        #50;
        RESET = 0;

        // Run for enough time
        #500_000_000; // Run for 50ms simulation time (adjust as needed)

        $display("SIMULATION STOPPED.");
        $stop;
    end

    // 3. UART Output Monitor
    always @(posedge CLK) begin
        if (UART_TX_VALID) begin
            // Print hex value to Tcl Console
            $display("UART_TX: %h (%c)", UART_TX_DATA, UART_TX_DATA);
        end
    end

endmodule
