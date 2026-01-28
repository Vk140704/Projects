`timescale 1ns/1ps

module DMA_Module #(
    parameter BURST_SIZE = 4   // MUST match TB stream count
)(
    input  wire        clk,
    input  wire        rstn,

    // Control
    input  wire        write_operation,
    input  wire        read_operation,

    // CSR interface
    input  wire [7:0]  awaddr,
    input  wire [7:0]  araddr,
    input  wire [31:0] csr_wdata_in,
    input  wire        csr_start_write,
    input  wire        csr_start_read,
    output reg         csr_done_write,
    output reg         csr_done_read,
    output reg [31:0]  csr_rdata_out,

    // Stream
    input  wire [31:0] stream_in,
    output reg  [31:0] stream_out,
    output reg         done_write,
    output reg         read_stream_done
);

    // CSR memory
    reg [31:0] csr_mem [0:255];

    // FIFO
    reg [31:0] fifo [0:BURST_SIZE-1];
    reg [$clog2(BURST_SIZE):0] wr_ptr, rd_ptr, count;

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            csr_done_write   <= 0;
            csr_done_read    <= 0;
            csr_rdata_out    <= 0;
            done_write       <= 0;
            read_stream_done <= 0;
            stream_out       <= 0;
            wr_ptr           <= 0;
            rd_ptr           <= 0;
            count            <= 0;

            for (i=0; i<256; i=i+1)
                csr_mem[i] <= 0;
        end else begin
            // Defaults
            csr_done_write   <= 0;
            csr_done_read    <= 0;
            done_write       <= 0;
            read_stream_done <= 0;

            // CSR WRITE
            if (csr_start_write) begin
                csr_mem[awaddr] <= csr_wdata_in;
                csr_done_write  <= 1;
            end

            // CSR READ
            if (csr_start_read) begin
                csr_rdata_out <= csr_mem[araddr];
                csr_done_read <= 1;
            end

            // STREAM WRITE
            if (write_operation && count < BURST_SIZE) begin
                fifo[wr_ptr] <= stream_in;
                wr_ptr <= wr_ptr + 1;
                count  <= count + 1;
                if (count + 1 == BURST_SIZE)
                    done_write <= 1;
            end

            // STREAM READ
            if (read_operation && count > 0) begin
                stream_out <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count  <= count - 1;
                if (count == 1)
                    read_stream_done <= 1;
            end
        end
    end

endmodule
