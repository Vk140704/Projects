`timescale 1ns/1ps

module tb_csr_dma;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rstn;

    reg write_operation, read_operation;
    reg [7:0] awaddr, araddr;
    reg [31:0] csr_wdata_in;
    reg csr_start_write, csr_start_read;

    wire csr_done_write, csr_done_read;
    wire [31:0] csr_rdata_out;

    reg [31:0] stream_in;
    wire [31:0] stream_out;
    wire done_write, read_stream_done;

    reg [31:0] rdata;

    // Clock
    always #(CLK_PERIOD/2) clk = ~clk;

    // DUT
    DMA_Module #(.BURST_SIZE(4)) dut (
        .clk(clk),
        .rstn(rstn),
        .write_operation(write_operation),
        .read_operation(read_operation),
        .awaddr(awaddr),
        .araddr(araddr),
        .csr_wdata_in(csr_wdata_in),
        .csr_start_write(csr_start_write),
        .csr_start_read(csr_start_read),
        .csr_done_write(csr_done_write),
        .csr_done_read(csr_done_read),
        .csr_rdata_out(csr_rdata_out),
        .stream_in(stream_in),
        .stream_out(stream_out),
        .done_write(done_write),
        .read_stream_done(read_stream_done)
    );

    // Tasks
    task csr_write(input [7:0] addr, input [31:0] data);
    begin
        awaddr = addr;
        csr_wdata_in = data;
        csr_start_write = 1;
        @(posedge clk);
        csr_start_write = 0;
        @(posedge clk);
    end
    endtask

    task csr_read(input [7:0] addr);
    begin
        araddr = addr;
        csr_start_read = 1;
        @(posedge clk);
        csr_start_read = 0;
        @(posedge clk);
        $display("READ [0x%0h] = %h", addr, csr_rdata_out);
    end
    endtask

    // Monitor (VERY IMPORTANT FOR DEBUG)
    initial begin
        $monitor("T=%0t | WOP=%b ROP=%b | AW=%h AR=%h | WDATA=%h | RDATA=%h | DIN=%h DOUT=%h | DW=%b DR=%b",
                 $time, write_operation, read_operation,
                 awaddr, araddr, csr_wdata_in, csr_rdata_out,
                 stream_in, stream_out, done_write, read_stream_done);
    end

    // Test
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_csr_dma);

        clk = 0;
        rstn = 0;
        write_operation = 0;
        read_operation = 0;
        csr_start_write = 0;
        csr_start_read = 0;
        stream_in = 0;

        #20 rstn = 1;

        // CSR TEST
        csr_write(8'h00, 32'h00000021);
        csr_write(8'h08, 32'h0000CAFE);
        csr_write(8'h10, 32'hABCDEFAB);

        csr_read(8'h00);
        csr_read(8'h08);
        csr_read(8'h10);

        // STREAM WRITE
        write_operation = 1;
        @(posedge clk) stream_in = 32'hAAAA_BBBB;
        @(posedge clk) stream_in = 32'hCCCC_DDDD;
        @(posedge clk) stream_in = 32'h1234_5678;
        @(posedge clk) stream_in = 32'hDEAD_BEEF;
        write_operation = 0;

        wait(done_write);
        $display("STREAM WRITE DONE");

        // STREAM READ
        read_operation = 1;
        wait(read_stream_done);
        read_operation = 0;

        $display("STREAM READ DONE");

        #50 $finish;
    end

endmodule
