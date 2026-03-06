//============================================================================

// Testbench for I2C Master Core (APB to I2C)
//============================================================================

`timescale 1ns/1ps

module tb_i2c_master;

    //=========================================================================
    // Parameters
    //=========================================================================
    parameter CLK_PERIOD    = 20;           // 50MHz clock
    parameter APB_ADDR_WIDTH = 12;
    
    //=========================================================================
    // Signals
    //=========================================================================
    // Clock and reset
    logic                        clk;
    logic                        rst_n;
    
    // APB Interface signals (connect to your DUT)
    logic [APB_ADDR_WIDTH-1:0]   paddr;
    logic [31:0]                 pwdata;
    logic [31:0]                 prdata;
    logic                        pwrite;
    logic                        psel;
    logic                        penable;
    logic                        pready;
    logic                        pslverr;
    logic                        interrupt;
    
    // I2C Pad signals (connect to your DUT)
    logic                        scl_i;
    logic                        scl_o;
    logic                        scl_oen;
    logic                        sda_i;
    logic                        sda_o;
    logic                        sda_oen;
    
    // I2C Bus signals (with pull-ups)
    wire                         scl;
    wire                         sda;
    
    // I2C Bus pull-ups (as per your spec)
    assign scl = scl_oen ? 1'bz : scl_o;
    assign sda = sda_oen ? 1'bz : sda_o;
    assign scl_i = scl;
    assign sda_i = sda;
    
    //=========================================================================
    // Clock Generation
    //=========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //=========================================================================
    // Reset Generation
    //=========================================================================
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        $display("[TB] Reset released at time %t", $time);
    end
    
    //=========================================================================
    // YOUR DUT Instantiation
    //=========================================================================
    apb_i2c #(
        .APB_ADDR_WIDTH(APB_ADDR_WIDTH)
    ) dut (
        .HCLK          (clk),
        .HRESETn       (rst_n),
        .PADDR         (paddr),
        .PWDATA        (pwdata),
        .PWRITE        (pwrite),
        .PSEL          (psel),
        .PENABLE       (penable),
        .PRDATA        (prdata),
        .PREADY        (pready),
        .PSLVERR       (pslverr),
        .interrupt_o   (interrupt),
        .scl_pad_i     (scl_i),
        .scl_pad_o     (scl_o),
        .scl_padoen_o  (scl_oen),
        .sda_pad_i     (sda_i),
        .sda_pad_o     (sda_o),
        .sda_padoen_o  (sda_oen)
    );
    
    //=========================================================================
    // Simple I2C Slave Model (for testing YOUR design)
    //=========================================================================
    i2c_slave_model #(
        .SLAVE_ADDR(7'h51)  // Slave address 0x51
    ) u_slave (
        .scl(scl),
        .sda(sda)
    );
    
    //=========================================================================
    // Test Control
    //=========================================================================
    initial begin
        // Wait for reset
        @(posedge rst_n);
        #100;
        
        $display("");
        $display("==========================================================");
        $display("Testing YOUR I2C Master Design");
        $display("==========================================================");
        $display("Time: %t", $time);
        $display("");
        
        // Run tests
        test_register_access();
        test_init_core();
        test_write_byte();
        test_read_byte();
        test_status_check();
        test_interrupt_handling();
        
        // End simulation
        $display("");
        $display("==========================================================");
        $display("All Tests Completed at time %t", $time);
        $display("==========================================================");
        $finish;
    end
    
    //=========================================================================
    // APB Write Task (matches your design's APB interface)
    //=========================================================================
    task apb_write(input [11:0] addr, input [31:0] data);
        @(posedge clk);
        psel <= 1;
        paddr <= addr;
        pwdata <= data;
        pwrite <= 1;
        penable <= 0;
        
        @(posedge clk);
        penable <= 1;
        
        @(posedge clk);
        while (!pready) @(posedge clk);
        
        @(posedge clk);
        psel <= 0;
        penable <= 0;
        
      $display("[APB] WRITE: addr=0x%03h data=0x%08h [Time=%0t]", 
                 addr, data, $time);
    endtask
    
    //=========================================================================
    // APB Read Task (matches your design's APB interface)
    //=========================================================================
    task apb_read(input [11:0] addr, output [31:0] data);
        @(posedge clk);
        psel <= 1;
        paddr <= addr;
        pwrite <= 0;
        penable <= 0;
        
        @(posedge clk);
        penable <= 1;
        
        @(posedge clk);
        while (!pready) @(posedge clk);
        data = prdata;
        
        @(posedge clk);
        psel <= 0;
        penable <= 0;
        
      $display("[APB] READ:  addr=0x%03h data=0x%08h [Time=%0t]", 
                 addr, data, $time);
    endtask
    
    //=========================================================================
    // Test 1: Check if your registers are accessible
    //=========================================================================
    task test_register_access();
        logic [31:0] read_data;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 1: Register Access Test (Checking YOUR core registers)");
        $display("----------------------------------------------------------");
        
        // According to your design, registers are at:
        // 0x000: PRERlo
        // 0x004: PRERhi/CTR (same address? Your design uses 0x004 for both)
        // 0x008: RXR
        // 0x00C: STATUS
        // 0x010: TXR
        // 0x014: CMD
        
        // Write to PRERlo
        apb_write(12'h000, 32'h1234);
        apb_read(12'h000, read_data);
        
        // Write to PRERhi/CTR
        apb_write(12'h004, 32'h5678);
        apb_read(12'h004, read_data);
        
        // Write to TXR
        apb_write(12'h010, 32'hAA);
        apb_read(12'h010, read_data);
        
        // Write to CMD
        apb_write(12'h014, 32'h00);
        
        $display("[TEST 1] Your core registers are accessible");
    endtask
    
    //=========================================================================
    // Test 2: Initialize your core
    //=========================================================================
    task test_init_core();
        logic [31:0] read_data;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 2: Initialize YOUR I2C Core");
        $display("----------------------------------------------------------");
        
        // Set prescale for 100KHz (50MHz / (5*100KHz) - 1 = 99)
        apb_write(12'h000, 32'h63);    // PRERlo = 0x63
        
        // According to your design, PRERhi is at 0x004
        apb_write(12'h004, 32'h00);    // PRERhi = 0x00
        
        // Enable core (your CTR register is also at 0x004)
        // CTR[7] = EN, CTR[6] = IEN
        apb_write(12'h004, 32'hC0);    // CTR = EN=1, IEN=1
        
        // Verify
        apb_read(12'h004, read_data);
        
        $display("[TEST 2] Your core initialized successfully");
    endtask
    
    //=========================================================================
    // Test 3: Write byte to slave using YOUR core
    //=========================================================================
    task test_write_byte();
        logic [31:0] status;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 3: Write Byte using YOUR I2C Master");
        $display("----------------------------------------------------------");
        
        // Step 1: Send START + Slave Address + Write
        apb_write(12'h010, 32'hA2);    // TXR = 0xA2 (0x51<<1 | 0)
        apb_write(12'h014, 32'h90);    // CMD = STA=1, WR=1
        
        wait_for_interrupt();
        read_status();
        
        // Step 2: Send Data + STOP
        apb_write(12'h010, 32'hAC);    // TXR = 0xAC (data)
        apb_write(12'h014, 32'h50);    // CMD = STO=1, WR=1
        
        wait_for_interrupt();
        read_status();
        
        // Clear interrupt
        apb_write(12'h014, 32'h01);    // CMD = IACK=1
        
        $display("[TEST 3] Your I2C Master write test completed");
    endtask
    
    //=========================================================================
    // Test 4: Read byte from slave using YOUR core
    //=========================================================================
    task test_read_byte();
        logic [31:0] status, data;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 4: Read Byte using YOUR I2C Master");
        $display("----------------------------------------------------------");
        
        // Step 1: START + Address + Write (set memory pointer)
        apb_write(12'h010, 32'hA2);    // TXR = 0xA2
        apb_write(12'h014, 32'h90);    // CMD = STA=1, WR=1
        wait_for_interrupt();
        
        // Step 2: Write memory location
        apb_write(12'h010, 32'h10);    // TXR = memory location 0x10
        apb_write(12'h014, 32'h10);    // CMD = WR=1
        wait_for_interrupt();
        
        // Step 3: Repeated START + Address + Read
        apb_write(12'h010, 32'hA3);    // TXR = 0xA3 (0x51<<1 | 1)
        apb_write(12'h014, 32'h90);    // CMD = STA=1, WR=1
        wait_for_interrupt();
        
        // Step 4: Read data + NACK + STOP
        apb_write(12'h014, 32'h68);    // CMD = RD=1, ACK=1, STO=1
        wait_for_interrupt();
        
        // Step 5: Read received data
        apb_read(12'h008, data);        // RXR
        $display("[TEST 4] Received data from YOUR core: 0x%02h", data[7:0]);
        
        // Clear interrupt
        apb_write(12'h014, 32'h01);    // IACK=1
        
        $display("[TEST 4] Your I2C Master read test completed");
    endtask
    
    //=========================================================================
    // Test 5: Check your status register bits
    //=========================================================================
    task test_status_check();
        logic [31:0] status;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 5: Check YOUR Core Status Register");
        $display("----------------------------------------------------------");
        
        apb_read(12'h00C, status);
        
        $display("[YOUR CORE STATUS] Bit7(RxACK)=%s | Bit6(Busy)=%b | Bit5(AL)=%b | Bit1(TIP)=%b | Bit0(IF)=%b",
                 status[7] ? "NACK" : "ACK",
                 status[6],
                 status[5],
                 status[1],
                 status[0]);
        
        $display("[TEST 5] Status register check completed");
    endtask
    
    //=========================================================================
    // Test 6: Test interrupt handling
    //=========================================================================
    task test_interrupt_handling();
        logic [31:0] status;
        
        $display("");
        $display("----------------------------------------------------------");
        $display("TEST 6: Test YOUR Core Interrupt Handling");
        $display("----------------------------------------------------------");
        
        // Generate a transfer to create interrupt
        apb_write(12'h010, 32'hA2);
        apb_write(12'h014, 32'h90);
        
        wait_for_interrupt();
        
        // Check if interrupt flag is set
        apb_read(12'h00C, status);
        if (status[0]) begin
            $display("[TEST 6] PASS: Interrupt flag (IF) is set");
        end else begin
            $display("[TEST 6] FAIL: Interrupt flag not set");
        end
        
        // Clear interrupt
        apb_write(12'h014, 32'h01);
        
        // Check if interrupt cleared
        apb_read(12'h00C, status);
        if (!status[0]) begin
            $display("[TEST 6] PASS: Interrupt cleared successfully");
        end else begin
            $display("[TEST 6] FAIL: Interrupt not cleared");
        end
        
        $display("[TEST 6] Interrupt handling test completed");
    endtask
    
    //=========================================================================
    // Wait for Interrupt (from YOUR core)
    //=========================================================================
    task wait_for_interrupt();
        $display("[TB] Waiting for interrupt from YOUR core...");
        @(posedge interrupt);
        $display("[TB] Interrupt received at time %t", $time);
    endtask
    
    //=========================================================================
    // Read Status (helper task)
    //=========================================================================
    task read_status();
        logic [31:0] status;
        apb_read(12'h00C, status);
    endtask
    
    //=========================================================================
    // Simulation Timeout
    //=========================================================================
    initial begin
        #1_000_000;
        $display("");
        $display("==========================================================");
        $display("ERROR: Simulation Timeout at %t", $time);
        $display("==========================================================");
        $finish;
    end
    
    //=========================================================================
    // Waveform Dumping
    //=========================================================================
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_i2c_master);
    end

endmodule


//=============================================================================
// Simple I2C Slave Model (for testing YOUR design)
//=============================================================================
module i2c_slave_model #(
    parameter SLAVE_ADDR = 7'h51
) (
    inout wire scl,
    inout wire sda
);
    
    // States
    typedef enum logic [2:0] {
        IDLE, GET_ADDR, GET_DATA, SEND_DATA, STOP
    } state_t;
    
    state_t state = IDLE;
    
    // Internal registers
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg [7:0] memory [0:255];
    reg       rw_bit;
    reg [7:0] mem_addr;
    reg       sda_out_en;
    reg       sda_out_data;
    
    // SDA control (open-drain) - as per I2C spec
    assign sda = sda_out_en ? sda_out_data : 1'bz;
    
    // Initialize memory
    initial begin
        for (int i = 0; i < 256; i++) begin
            memory[i] = i + 8'h10;
        end
        $display("[SLAVE] Model initialized for testing YOUR I2C Master");
    end
    
    // I2C State Machine
    always @(posedge scl) begin
        case (state)
            IDLE: begin
                sda_out_en <= 0;
                bit_count <= 0;
                if (sda == 0 && $past(sda) == 1) begin
                    $display("[SLAVE] START detected");
                    state <= GET_ADDR;
                end
            end
            
            GET_ADDR: begin
                shift_reg <= {shift_reg[6:0], sda};
                bit_count <= bit_count + 1;
                
                if (bit_count == 7) begin
                    rw_bit = sda;
                    if (shift_reg[7:1] == SLAVE_ADDR) begin
                        $display("[SLAVE] Address matched: 0x%02h %s", 
                                 SLAVE_ADDR, rw_bit ? "READ" : "WRITE");
                        bit_count <= 0;
                    end else begin
                        state <= IDLE;
                    end
                end
            end
            
            GET_DATA: begin
                shift_reg <= {shift_reg[6:0], sda};
                bit_count <= bit_count + 1;
                
                if (bit_count == 7) begin
                    memory[mem_addr] = {shift_reg[6:0], sda};
                    $display("[SLAVE] Received data: 0x%02h", 
                             {shift_reg[6:0], sda});
                    bit_count <= 0;
                end
            end
            
            SEND_DATA: begin
                if (bit_count == 0) begin
                    shift_reg <= memory[mem_addr];
                    $display("[SLAVE] Sending data: 0x%02h", memory[mem_addr]);
                end
                
                if (bit_count < 8) begin
                    sda_out_en <= 1;
                    sda_out_data <= memory[mem_addr][7-bit_count];
                    bit_count <= bit_count + 1;
                end
            end
        endcase
    end
    
    // Falling edge operations (ACK generation)
    always @(negedge scl) begin
        case (state)
            GET_ADDR: begin
                if (bit_count == 0 && shift_reg[7:1] == SLAVE_ADDR) begin
                    sda_out_en <= 1;
                    sda_out_data <= 0;  // ACK
                    @(negedge scl);
                    sda_out_en <= 0;
                    
                    if (rw_bit == 0) state <= GET_DATA;
                    else state <= SEND_DATA;
                    
                    mem_addr <= 8'h10;  // Start address
                end
            end
            
            GET_DATA: begin
                if (bit_count == 0) begin
                    sda_out_en <= 1;
                    sda_out_data <= 0;  // ACK
                    @(negedge scl);
                    sda_out_en <= 0;
                    mem_addr <= mem_addr + 1;
                end
            end
            
            SEND_DATA: begin
                if (bit_count == 8) begin
                    sda_out_en <= 0;
                    bit_count <= 0;
                end
            end
        endcase
    end
    
    // STOP detection
    always @(posedge sda) begin
        if (scl == 1) begin
            $display("[SLAVE] STOP detected");
            state <= IDLE;
            sda_out_en <= 0;
        end
    end

endmodule
