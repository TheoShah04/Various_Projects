module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  logic clk,
    input  logic rst,
    input  logic rx,        // UART line from laptop (FTDI TX)
    output logic [7:0] data,
    output logic valid_out,      // High for 1 cycle when byte received
    output logic data_end
);

    localparam integer BAUD_CNT = CLK_FREQ / BAUD; //number of clock cycles per bit
    localparam integer HALF_BAUD = BAUD_CNT / 2; //half cycle so that we sample rx line in the middle of data transmissions
    int unsigned idle_cnt;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [$clog2(BAUD_CNT)-1:0] baud_cnt; //How many bits it takes to count the number of clock cycles between each sample
    logic [2:0] bit_idx; //0-7, 8 bits of data
    logic [7:0] shift_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            baud_cnt <= 0;
            bit_idx <= 0;
            valid_out <= 0;
            idle_cnt <= 0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                IDLE:   if (!rx) begin // start bit detected
                            state <= START;
                            baud_cnt <= HALF_BAUD;
                            idle_cnt <= 0;
                        end
                        else begin
                            idle_cnt <= idle_cnt + 1;
                        end
                START:  if (baud_cnt == 0) begin
                            state <= DATA;
                            baud_cnt <= BAUD_CNT-1;
                            bit_idx <= 0;
                        end else baud_cnt <= baud_cnt - 1;
                DATA:   if (baud_cnt == 0) begin //sample
                            shift_reg[bit_idx] <= rx;
                            baud_cnt <= BAUD_CNT-1;
                            if (bit_idx == 7) begin //byte received
                                state <= STOP;
                            end
                            else begin //keep adding to byte buffer
                                bit_idx <= bit_idx + 1;
                            end
                        end else begin //wait to sample
                            baud_cnt <= baud_cnt - 1;
                        end
                STOP:   if (baud_cnt == 0) begin
                            data <= shift_reg;
                            valid_out <= 1'b1;
                            state <= IDLE;
                        end else begin
                            baud_cnt <= baud_cnt - 1;
                        end
            endcase
        end
    end

    assign data_end = (idle_cnt == 20_000); //Enough idle time to assume end of transmission (20,000 clk cycles)

endmodule
