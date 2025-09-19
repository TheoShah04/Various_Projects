module top #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter NUM_SEQ = 10
    )(
    input  CLK100MHZ,   // 100 MHz clock
    input  rst,
    input  uart_rx,
    output uart_tx,
    output rx_led,
    output tx_led,
    output rst_led
);

    uart_sort_top #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .NUM_SEQ(NUM_SEQ)
    ) u_sort_top (
        .CLK100MHZ(CLK100MHZ),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_led(rx_led),
        .tx_led(tx_led),
        .rst_led(rst_led)
    );

endmodule
