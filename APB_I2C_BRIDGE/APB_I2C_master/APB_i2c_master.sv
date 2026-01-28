`timescale 1ns/1ns

module i2c_master #(
    parameter CLK_DIV = 50
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [6:0]  slave_addr,
    input  logic        rw,
    input  logic [7:0]  data_in,
    output logic        busy,
    output logic        ack_err,
    output logic [7:0]  data_out,

    inout  wire         sda,
    output logic        scl
);

    // ----------------------------
    // Open-drain SDA
    // ----------------------------
    logic sda_drive_low;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    // ----------------------------
    // SCL clock generator
    // ----------------------------
    logic [$clog2(CLK_DIV):0] clk_cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            scl     <= 1'b1;
        end else if (clk_cnt == CLK_DIV-1) begin
            clk_cnt <= 0;
            scl     <= ~scl;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end

    // ----------------------------
    // FSM states
    // ----------------------------
    typedef enum logic [3:0] {
        IDLE,
        START,
        SEND_ADDR,
        ADDR_ACK,
        SEND_DATA,
        DATA_ACK,
        READ_DATA,
        READ_ACK,
        STOP
    } state_t;

    state_t state;

    logic [3:0] bit_cnt;
    logic [7:0] shift_reg;

    // ----------------------------
    // I2C FSM
    // ----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            busy           <= 0;
            ack_err        <= 0;
            sda_drive_low  <= 0;
            bit_cnt        <= 0;
            shift_reg      <= 0;
            data_out       <= 0;
        end else begin

            case (state)

                // ---------------- IDLE ----------------
                IDLE: begin
                    busy          <= 0;
                    ack_err       <= 0;
                    sda_drive_low <= 0;
                    if (start) begin
                        busy  <= 1;
                        state <= START;
                    end
                end

                // ---------------- START ----------------
                START: begin
                    if (scl) begin
                        sda_drive_low <= 1;   // SDA ↓ while SCL ↑
                        shift_reg     <= {slave_addr, rw};
                        bit_cnt       <= 7;
                        state         <= SEND_ADDR;
                    end
                end

                // ---------------- SEND ADDRESS ----------------
                SEND_ADDR: begin
                    if (!scl) begin
                        sda_drive_low <= ~shift_reg[bit_cnt];
                    end
                    if (scl) begin
                        if (bit_cnt == 0)
                            state <= ADDR_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // ---------------- ADDRESS ACK ----------------
                ADDR_ACK: begin
                    sda_drive_low <= 0; // release SDA
                    if (scl) begin
                        if (!sda) begin
                            if (rw == 0) begin
                                shift_reg <= data_in;
                                bit_cnt   <= 7;
                                state     <= SEND_DATA;
                            end else begin
                                bit_cnt   <= 7;
                                state     <= READ_DATA;
                            end
                        end else begin
                            ack_err <= 1;
                            state   <= STOP;
                        end
                    end
                end

                // ---------------- SEND DATA ----------------
                SEND_DATA: begin
                    if (!scl) begin
                        sda_drive_low <= ~shift_reg[bit_cnt];
                    end
                    if (scl) begin
                        if (bit_cnt == 0)
                            state <= DATA_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // ---------------- DATA ACK ----------------
                DATA_ACK: begin
                    sda_drive_low <= 0;
                    if (scl) begin
                        if (!sda)
                            state <= STOP;
                        else begin
                            ack_err <= 1;
                            state   <= STOP;
                        end
                    end
                end

                // ---------------- READ DATA ----------------
                READ_DATA: begin
                    sda_drive_low <= 0;
                    if (scl) begin
                        data_out[bit_cnt] <= sda;
                        if (bit_cnt == 0)
                            state <= READ_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // ---------------- READ ACK ----------------
                READ_ACK: begin
                    if (!scl)
                        sda_drive_low <= 0; // NACK
                    if (scl)
                        state <= STOP;
                end

                // ---------------- STOP ----------------
                STOP: begin
                    if (scl) begin
                        sda_drive_low <= 0; // SDA ↑ while SCL ↑
                        busy          <= 0;
                        state         <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
