module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  logic clk,
    input  logic rst,
    input  logic [7:0] data,
    input  logic start,   // pulse high to send data
    output logic tx,      // UART line to laptop (FTDI RX)
    output logic busy
);

    localparam integer BAUD_CNT = CLK_FREQ / BAUD;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [$clog2(BAUD_CNT)-1:0] baud_cnt;
    logic [2:0] bit_idx;
    logic [7:0] shift_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1;
            busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start) begin
                        shift_reg <= data;
                        state <= START;
                        baud_cnt <= BAUD_CNT-1;
                        tx <= 0; // start bit
                        busy <= 1;
                    end
                end
                START, DATA, STOP: begin
                    if (baud_cnt == 0) begin
                        case (state)
                            START: begin
                                state <= DATA;
                                bit_idx <= 0;
                                tx <= shift_reg[0];
                                shift_reg <= shift_reg >> 1;
                            end
                            DATA: begin
                                if (bit_idx == 7) begin
                                    state <= STOP;
                                    tx <= 1; // stop bit
                                end else begin
                                    bit_idx <= bit_idx + 1;
                                    tx <= shift_reg[0];
                                    shift_reg <= shift_reg >> 1;
                                end
                            end
                            STOP: state <= IDLE;
                        endcase
                        baud_cnt <= BAUD_CNT-1;
                    end else baud_cnt <= baud_cnt - 1;
                end
            endcase
        end
    end
endmodule
