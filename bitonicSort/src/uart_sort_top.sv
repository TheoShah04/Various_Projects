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
    output logic rx_trg_led,
    output logic tx_led,
    output logic rst_led
);

    assign rst_led = rst;
    assign rx_led = uart_rx;
    always_ff @ (posedge CLK100MHZ) begin
        if (rst) begin
            rx_led <= 1'b0;
        end
        else begin
            if (uart_rx == 1'b0) rx_trg_led <= 1'b1;
        end
    end
    assign tx_led = uart_tx; 
    
    logic [7:0] rx_data, tx_data;
    logic rx_valid, tx_busy, end_of_data, start_sort, valid_sort, tx_valid, tx_buffer_full;
    logic [0:WIDTH-1] seq_in [0:DEPTH-1];
    logic [0:WIDTH-1] seq_out [0:DEPTH-1];

    logic [WIDTH*DEPTH-1:0] seq_in_flat;
    logic [WIDTH*DEPTH-1:0] seq_out_flat;
    genvar k;
    generate
        for (k = 0; k < DEPTH; k++) begin
            assign seq_in_flat[(k+1)*WIDTH-1 -: WIDTH] = seq_in[k];
            assign seq_out_flat[(k+1)*WIDTH-1 -: WIDTH] = seq_out[k];
        end
    endgenerate

    ila_0 ILA (
	.clk(CLK100MHZ), // input wire clk
	.probe0(uart_rx), // input wire [0:0]  probe0  
	.probe1(rx_data), // input wire [7:0]  probe1 
	.probe2(rx_valid), // input wire [0:0]  probe2 
	.probe3(rst), // input wire [0:0]  probe3 
	.probe4(seq_in_flat), // input wire [255:0]  probe4 
	.probe5(start_sort), // input wire [0:0]  probe5 
	.probe6(valid_sort), // input wire [0:0]  probe6 
	.probe7(seq_out_flat) // input wire [255:0]  probe7
    );

    uart_rx #(.CLK_FREQ(100_000_000), .BAUD(115200)) u_rx (
        .clk(CLK100MHZ),
        .rst(rst),
        .rx(uart_rx), //port 0
        .data(rx_data), //port 1
        .valid_out(rx_valid), //port 2
        .data_end(end_of_data) //port 3
    );

    rx_buffer #(.WIDTH(WIDTH), .DEPTH(DEPTH), .NUM_SEQ(NUM_SEQ)) rx_data_buffer (
        .clk(CLK100MHZ),
        .rst(rst),
        .valid_in(rx_valid),
        .data_end(end_of_data),
        .byte_in(rx_data),
        .array_out(seq_in), //port 4
        .valid_out(start_sort) //port 5
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
        .valid_in(valid_sort), //port 6
        .tx_busy(tx_busy), 
        .array_in(seq_out), //port 7
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
