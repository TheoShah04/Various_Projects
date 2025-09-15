module top #(
    parameter WIDTH = 32,
    parameter DEPTH = 8
    )
    (
        input logic clk,
        input logic rst,
        input logic valid_in,
        input logic [0:WIDTH-1] unsorted [0:DEPTH-1],
        output logic [0:WIDTH-1] sorted [0:DEPTH-1],
        output logic valid_out
    );

    logic [WIDTH-1:0] seq_out [DEPTH-1:0];
    logic seq_valid_out;
    bitonicSort #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH),
        .DIR(1) //sort all elements in ascending order
    ) topModule (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .seq_in(unsorted),
        .seq_out(seq_out),
        .valid_out(seq_valid_out)
    );


    always_ff @ (posedge clk) begin
        if (rst) begin
            valid_out <= '0;
            sorted <= '{default: '0};
        end
        else begin
            if (seq_valid_out) begin
                sorted <= seq_out;
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= '0;
                sorted <= '{default: '0};
            end
        end
    end

endmodule
