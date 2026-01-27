`timescale 1ns/1ns

module i2c_slave #
(
    parameter SLAVE_ADDR = 7'h42
)
(
    inout       sda,
    input       scl,
    input       clk,
    input       rst,
    output reg [7:0] data_out,
    output reg       got_data
);

    reg sda_oe;
    reg sda_out;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    localparam WAIT_START = 3'd0,
               ADDR       = 3'd1,
               ACK_ADDR   = 3'd2,
               DATA       = 3'd3,
               ACK_DATA   = 3'd4,
               DONE       = 3'd5;

    reg [2:0] state;
    reg [3:0] bit_idx;
    reg [7:0] shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= WAIT_START;
            got_data <= 0;
            sda_oe   <= 0;
        end else begin
            case (state)
                WAIT_START: if (~sda && scl) begin
                    bit_idx <= 7;
                    state   <= ADDR;
                end

                ADDR: if (scl) begin
                    shift[bit_idx] <= sda;
                    if (bit_idx == 0) state <= ACK_ADDR;
                    else bit_idx <= bit_idx - 1;
                end

                ACK_ADDR: begin
                    if (shift[7:1] == SLAVE_ADDR) begin
                        sda_oe  <= 1; // ACK
                        sda_out <= 0;
                        bit_idx <= 7;
                        state   <= DATA;
                    end else begin
                        state <= WAIT_START;
                    end
                end

                DATA: if (scl) begin
                    shift[bit_idx] <= sda;
                    if (bit_idx == 0) state <= ACK_DATA;
                    else bit_idx <= bit_idx - 1;
                end

                ACK_DATA: begin
                    sda_oe  <= 1;
                    sda_out <= 0; // ACK data
                    data_out <= shift;
                    got_data <= 1;
                    state <= DONE;
                end

                DONE: begin
                    sda_oe <= 0;
                    state  <= WAIT_START;
                end
            endcase
        end
    end

endmodule
