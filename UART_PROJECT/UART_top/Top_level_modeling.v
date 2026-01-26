module uart #
(
    parameter CLKS_PER_BIT = 108  // Example for 1MHz clock & ~9600 baud
)
(
    input       i_clk,
    input       i_rst,
    // TX Interface
    input       i_tx_start,
    input  [7:0] i_tx_data,
    output      o_tx_busy,
    output      o_uart_tx,
    // RX Interface
    input       i_uart_rx,
    output reg  o_rx_valid,
    output reg [7:0] o_rx_data
);

    wire baud_tick;
    wire tx_busy;
    wire rx_ready;
    wire [7:0] rx_data;

    // Baud rate generator
    uart_baud #(.CLKS_PER_BIT(CLKS_PER_BIT)) baudgen (
        .clk(i_clk),
        .rst(i_rst),
        .tick(baud_tick)
    );

    // Transmitter
    uart_tx tx (
        .clk(i_clk),
        .rst(i_rst),
        .i_tx_start(i_tx_start),
        .i_tx_data(i_tx_data),
        .i_baud_tick(baud_tick),
        .o_busy(tx_busy),
        .o_tx_serial(o_uart_tx)
    );
    assign o_tx_busy = tx_busy;

    // Receiver
    uart_rx rx (
        .clk(i_clk),
        .rst(i_rst),
        .i_rx_serial(i_uart_rx),
        .i_baud_tick(baud_tick),
        .o_data(rx_data),
        .o_valid(rx_ready)
    );

    always @(posedge i_clk) begin
        if (i_rst) begin
            o_rx_valid <= 0;
            o_rx_data  <= 8'b0;
        end else begin
            o_rx_valid <= rx_ready;
            o_rx_data  <= rx_data;
        end
    end

endmodule
