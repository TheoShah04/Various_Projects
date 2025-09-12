module stage1 #(
    parameter WIDTH = 32;
    parameter DEPTH = 8;
)(
    input logic clk,
    input logic rst, 
    input logic stage1_in,
    input logic stage1_out
)

    //stage 1.1
    always_ff @ (posedge clk) begin
        if (rst) begin
            stage1_out <= '{default:'0};
        end
        else begin
            
        end
    end

    genvar i;
    generate 
        for()
    endgenerate


endmodule
