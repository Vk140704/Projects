`timescale 1ns/1ns

module tb_uart;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;

    // Transmitter inputs
    reg         tx_start = 0;
    reg  [7:0]  tx_data  = 8'h00;

    // DUT outputs
    wire        tx_busy;
    wire        uart_tx;

    // Receiver wires
    wire        rx_serial;
    wire        rx_valid;
    wire [7:0]  rx_data;

    // Loopback TX -> RX
    assign rx_serial = uart_tx;

    // Instantiate DUT
    uart #(.CLKS_PER_BIT(16)) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_tx_start(tx_start),
        .i_tx_data(tx_data),
        .o_tx_busy(tx_busy),
        .o_uart_tx(uart_tx),
        .i_uart_rx(rx_serial),
        .o_rx_valid(rx_valid),
        .o_rx_data(rx_data)
    );

    // 100 MHz clock generator
    always #5 clk = ~clk;

   initial begin
    #20 rst = 0;
    #10 tx_data = 8'hA5;
    tx_start = 1;
    #10 tx_start = 0;

    wait(rx_valid);
    $display("Simulation complete. Received = 0x%0h at time %0t", rx_data, $time);
    
    #100;
    $finish;
end

endmodule
