`timescale 1ns/1ns

module i2c_slave #
(
    parameter SLAVE_ADDR = 7'h50
)
(
    inout  wire sda,     // I2C data line (open drain)
    input  wire scl,     // I2C clock
    input  logic clk,    // system clock for sampling
    input  logic rst,    // reset
    output logic [7:0] data_out  // received data
);

    // control for open-drain SDA
    logic sda_drive_en;
    assign sda = sda_drive_en ? 1'b0 : 1'bz;

    typedef enum logic [2:0] {
        WAIT_START,
        ADDR,
        ACK_ADDR,
        DATA,
        ACK_DATA
    } state_t;

    state_t state;
    logic [3:0] bit_cnt;
    logic [7:0] shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= WAIT_START;
            data_out     <= 8'b0;
            sda_drive_en <= 1'b0;
            bit_cnt      <= 4'b0;
        end else begin
            case (state)
                WAIT_START: begin
                    sda_drive_en <= 1'b0;
                    if (~sda && scl) begin
                        bit_cnt <= 4'd7;
                        state   <= ADDR;
                    end
                end

                ADDR: begin
                    // sample address bits on rising SCL
                    if (scl) begin
                        shift[bit_cnt] <= sda;
                        if (bit_cnt == 0)
                            state <= ACK_ADDR;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                ACK_ADDR: begin
                    // if address matches, pull sda low for ACK
                    if (shift[7:1] == SLAVE_ADDR) begin
                        sda_drive_en <= 1'b1;
                        bit_cnt      <= 4'd7;
                        state        <= DATA;
                    end else begin
                        sda_drive_en <= 1'b0;
                        state        <= WAIT_START;
                    end
                end

                DATA: begin
                    if (scl) begin
                        shift[bit_cnt] <= sda;
                        if (bit_cnt == 0)
                            state <= ACK_DATA;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                ACK_DATA: begin
                    // latch received byte and ACK it
                    data_out     <= shift;
                    sda_drive_en <= 1'b1; // pull low for ack
                    state        <= WAIT_START;
                end

            endcase
        end
    end

endmodule
