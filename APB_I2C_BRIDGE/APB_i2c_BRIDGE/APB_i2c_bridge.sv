`timescale 1ns/1ns

module apb_i2c_bridge #
(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)
(
    input  logic                 PCLK,
    input  logic                 PRESETn,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic [DATA_WIDTH-1:0] PWDATA,
    output logic [DATA_WIDTH-1:0] PRDATA,
    input  logic                 PWRITE,
    input  logic                 PSEL,
    input  logic                 PENABLE,
    output logic                 PREADY,
    output logic                 PSLVERR,

    inout  wire                  sda,
    output wire                  scl
);

    logic        start_i2c;
    logic [6:0]  i2c_addr;
    logic        i2c_rw;
    logic [7:0]  i2c_data_wr;
    logic [7:0]  i2c_data_rd;
    logic        busy, ack_err;

    typedef enum logic [1:0] {IDLE, START, WAIT} apb_state_t;
    apb_state_t state;

    // ----------------------------
    // APB FSM
    // ----------------------------
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state     <= IDLE;
            PREADY    <= 0;
            PSLVERR   <= 0;
            start_i2c <= 0;
            PRDATA    <= '0;
        end else begin
            PREADY    <= 0;
            start_i2c <= 0;

            case (state)

                IDLE: begin
                    if (PSEL && PENABLE) begin
                        state <= START;
                    end
                end

                START: begin
                    i2c_addr <= PADDR[6:0];

                    if (PWRITE) begin
                        i2c_rw      <= 1'b0;
                        i2c_data_wr <= PWDATA;
                    end else begin
                        i2c_rw <= 1'b1;
                    end

                    start_i2c <= 1'b1;
                    PREADY    <= 1'b1;
                    state     <= WAIT;
                end

                WAIT: begin
                    if (!busy) begin
                        if (!PWRITE)
                            PRDATA <= i2c_data_rd;

                        PREADY <= 1'b1;
                        state  <= IDLE;
                    end
                end

            endcase
        end
    end

    // ----------------------------
    // I2C Master
    // ----------------------------
    i2c_master #(.CLK_DIV(100)) u_i2c_master (
        .clk        (PCLK),
        .rst        (!PRESETn),
        .start      (start_i2c),
        .slave_addr (i2c_addr),
        .rw         (i2c_rw),
        .data_in    (i2c_data_wr),
        .busy       (busy),
        .ack_err    (ack_err),
        .data_out   (i2c_data_rd),
        .sda        (sda),
        .scl        (scl)
    );

endmodule
