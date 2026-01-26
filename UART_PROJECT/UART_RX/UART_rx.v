
////////////////////////////////////////////////////////////////////////////////
// UART Receiver
////////////////////////////////////////////////////////////////////////////////
module uart_rx (
    input        clk,
    input        rst,
    input        i_rx_serial,
    input        i_baud_tick,
    output reg [7:0] o_data,
    output reg       o_valid
);

    reg [3:0]  bit_index;
    reg [7:0]  shift_reg;
    reg [1:0]  state;
    reg [3:0]  sample_count;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam DONE  = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            o_valid <= 0;
        end else if (i_baud_tick) begin
            o_valid <= 0;
            case (state)
                IDLE: begin
                    if (~i_rx_serial) begin
                        state <= START;
                        sample_count <= 1;
                    end
                end
                START: if (sample_count == 1) begin
                        state <= DATA;
                        bit_index <= 0;
                    end else sample_count <= sample_count + 1;
                DATA: begin
                    shift_reg[bit_index] <= i_rx_serial;
                    if (bit_index == 7) state <= DONE;
                    else bit_index <= bit_index + 1;
                end
                DONE: begin
                    o_data  <= shift_reg;
                    o_valid <= 1;
                    state   <= IDLE;
                end
            endcase
        end
    end

endmodule


