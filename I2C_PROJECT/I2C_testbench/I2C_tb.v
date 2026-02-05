`include "i2c_master.v"
`include "i2c_slave.v"
`timescale 1ns/1ns

module tb_i2c;

  reg clk = 0;
  reg rst = 1;
  reg start;
  reg [6:0] addr = 7'h42;
  reg rw = 0;
  reg [7:0] data_in = 8'hA5;

  wire busy, ack_err;
  wire scl;
  wire sda;

  pullup(sda);

  // clock
  always #5 clk = ~clk;

  i2c_master #(.CLK_DIV(20)) master (
    .clk(clk),
    .rst(rst),
    .start(start),
    .addr(addr),
    .rw(rw),
    .data_wr(data_in),
    .busy(busy),
    .ack_err(ack_err),
    .sda(sda),
    .scl(scl)
  );

  i2c_slave #(.SLAVE_ADDR(7'h42)) slave (
    .scl(scl),
    .sda(sda),
    .rst(rst)
  );

  initial begin
    $dumpfile("i2c.vcd");
    $dumpvars;
	 $monitor("Time = %0t start = %d addr = %d rw = %d data_in = %d sda = %b",
         $time, start, addr, rw, data_in, sda);

    start = 0;
    #20 rst = 0;
    #20 start = 1;
    #10 start = 0;

    #1000 $finish;
  end

endmodule
