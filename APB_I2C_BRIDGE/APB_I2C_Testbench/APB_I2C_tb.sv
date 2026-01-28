`include "apb_i2c_bridge.sv"
`include "i2c_master.sv"
`include "i2c_slave.sv"

`timescale 1ns/1ns

module tb_apb_i2c;

    logic clk = 0, rst = 1;
    logic [7:0]  PADDR, PWDATA, PRDATA;
    logic PWRITE, PSEL, PENABLE, PREADY, PSLVERR;

    wire sda_line;
wire scl;
pullup(sda_line);

    // Instantiate bridge
    apb_i2c_bridge bridge (
        .PCLK(clk), .PRESETn(!rst),
        .PADDR(PADDR), .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PWRITE(PWRITE), .PSEL(PSEL),
        .PENABLE(PENABLE), .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .sda(sda_line), .scl(scl)
    );

    // Slave
    logic [7:0] slave_data;
    i2c_slave #(.SLAVE_ADDR(7'h50)) slave (
        .sda(sda_line), .scl(scl),
        .clk(clk), .rst(rst),
        .data_out(slave_data)
    );

    always #5 clk = ~clk;

    initial begin
      $dumpfile("i2c.vcd");
        $dumpvars();
        $monitor("Time = %0t PADDR=%0d PWDATA=%0d PRDATA=%0d PWRITE=%0d PSEL=%0d PENABLE=%0d PREADY=%0d PSLVERR=%0d sda_line=%b scl=%b",
             $time, PADDR, PWDATA, PRDATA, PWRITE, PSEL, PENABLE, PREADY, PSLVERR, sda_line, scl);
        rst = 1; PSEL = 0; PENABLE = 0; PWRITE = 0;
        #20 rst = 0;

        #10;
        // APB Write
        PADDR   = 8'h50;
        PWDATA  = 8'hA5;
        PWRITE  = 1;
        PSEL    = 1;
        PENABLE = 1;
        #10;
        PSEL    = 0;
        PENABLE = 0;

        #500;
      $display("Slave read = 0x%0h", slave_data);

        #100 $finish;
    end

endmodule
