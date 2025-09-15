`timescale 1ns/1ps

module tb_top_multiple;

    // Parameters
    localparam int WIDTH = 32;
    localparam int DEPTH = 8;

    // Testbench signals
    logic clk;
    logic rst;
    logic valid_in;
    logic signed [WIDTH-1:0] unsorted [DEPTH-1:0];
    logic signed [WIDTH-1:0] sorted   [DEPTH-1:0];
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

    // === Input/Output scheduling ===
    typedef logic signed [WIDTH-1:0] vec_t [DEPTH];
    vec_t test_vecs[$];      // dynamic array for test inputs
    vec_t expected_q[$];     // queue of expected outputs

    function vec_t sort_array(vec_t arr);
        vec_t tmp;
        tmp = arr;
        // Simple bubble sort in SV for expected output
        for (int i = 0; i < DEPTH-1; i++) begin
            for (int j = 0; j < DEPTH-1-i; j++) begin
                if (tmp[j] > tmp[j+1]) begin
                    logic signed [WIDTH-1:0] t;
                    t = tmp[j];
                    tmp[j] = tmp[j+1];
                    tmp[j+1] = t;
                end
            end
        end
        return tmp;
    endfunction

    initial begin
        vec_t v;

        // Edge case 1: all zeros
        v = '{0,0,0,0,0,0,0,0};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Edge case 2: all same positive numbers
        v = '{7,7,7,7,7,7,7,7};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Edge case 3: all same negative numbers
        v = '{-5,-5,-5,-5,-5,-5,-5,-5};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Edge case 4: mixed negative and positive
        v = '{-10,5,0,-3,2,7,-1,4};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Edge case 5: min/max 32-bit signed values
        v = '{-2147483648,2147483647,0,-1,1,123,-123,0};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Edge case 6: random mix in range
        v = '{100,-100,0,2147483647,-2147483648,50,-50,0};
        test_vecs.push_back(v);
        expected_q.push_back(sort_array(v));

        // Wait reset deassertion
        @(negedge rst);

        // === Drive inputs back-to-back with no gaps ===
        foreach (test_vecs[i]) begin
            @(posedge clk);
            valid_in <= 1;
            unsorted <= test_vecs[i];
        end

        // Deassert after last input
        @(posedge clk);
        valid_in <= 0;
        unsorted <= '{default:'0};
    end

    // === Monitor outputs and check ===
    always_ff @(posedge clk) begin
        if (valid_out) begin
            if (expected_q.size() == 0) begin
                $error("Unexpected valid_out with no expected results!");
            end else begin
                vec_t exp = expected_q.pop_front();
                if (sorted !== exp) begin
                    $error("Mismatch! Got %p Expected %p", sorted, exp);
                end else begin
                    $display("PASS at %0t: %p", $time, sorted);
                end
            end
        end
    end

    // End simulation once all outputs observed
    initial begin
        wait (expected_q.size() == 0);
        #50 $finish;
    end

endmodule
