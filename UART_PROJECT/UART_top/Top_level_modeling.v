`include "uart_baud.v"
`include "uart_tx.v"
`include "uart_rx.v"

module uart #
(
    parameter CLKS_PER_BIT = 108
)
(
    input        i_clk,
    input        i_rst,
    input        i_tx_start,
    input  [7:0] i_tx_data,
    output       o_tx_busy,
    output       o_uart_tx,
    input        i_uart_rx,
    output reg   o_rx_valid,
    output reg [7:0] o_rx_data
);

    wire baud_tick, tx_busy, rx_ready;
    wire [7:0] rx_data;

    uart_baud #(.CLKS_PER_BIT(CLKS_PER_BIT)) baudgen (
        .clk(i_clk), .rst(i_rst), .tick(baud_tick)
    );

    uart_tx tx (
        .clk(i_clk), .rst(i_rst),
        .i_tx_start(i_tx_start),
        .i_tx_data(i_tx_data),
        .i_baud_tick(baud_tick),
        .o_busy(tx_busy),
        .o_tx_serial(o_uart_tx)
    );
    assign o_tx_busy = tx_busy;

    uart_rx rx (
        .clk(i_clk), .rst(i_rst),
        .i_rx_serial(i_uart_rx),
        .i_baud_tick(baud_tick),
        .o_data(rx_data),
        .o_valid(rx_ready)
    );

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_rx_valid <= 0;
            o_rx_data  <= 0;
        end else begin
            o_rx_valid <= rx_ready;
            o_rx_data  <= rx_data;
        end
    end

endmodule
