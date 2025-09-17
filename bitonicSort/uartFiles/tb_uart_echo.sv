`timescale 1ns/1ps

module tb_uart_echo;

    // Testbench signals
    logic clk100;
    logic rst;
    logic [7:0] uart_rx;
    logic [7:0] uart_tx;

    // Instantiate DUT
    uart_echo_top dut (
        .clk(clk100),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // Clock generation: 100 MHz
    initial clk100 = 0;
    always #5 clk100 = ~clk100;  // 10 ns period

    // Reset pulse at start
    initial begin
        rst = 1;
        uart_rx = 1; // idle line is high
        #200;
        rst = 0;
    end

    // Task to send a UART byte
    task send_uart_byte(input [7:0] b);
        integer i;
        begin
            // Start bit
            uart_rx = 0;
            #(8680); // 1 bit period at 115200 baud

            // Data bits (LSB first)
            for (i = 0; i < 8; i++) begin
                uart_rx = b[i];
                #(8680);
            end

            // Stop bit
            uart_rx = 1;
            #(8680);
        end
    endtask

    // Stimulus
    initial begin
        // Wait for reset release
        @(negedge rst);

        // Wait a bit
        #100000;

        // Send 'A' (0x41)
        send_uart_byte(8'h41);

        // Send 'Z' (0x5A)
        send_uart_byte(8'h5A);

        // Done
        #100000;
        $stop;
    end

endmodule
