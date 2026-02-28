`timescale 1ns / 1ps

module tb_True_Dual_Port;

    // 1. Declare Testbench Signals
    reg CLK;
    reg RESET;
    reg [15:0] DIP;
    reg [2:0]  PB;
    reg [31:0] ACCEL_DATA;
    reg        ACCEL_READY;
    reg        UART_RX_VALID;
    reg [7:0]  UART_RX_DATA;
    reg        UART_TX_READY;

    // Dummy wires for outputs
    wire [7:0]  LED_OUT;
    wire [6:0]  LED_PC;
    wire [31:0] SEVENSEGHEX;
    wire [7:0]  UART_TX_DATA;
    wire        UART_TX_VALID;
    wire        UART_RX_ACK;
    wire        OLED_WRITE;
    wire [6:0]  OLED_COL;
    wire [5:0]  OLED_ROW;
    wire [23:0] OLED_PIXEL_DATA;

    // 2. Instantiate the Wrapper
    Wrapper uut (
        .CLK(CLK),
        .RESET(RESET),
        .DIP(DIP),
        .PB(PB),
        .LED_OUT(LED_OUT),
        .LED_PC(LED_PC),
        .SEVENSEGHEX(SEVENSEGHEX),
        .UART_TX_DATA(UART_TX_DATA),
        .UART_TX_VALID(UART_TX_VALID),
        .UART_TX_READY(UART_TX_READY),
        .UART_RX_DATA(UART_RX_DATA),
        .UART_RX_VALID(UART_RX_VALID),
        .UART_RX_ACK(UART_RX_ACK),
        .OLED_WRITE(OLED_WRITE),
        .OLED_COL(OLED_COL),
        .OLED_ROW(OLED_ROW),
        .OLED_PIXEL_DATA(OLED_PIXEL_DATA),
        .ACCEL_DATA(ACCEL_DATA),
        .ACCEL_READY(ACCEL_READY)
    );

    // 3. Clock Generation (100MHz)
    always #5 CLK = ~CLK;

    // 4. Test Sequence
    initial begin
        // Initialize Inputs
        CLK = 0;
        RESET = 1;
        DIP = 0; PB = 0; ACCEL_DATA = 0; ACCEL_READY = 0;
        UART_RX_VALID = 0; UART_RX_DATA = 0; UART_TX_READY = 1;

        // Wait for global reset
        #100;
        RESET = 0;
        #10;

        $display("=================================================");
        $display(" Starting Superscalar IROM Fetch Test");
        $display("=================================================");

        // FORCE the internal PC to test the IROM fetch independently of the RV core
        // IMEM_BASE is 32'h0040_0000

        // Test 1: Fetch from Base Address
        force uut.rv_pc = 32'h0040_0000;
        #10; // Wait 1 clock cycle for the negedge read
        $display("Test 1 (Base): PC = %h | Port 1: %h | Port 2: %h", 
                  uut.rv_pc, uut.rv_instr_1, uut.rv_instr_2);

        // Test 2: Fetch next block (PC + 8)
        force uut.rv_pc = 32'h0040_0008;
        #10;
        $display("Test 2 (+8)  : PC = %h | Port 1: %h | Port 2: %h", 
                  uut.rv_pc, uut.rv_instr_1, uut.rv_instr_2);

        // Test 3: Fetch invalid address (Outside IMEM bounds)
        force uut.rv_pc = 32'h0000_0000; 
        #10;
        // Should return NOPs (32'h00000013) as per your wrapper logic
        $display("Test 3 (Inv) : PC = %h | Port 1: %h | Port 2: %h", 
                  uut.rv_pc, uut.rv_instr_1, uut.rv_instr_2);

        $display("=================================================");
        $display(" Test Complete.");
        $finish;
    end
endmodule