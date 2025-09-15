`timescale 1ns/1ps

module tb_top_multiple;

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
    // initial begin
    //     $dumpfile("waveform.vcd");
    //     $dumpvars(0, tb_top);
    // end

    // Test procedure
    initial begin
        // Define a set of test vectors and their expected outputs
        logic [WIDTH-1:0] test_vecs   [3][DEPTH];  // 3 test cases
        logic [WIDTH-1:0] expected    [3][DEPTH];
        automatic int num_tests = 3;

        // Test 1
        test_vecs[0] = '{32'd10, 32'd3, 32'd25, 32'd7, 32'd1, 32'd18, 32'd2, 32'd5};
        expected [0] = '{32'd1, 32'd2, 32'd3, 32'd5, 32'd7, 32'd10, 32'd18, 32'd25};

        // Test 2
        test_vecs[1] = '{32'd8, 32'd6, 32'd4, 32'd2, 32'd1, 32'd3, 32'd5, 32'd7};
        expected [1] = '{32'd1, 32'd2, 32'd3, 32'd4, 32'd5, 32'd6, 32'd7, 32'd8};

        // Test 3
        test_vecs[2] = '{32'd100, 32'd50, 32'd75, 32'd25, 32'd10, 32'd5, 32'd1, 32'd0};
        expected [2] = '{32'd0, 32'd1, 32'd5, 32'd10, 32'd25, 32'd50, 32'd75, 32'd100};

        // Wait for reset deassertion
        @(negedge rst);

        // Loop through all tests
        for (int t = 0; t < num_tests; t++) begin
            apply_input(test_vecs[t]);

            // Wait until DUT produces valid output
            wait (valid_out);

            // Check result
            if (sorted !== expected[t]) begin
                $error("Test %0d FAILED! Got: %p Expected: %p", t, sorted, expected[t]);
            end else begin
                $display("Test %0d PASSED! Sorted output: %p", t, sorted);
            end
        end

        // Finish simulation
        #20 $finish;
    end

endmodule
