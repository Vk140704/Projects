module uart_tx (
    input        clk,
    input        rst,
    input        i_tx_start,
    input  [7:0] i_tx_data,
    input        i_baud_tick,
    output reg   o_busy,
    output reg   o_tx_serial
);

    reg [3:0]  bit_index;
    reg [9:0]  shift_reg;
    reg [1:0]  state;

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            o_busy      <= 0;
            o_tx_serial <= 1;
            bit_index   <= 0;
        end else if (i_baud_tick) begin
            case (state)
                IDLE: begin
                    if (i_tx_start) begin
                        shift_reg   <= {1'b1, i_tx_data, 1'b0};
                        o_busy      <= 1;
                        state       <= START;
                    end
                end
                START: begin
                    o_tx_serial <= shift_reg[0];
                    shift_reg   <= {1'b1, shift_reg[9:1]};
                    state       <= DATA;
                    bit_index   <= 0;
                end
                DATA: begin
                    o_tx_serial <= shift_reg[0];
                    shift_reg   <= {1'b1, shift_reg[9:1]};
                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end
                STOP: begin
                    o_tx_serial <= 1'b1;
                    o_busy      <= 0;
                    state       <= IDLE;
                end
            endcase
        end
    end

endmodule
