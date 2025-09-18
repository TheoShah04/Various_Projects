module rx_buffer #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter NUM_SEQ = 10
)(
    input logic clk,
    input logic rst,
    input logic valid_in,
    input logic data_end,
    input logic [7:0] byte_in,
    output logic [WIDTH-1:0] array_out [DEPTH-1:0],
    output logic valid_out
);

    typedef logic [WIDTH-1:0] buffer_t [DEPTH];
    buffer_t data_buffer [NUM_SEQ];
    logic buffer_empty;
    logic [$clog2(NUM_SEQ)-1:0] unloading_index; //0-9 

    typedef enum {LOADING, UNLOADING} FSM_state;
    FSM_state currentState, nextState;

    logic [1:0] byte_index; //0-3
    logic [$clog2(DEPTH)-1:0] int_index; //0-7
    logic [$clog2(NUM_SEQ)-1:0] array_index; //0-9


    always_ff @ (posedge clk) begin
        if (rst) begin
            array_out <= '{default: '0};
            valid_out <= 1'b0;
            byte_index <= '0;
            int_index <= '0;
            array_index <= '0;
            currentState <= LOADING;
        end
        else begin
            currentState <= nextState;
            if (nextState == LOADING) begin
                if (!data_end && valid_in) begin
                    if (int_index == DEPTH-1) begin
                        if (array_index == NUM_SEQ-1) begin
                            array_index <= '0;
                        end
                        else begin
                            array_index <= array_index + 1;
                        end
                    end
                    if (byte_index == 2'b11) begin
                        int_index <= int_index + 1;
                    end
                    byte_index <= byte_index + 1;
                    data_buffer[array_index][int_index][8*byte_index+:8] <= byte_in;
                end
            end
            else begin //UNLOADING state
                if (!buffer_empty) begin
                    unloading_index <= unloading_index + 1;
                    valid_out <= 1'b1;
                    array_out <= data_buffer[unloading_index];
                end
                else begin //buffer empty, return to LOADING state
                    valid_out <= 1'b0;
                    array_index <= '0;
                    int_index <= '0;
                    byte_index <= '0;
                    unloading_index <= '0;
                end
            end
        end
    end

    assign buffer_empty = (unloading_index == array_index);

    always_comb begin
        case (currentState)
            LOADING: begin
                if (!data_end) nextState = LOADING;
                else nextState = UNLOADING;
            end
            UNLOADING: begin
                if (!buffer_empty) nextState = UNLOADING;
                else nextState = LOADING;
            end
        endcase
    end

endmodule
