module compSwap #(
        parameter WIDTH = 32,
        parameter DIR = 1
    )(
        input logic clk,
        input logic rst,
        input logic [0:WIDTH-1] A_in,
        input logic [0:WIDTH-1] B_in,
        output logic [0:WIDTH-1] A_out,
        output logic [0:WIDTH-1] B_out
    );

    always_ff @ (posedge clk) begin
        if (!rst) begin
            if (DIR) begin //B > A
                A_out <= (B_in >= A_in) ? A_in : B_in;
                B_out <= (B_in >= A_in) ? B_in : A_in;
            end
            else begin //A > B
                A_out <= (A_in >= B_in) ? A_in : B_in;
                B_out <= (A_in >= B_in) ? B_in : A_in;
            end
        end
        else begin
            A_out = '0;
            B_out = '0;
        end
    end
    
endmodule
