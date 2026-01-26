`timescale 1ns/1ns

module uart_baud #
(
    parameter CLKS_PER_BIT = 108
)
(
    input        clk,
    input        rst,
    output reg   tick
);
    reg [$clog2(CLKS_PER_BIT)-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick    <= 0;
        end else begin
            if (counter == CLKS_PER_BIT-1) begin
                counter <= 0;
                tick    <= 1;
            end else begin
                counter <= counter + 1;
                tick    <= 0;
            end
        end
    end
endmodule
