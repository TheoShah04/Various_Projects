module stage1 #(
    parameter WIDTH = 32;
    parameter DEPTH = 8;
    parameter BITONIC_SEQUENCE_LENGTH = 2;
)(
    input logic clk,
    input logic rst, 
    input logic [0:WIDTH-1] stage1_in [0:DEPTH-1],
    input logic [0:WIDTH-1] stage1_out [0:DEPTH-1]
)
    localparam NUM = DEPTH / 2;
    localparam CD = BITONIC_SEQUENCE_LENGTH / 2;

    genvar i;
    generate 
        for (i = 0; i < NUM; i++) begin
            compSwap comparePair(
                .A_in(),
                .B_in(),
                .dir(),
                .A_out(),
                .B_out()
            )
        end
    endgenerate

endmodule
