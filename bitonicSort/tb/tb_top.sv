`timescale 1ns/1ps

module tb_top;

    // Parameters
    localparam int WIDTH = 32;
    localparam int DEPTH = 8;

    // Testbench signals
    logic clk;
    logic rst;
    logic valid_in;
    logic [WIDTH-1:0] unsorted [DEPTH-1:0];
    logic [WIDTH-1:0] sorted   [DEPTH-1:0];
    logic valid_out;

    // DUT instance
    top #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .unsorted(unsorted),
        .sorted(sorted),
        .valid_out(valid_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to apply one vector of inputs
    task automatic apply_input(input logic [WIDTH-1:0] data [DEPTH]);
        begin
            @(posedge clk);
            valid_in <= 1;
            unsorted <= data;
            @(posedge clk);
            valid_in <= 0;
            unsorted <= '{default:'0};
        end
    endtask

    // Reset sequence
    initial begin
        rst = 1;
        valid_in = 0;
        unsorted = '{default:'0};
        repeat (2) @(posedge clk);
        rst = 0;
    end

    // VCD dump setup
    initial begin
        $dumpfile("waveform.vcd");   // VCD output filename
        $dumpvars(0, tb_top);        // dump everything under tb_top (incl. DUT)
    end

    // Test procedure
    initial begin
        logic [WIDTH-1:0] test_vec [DEPTH];
        logic [WIDTH-1:0] expected  [DEPTH];

        // Wait for reset deassertion
        @(negedge rst);

        // Example unsorted input
        test_vec = '{32'd10, 32'd3, 32'd25, 32'd7, 32'd1, 32'd18, 32'd2, 32'd5};

        // Expected sorted ascending
        expected = '{32'd1, 32'd2, 32'd3, 32'd5, 32'd7, 32'd10, 32'd18, 32'd25};

        // Apply input
        apply_input(test_vec);

        // Wait until valid_out goes high
        wait (valid_out);

        // Check output
        if (sorted !== expected) begin
            $error("Test FAILED! Got: %p Expected: %p", sorted, expected);
        end else begin
            $display("Test PASSED! Sorted output: %p", sorted);
        end

        // Finish simulation
        #20 $finish;
    end

endmodule
