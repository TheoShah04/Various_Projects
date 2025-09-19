module tx_buffer #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter NUM_SEQ = 10
)(
    input  logic clk,
    input  logic rst,

    //Upstream logic 
    input  logic valid_in,
    input  logic [WIDTH-1:0] array_in [DEPTH-1:0],
    output logic full,

    //Downstream UART interface
    input  logic tx_busy,
    output logic [7:0] byte_out,
    output logic valid_out
);

    typedef logic [WIDTH-1:0] buffer_t [DEPTH];
    buffer_t data_buffer [NUM_SEQ];

    logic [$clog2(NUM_SEQ)-1:0] wr_ptr; 
    logic [$clog2(NUM_SEQ)-1:0] rd_ptr; 
    logic [$clog2(NUM_SEQ+1)-1:0] count; //counts how many sequences are stored

    logic [$clog2(DEPTH)-1:0] int_index;
    logic [1:0]               byte_index;

    assign full = (count == NUM_SEQ);
    assign empty = (count == 0);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count <= '0;
            int_index <= DEPTH-1;
            byte_index <= '0;
            byte_out <= '0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in && !full) begin //Write valid
                data_buffer[wr_ptr] <= array_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end

            if (!tx_busy && !empty) begin //Read valid
                valid_out <= 1'b1;
                byte_out <= data_buffer[rd_ptr][int_index][8*byte_index +: 8];

                if (byte_index == 2'b11) begin
                    byte_index <= '0;
                    if (int_index == 0) begin //Completed one full read of a sequence
                        int_index <= DEPTH-1;
                        rd_ptr <= rd_ptr + 1;
                        count <= count - 1;
                    end else begin
                        int_index <= int_index - 1;
                    end
                end else begin
                    byte_index <= byte_index + 1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
