module bitonicSort #(
    parameter DEPTH = 8,
    parameter WIDTH = 32,
    parameter bit DIR = 1
)(
    input logic clk,
    input logic rst,
    input logic valid_in,
    input logic [0:WIDTH-1] seq_in [0:DEPTH-1],
    output logic [0:WIDTH-1] seq_out [0:DEPTH-1],
    output logic valid_out
);

    localparam NUM = DEPTH / 2;

    generate
        if (DEPTH == 1) begin
            always_ff @ (posedge clk) begin
                {<<{seq_out}} <= {<<{seq_in}};
                valid_out <= valid_in;
            end
        end
        else begin
            logic [WIDTH-1:0] left_out [0:NUM-1];
            logic [WIDTH-1:0] right_out[0:NUM-1];
            logic [0:WIDTH-1] seq_in_merge [0:DEPTH-1];
            logic [0:WIDTH-1] seq_out_merge [0:DEPTH-1];
            logic valid_out_left, valid_out_right, valid_in_merge, valid_out_merge;
            bitonicSort #(
                .DEPTH(NUM),
                .WIDTH(WIDTH),
                .DIR(1)
            ) sortLeft (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in),
                .seq_in(seq_in[0:NUM-1]),
                .seq_out(left_out),
                .valid_out(valid_out_left)
            );
            bitonicSort #(
                .DEPTH(NUM),
                .WIDTH(WIDTH),
                .DIR(0)
            ) sortRight (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in),
                .seq_in(seq_in[NUM:DEPTH-1]),
                .seq_out(right_out),
                .valid_out(valid_out_right)
            );
            bitonicMerge #(
                .DEPTH(DEPTH),
                .WIDTH(WIDTH),
                .DIR(DIR)
            ) mergeSequences (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in_merge),
                .seq_in(seq_in_merge),
                .seq_out(seq_out_merge),
                .valid_out(valid_out_merge)
            );
            always_ff @ (posedge clk) begin //add rst functionality
                if (valid_out_left && valid_out_right) begin
                    for (int i = 0; i < NUM; i++) begin
                        seq_in_merge[i]     <= left_out[i];
                        seq_in_merge[NUM+i] <= right_out[i];
                    end
                    valid_in_merge <= 1'b1;
                end
                else begin
                    for (int i = 0; i < DEPTH; i++) seq_in_merge[i] <= '0;
                    valid_in_merge <= 1'b0;
                end
            end

            always_ff @ (posedge clk) begin
                if (valid_out_merge) begin
                    {<<{seq_out}} <= {<<{seq_out_merge}};
                    valid_out <= 1'b1;
                end
                else begin
                    for (int i = 0; i < DEPTH; i++) seq_out[i] <= '0;
                    valid_out <= 1'b0;
                end
            end
        end
    endgenerate


endmodule
