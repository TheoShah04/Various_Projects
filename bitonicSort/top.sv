module top #(
    parameter WIDTH = 32;
    parameter DEPTH = 8;
    )
    (
        input logic clk,
        input logic rst,
        input logic [0:WIDTH-1] unsorted [0:DEPTH-1],
        output logic [0:WIDTH-1] sorted [0:DEPTH-1]
    )

    logic [0:WIDTH-1] stage1_out [0:DEPTH-1];
    stage1 stage1Module (
        .clk(clk),
        .rst(rst),
        .stage1_in(unsorted),
        .stage1_out(stage1_out)
    );

    logic [0:WIDTH-1] stage2_in [0:DEPTH-1];
    logic [0:WIDTH-1] stage2_out [0:DEPTH-1];
    stage2 stage2Module (
        .clk(clk),
        .rst(rst),
        .stage2_in(stage2_in),
        .stage2_out(stage2_out)
    );
    
    logic [0:WIDTH-1] stage3_in [0:DEPTH-1];
    logic [0:WIDTH-1] stage3_out [0:DEPTH-1];
    stage3 stage3Module (
        .clk(clk),
        .rst(rst),
        .stage3_in(stage3_in),
        .stage3_out(stage3_out)
    );

    always_ff @ (posedge clk) begin
        if (rst) begin
            stage2_in <= '{default: '0};
            stage3_in <= '{default: '0};
            sorted <= '{default: '0};
        end
        else begin
            stage2_in <= stage1_out;
            stage3_in <= stage2_out;
            sorted <= stage3_out;
        end
    end

 


endmodule
