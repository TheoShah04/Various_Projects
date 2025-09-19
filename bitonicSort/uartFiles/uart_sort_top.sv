module uart_sort_top #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter NUM_SEQ = 10
)(
    input  logic CLK100MHZ,     // 100 MHz clock
    input  logic rst,
    input  logic uart_rx,
    output logic uart_tx,
    output logic rx_led,
    output logic tx_led,
    output logic rst_led
);

    assign rst_led = rst;
    assign rx_led = uart_rx;
    assign tx_led = uart_tx; 
    
    logic [7:0] rx_data, tx_data;
    logic rx_valid, tx_busy, end_of_data, start_sort, valid_sort, tx_valid, tx_buffer_full;
    logic [0:WIDTH-1] seq_in [0:DEPTH-1];
    logic [0:WIDTH-1] seq_out [0:DEPTH-1];

    uart_rx #(.CLK_FREQ(100_000_000), .BAUD(115200)) u_rx (
        .clk(CLK100MHZ),
        .rst(rst),
        .rx(uart_rx),
        .data(rx_data),
        .valid_out(rx_valid),
        .data_end(end_of_data)
    );

    rx_buffer #(.WIDTH(WIDTH), .DEPTH(DEPTH), .NUM_SEQ(NUM_SEQ)) rx_data_buffer (
        .clk(CLK100MHZ),
        .rst(rst),
        .valid_in(rx_valid),
        .data_end(end_of_data),
        .byte_in(rx_data),
        .array_out(seq_in),
        .valid_out(start_sort)
    );

    sort_top #(.WIDTH(WIDTH), .DEPTH(DEPTH)) sorting_module (
        .clk(CLK100MHZ),
        .rst(rst),
        .valid_in(start_sort),
        .unsorted(seq_in),
        .sorted(seq_out),
        .valid_out(valid_sort)
    );

    tx_buffer #(.WIDTH(WIDTH), .DEPTH(DEPTH), .NUM_SEQ(NUM_SEQ)) tx_data_buffer (
        .clk(CLK100MHZ),
        .rst(rst),
        .valid_in(valid_sort),
        .tx_busy(tx_busy),
        .array_in(seq_out),
        .full(tx_buffer_full),
        .byte_out(tx_data),
        .valid_out(tx_valid)
    );

    uart_tx #(.CLK_FREQ(100_000_000), .BAUD(115200)) u_tx (
        .clk(CLK100MHZ),
        .rst(rst),
        .data(tx_data),
        .start(tx_valid),
        .tx(uart_tx),
        .busy(tx_busy)
    );

endmodule
