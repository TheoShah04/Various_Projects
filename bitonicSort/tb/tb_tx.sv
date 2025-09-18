`timescale 1ns/1ps

module tb_tx;

  // Parameters
  localparam CLK_FREQ = 100_000_000;
  localparam BAUD     = 115200;
  localparam WIDTH    = 32;
  localparam DEPTH    = 8;
  localparam NUM_SEQ  = 4;

  // Clock and reset
  logic clk;
  logic rst;

  // Upstream signals
  logic valid_in;
  logic [WIDTH-1:0] array_in [DEPTH-1:0];
  logic full;

  // tx_buffer → uart_tx
  logic [7:0] byte_out;
  logic valid_out;

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
  ) dut_uart (
    .clk(clk),
    .rst(rst),
    .data(byte_out),
    .start(valid_out),
    .tx(tx),
    .busy(busy)
  );

  // Stimulus
  initial begin
    // Initialize
    rst = 1;
    valid_in = 0;
    array_in = '{default:'0};
    #100;
    rst = 0;

    // Push one sequence into buffer
    @(posedge clk);
    valid_in = 1;
    array_in[0] = 32'h41424344; // "ABCD"
    array_in[1] = 32'h45464748; // "EFGH"
    array_in[2] = 32'h494A4B4C; // "IJKL"
    array_in[3] = 32'h4D4E4F50; // "MNOP"
    array_in[4] = 32'h51525354; // "QRST"
    array_in[5] = 32'h55565758; // "UVWX"
    array_in[6] = 32'h595A3031; // "YZ01"
    array_in[7] = 32'h32333435; // "2345"
    @(posedge clk);
    valid_in = 0;

    // Wait for UART to transmit everything
    repeat (200000) @(posedge clk);

    // Push multiple sequences
    foreach (array_in[i]) array_in[i] = {WIDTH{1'b1}}; // all 1s
    valid_in = 1;
    @(posedge clk);
    valid_in = 0;

    repeat (200000) @(posedge clk);

    $finish;
  end

  // Monitor UART line
//   initial begin
//     $dumpfile("tb_tx.vcd");
//     $dumpvars(0, tb_tx);

//     $display("Time\tTX Busy\tTX Line");
//     forever begin
//       @(posedge clk);
//       $display("%0t\t%b\t%b", $time, busy, tx);
//     end
//   end

endmodule
