`include "i2c_master.v"
`include "i2c_slave.v"

`timescale 1ns/1ns

module tb_i2c;

    reg clk = 0, rst = 1;
    reg start;
    reg [6:0] addr = 7'h42;
    reg rw = 0;
    reg [7:0] data_in = 8'hA5;
    wire busy, ack_err;
    wire scl;
    wire sda_line;

    // Model pull-ups
    pullup(sda_line);

    // Instantiate Master
    i2c_master #(.CLK_DIV(20)) master (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(addr),
        .rw(rw),
        .data_wr(data_in),
        .busy(busy),
        .ack_err(ack_err),
        .sda(sda_line),
        .scl(scl)
    );

    // Instantiate Slave
    i2c_slave #(.SLAVE_ADDR(7'h42)) slave (
        .sda(sda_line),
        .scl(scl),
        .clk(clk),
        .rst(rst),
        .data_out(),
        .got_data()
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
       $dumpfile("i2c.vcd");
      $dumpvars();
     $monitor("Time = %0t start = %d addr = %d rw = %d data_in = %d sda = %b",
         $time, start, addr, rw, data_in, sda_line);

        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;

        #200 $display("Simulation Done: busy=%b ack_err=%b", busy, ack_err);

        #500 $finish;
    end

endmodule
