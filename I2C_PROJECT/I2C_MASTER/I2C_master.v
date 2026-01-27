`timescale 1ns/1ns

module i2c_master #
(
    parameter CLK_DIV = 50  // Divider for SCL frequency (adjust as needed)
)
(
    input       clk,
    input       rst,
    input       start,
    input [6:0] slave_addr,
    input       rw,        // 0 = write, 1 = read (read not implemented here)
    input [7:0] data_wr,
    output reg busy,
    output reg ack_err,
    inout       sda,
    output reg  scl
);

    // Tri-state control for SDA: 0 => pull low, z => release
    reg sda_oe;
    reg sda_out;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    // Clock divider for SCL
    reg [15:0] clk_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            scl     <= 1;
        end else if (clk_cnt == CLK_DIV) begin
            clk_cnt <= 0;
            scl     <= ~scl;
        end else clk_cnt <= clk_cnt + 1;
    end

    // FSM states
    localparam IDLE      = 4'd0,
               START1    = 4'd1,
               START2    = 4'd2,
               SEND_ADDR = 4'd3,
               ADDR_ACK  = 4'd4,
               SEND_DATA = 4'd5,
               DATA_ACK  = 4'd6,
               STOP1     = 4'd7,
               STOP2     = 4'd8,
               DONE      = 4'd9;

    reg [3:0] state;
    reg [3:0] bit_idx;
    reg [7:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            busy     <= 0;
            ack_err  <= 0;
            sda_oe   <= 0;
            sda_out  <= 1;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy  <= 1;
                        state <= START1;
                    end
                end

                START1: begin
                    // SDA low while SCL high = START
                    sda_oe  <= 1; 
                    sda_out <= 0; 
                    state   <= START2;
                end

                START2: begin
                    // Prepare to send address+R/W
                    shift_reg <= {slave_addr, rw};
                    bit_idx   <= 7;
                    state     <= SEND_ADDR;
                end

                SEND_ADDR: if (scl) begin
                    sda_oe  <= 1;
                    sda_out <= shift_reg[bit_idx];
                    if (bit_idx == 0) state <= ADDR_ACK;
                    else bit_idx <= bit_idx - 1;
                end

                ADDR_ACK: if (~scl) begin
                    sda_oe <= 0; // release SDA to allow ACK from slave
                    if (sda) ack_err <= 1;
                    else begin
                        shift_reg <= data_wr;
                        bit_idx   <= 7;
                        state     <= SEND_DATA;
                    end
                end

                SEND_DATA: if (scl) begin
                    sda_oe  <= 1;
                    sda_out <= shift_reg[bit_idx];
                    if (bit_idx == 0) state <= DATA_ACK;
                    else bit_idx <= bit_idx - 1;
                end

                DATA_ACK: if (~scl) begin
                    sda_oe <= 0;
                    if (sda) ack_err <= 1;
                    state <= STOP1;
                end

                STOP1: begin
                    // SDA low while SCL low
                    sda_oe  <= 1;
                    sda_out <= 0;
                    state   <= STOP2;
                end

                STOP2: if (~scl) begin
                    // STOP: release SDA while SCL high
                    sda_oe  <= 0;
                    state   <= DONE;
                end

                DONE: begin
                    busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
