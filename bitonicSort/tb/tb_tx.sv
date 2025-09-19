`timescale 1ns/1ps

module tb_tx;

  // Parameters
  localparam CLK_FREQ = 100_000_000;
  localparam BAUD     = 115200;
  localparam WIDTH    = 32;
  localparam DEPTH    = 8;
  localparam NUM_SEQ  = 10;

  // Clock and reset
  logic clk;
  logic rst;

  // Upstream signals
  logic valid_in;
  logic [WIDTH-1:0] array_in [DEPTH-1:0];
  logic full;

  // tx_buffer → uart_tx
  logic [7:0] byte_out, rx_data;
  logic valid_out, rx_valid, data_end;

  // uart_tx outputs
  logic tx;
  logic busy;

  // Clock gen
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  // DUTs
  tx_buffer #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .NUM_SEQ(NUM_SEQ)
  ) dut_buffer (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .array_in(array_in),
    .full(full),
    .tx_busy(busy),
    .byte_out(byte_out),
    .valid_out(valid_out)
  );

  uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD(BAUD)
  ) dut_uart_tx (
    .clk(clk),
    .rst(rst),
    .data(byte_out),
    .start(valid_out),
    .tx(tx),
    .busy(busy)
  );

  uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD(BAUD)
  ) dut_uart_rx (
    .clk(clk),
    .rst(rst),
    .rx(tx),        // connect to DUT's TX line
    .data(rx_data),
    .valid_out(rx_valid),
    .data_end(data_end)
  );

  // Stimulus
  initial begin
    // Init
    rst      = 1;
    valid_in = 0;
    array_in = '{default:'0};
    #100;
    rst = 0;

    // Stream several sequences into tx_buffer
    for(int j = 0; j < 8; j++) begin
      @(posedge clk);
      if (!full) begin
        valid_in = 1;
        // unique pattern per sequence
        foreach (array_in[i]) begin
          array_in[i] = i + j; 
        end
      end else begin
        valid_in = 0; // pause if buffer full
      end
    end
    @(posedge clk);
    valid_in = 0;

    // Let UART drain buffer
    repeat (300000) @(posedge clk);

    $finish;
  end

  always @(posedge clk) begin
    if (rx_valid) begin
      $display("[%0t] RX got byte: %02x", $time, rx_data);
    end
  end

endmodule
