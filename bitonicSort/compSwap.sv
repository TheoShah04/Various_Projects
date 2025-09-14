module compSwap #(
        parameter WIDTH = 32
    )(
        input logic [0:WIDTH-1] A_in,
        input logic [0:WIDTH-1] B_in,
        input logic dir,
        output logic [0:WIDTH-1] A_out,
        output logic [0:WIDTH-1] B_out
    )

    always_comb begin
        if (dir) begin //B > A
            A_out = (B_in >= A_in) ? A_in : B_in;
            B_out = (B_in >= A_in) ? B_in : A_in;
        end
        else begin //A > B
            A_out = (A_in >= B_in) ? A_in : B_in;
            B_out = (A_in >= B_in) ? B_in : A_in;
        end
    end
    
endmodule
