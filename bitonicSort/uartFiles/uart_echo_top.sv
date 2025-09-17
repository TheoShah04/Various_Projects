module uart_echo_top(
    input  logic clk,     // 100 MHz clock
    input  logic rst,
    input  logic uart_rx,
    output logic uart_tx
);

    logic [7:0] rx_data;
    logic rx_valid;
    logic tx_busy;

    uart_rx #(.CLK_FREQ(100_000_000), .BAUD(115200)) u_rx (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .data(rx_data),
        .valid_out(rx_valid)
    );

    rx_buffer #(          ) rx_data_buffer (
        .clk(clk),
        .rst(rst),
        .valid_in(rx_valid),
        .byte_in(rx_data),
    );

    // uart_tx #(.CLK_FREQ(100_000_000), .BAUD(115200)) u_tx (
    //     .clk(clk100),
    //     .rst(rst),
    //     .data(rx_data),
    //     .start(rx_valid & ~tx_busy),
    //     .tx(uart_tx),
    //     .busy(tx_busy)
    // );

endmodule
