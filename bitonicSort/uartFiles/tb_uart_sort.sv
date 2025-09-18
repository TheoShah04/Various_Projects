`timescale 1ns/1ps

module tb_uart_sort;

    // Testbench signals
    logic clk100;
    logic rst;
    logic [7:0] uart_rx;
    logic [7:0] uart_tx;
    localparam WIDTH = 32;
    localparam DEPTH = 8;
    localparam NUM_SEQ = 10;

    // Instantiate DUT
    uart_sort_top #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .NUM_SEQ(NUM_SEQ)
    ) dut (
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

    task send_uart_int(input [31:0] b);
        integer i;
        begin
            // Data bits (LSB first)
            for (i = 0; i < 4; i++) begin
                send_uart_byte(b[8*i+:8]);
            end
        end
    endtask

    // Stimulus
    initial begin
        // Wait for reset release
        @(negedge rst);

        // Wait a bit
        #100000;

        send_uart_int(32'd01);
        send_uart_int(32'd02);
        send_uart_int(32'd04);
        send_uart_int(32'd05);
        send_uart_int(32'd06);
        send_uart_int(32'd07);
        send_uart_int(32'd21);
        send_uart_int(32'd01);

        send_uart_int(32'd10);
        send_uart_int(32'd20);
        send_uart_int(32'd21);
        send_uart_int(32'd42);
        send_uart_int(32'd01);
        send_uart_int(32'd02);
        send_uart_int(32'd04);
        send_uart_int(32'd05);

        // Done
        #300000;
        $stop;
    end

endmodule
