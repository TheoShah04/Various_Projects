module bitonicSort #(
    parameter DEPTH = 8,
    parameter WIDTH = 32
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
            assign {<<{seq_out}} = {<<{seq_in}};
            assign valid_out = 1'b1;
        end
        else begin
            logic [WIDTH-1:0] left_out [0:NUM-1];
            logic [WIDTH-1:0] right_out[0:NUM-1];
            logic valid_out_left, valid_out_right;
            bitonicSort #(
                .DEPTH(NUM),
                .WIDTH(WIDTH)
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
                .WIDTH(WIDTH)
            ) sortRight (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in),
                .seq_in(seq_in[NUM:DEPTH-1]),
                .seq_out(right_out),
                .valid_out(valid_out_right)
            );
            always_comb begin
                if (valid_out_left && valid_out_right) begin
                    for (int i = 0; i < NUM; i++) begin
                        //Replace with compare-and-swap network
                        seq_out[i]     = left_out[i];
                        seq_out[NUM+i] = right_out[i];
                    end
                    valid_out = 1'b1;
                end
                else begin
                    for (int i = 0; i < DEPTH; i++) seq_out[i] = '0;
                    valid_out = 1'b0;
                end
            end
        end
    endgenerate

endmodule
