module bitonicMerge #(
    parameter DEPTH = 8,
    parameter WIDTH = 32,
    parameter bit DIR = 1
)(
    input clk,
    input rst,
    input logic valid_in,
    input logic [WIDTH-1:0] seq_in [DEPTH-1:0],
    output logic [WIDTH-1:0] seq_out [DEPTH-1:0],
    output logic valid_out
);

    genvar i;
    generate 
        if (DEPTH > 1) begin
            localparam NUM = DEPTH / 2;
            logic [WIDTH-1:0] left_out [NUM-1:0];
            logic [WIDTH-1:0] right_out [NUM-1:0];
            logic valid_in_comp, valid_out_left, valid_out_right, valid_in_merge;
            logic [WIDTH-1:0] seq_inter [DEPTH-1:0];
            logic [WIDTH-1:0] comp_out [DEPTH-1:0];

            for (i = 0; i < NUM; i++) begin
                compSwap #( // 1 clk latency
                    .WIDTH(WIDTH),
                    .DIR(DIR)
                ) compare (
                    .clk(clk),
                    .rst(rst),
                    .A_in(seq_in[i]),
                    .B_in(seq_in[i+NUM]),
                    .A_out(comp_out[i]),
                    .B_out(comp_out[i+NUM])
                );
            end


            bitonicMerge #(
                .DEPTH(NUM),
                .WIDTH(WIDTH),
                .DIR(DIR)
            ) leftMerge (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in_merge),
                .seq_in(seq_inter[NUM-1:0]), 
                .seq_out(left_out),
                .valid_out(valid_out_left)
            );


            bitonicMerge #(
                .DEPTH(NUM),
                .WIDTH(WIDTH),
                .DIR(DIR)
            ) rightMerge (
                .clk(clk),
                .rst(rst),
                .valid_in(valid_in_merge),
                .seq_in(seq_inter[DEPTH-1:NUM]),
                .seq_out(right_out),
                .valid_out(valid_out_right)
            );

            always_ff @ (posedge clk) begin
                valid_in_comp <= valid_in;
                if (valid_in_comp) begin
                    for (int j = 0; j < DEPTH; j++) begin
                        seq_inter[j] <= comp_out[j];
                    end                
                end
                else begin
                    seq_inter <= '{default: '0};
                end
                valid_in_merge <= valid_in_comp;
            end

            always_ff @ (posedge clk) begin
                if (valid_out_right && valid_out_left) begin
                    for (int i = 0; i < NUM; i++) begin
                        seq_out[i] <= left_out[i];
                        seq_out[NUM+i] <= right_out[i];
                    end
                    valid_out <= 1'b1;
                end
                else begin
                    seq_out <= '{default: '0};
                    valid_out <= 1'b0;
                end
            end
        end
        else begin
            always_ff @ (posedge clk) begin
                for (int j = 0; j < DEPTH; j++) begin
                        seq_out[j] <= seq_in[j];
                end  
                valid_out <= valid_in;
            end
        end
    endgenerate

endmodule
