// Transaction Generator
class transaction_generator;
    
    // Mailboxes
    mailbox #(apb_transaction) gen2drv;
    mailbox #(i2c_transaction) gen2scb;
    
    // Configuration
    int num_transactions = 10;
    string test_name = "BASIC";
    
    // Constructor
    function new(mailbox #(apb_transaction) gen2drv,
                 mailbox #(i2c_transaction) gen2scb);
        this.gen2drv = gen2drv;
        this.gen2scb = gen2scb;
    endfunction
    
    // Main run task
    task run();
        $display("[Generator] Starting %s test", test_name);
        
        case (test_name)
            "WRITE": generate_write_test();
            "READ":  generate_read_test();
            "MIXED": generate_mixed_test();
            default: generate_basic_test();
        endcase
        
        $display("[Generator] Completed generation");
    endtask
    
    // Generate write test
    task generate_write_test();
        apb_transaction apb_tx;
        i2c_transaction i2c_tx;
        
        // Initialize core
        init_sequence();
        
        // Write test
        for (int i = 0; i < num_transactions; i++) begin
            // Create I2C transaction
            i2c_tx = new();
            i2c_tx.slave_addr = 7'h51;
            i2c_tx.read_not_write = 0;
            i2c_tx.num_bytes = 1;
            i2c_tx.write_data = new[1];
            i2c_tx.write_data[0] = $urandom_range(0, 255);
            i2c_tx.stop_after = 1;
            
            // Send to scoreboard
            gen2scb.put(i2c_tx);
            
            // Generate APB sequence for write
            // START + Address + Write
            apb_tx = new();
            apb_tx.addr = 12'h010;  // TXR
            apb_tx.data = {24'h0, (i2c_tx.slave_addr << 1)};
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            apb_tx = new();
            apb_tx.addr = 12'h014;  // CMD
            apb_tx.data = 32'h90;    // STA=1, WR=1
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            // Data
            apb_tx = new();
            apb_tx.addr = 12'h010;  // TXR
            apb_tx.data = {24'h0, i2c_tx.write_data[0]};
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            // STOP
            apb_tx = new();
            apb_tx.addr = 12'h014;  // CMD
            apb_tx.data = 32'h50;    // STO=1, WR=1
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
        end
    endtask
    
    // Generate read test
    task generate_read_test();
        apb_transaction apb_tx;
        i2c_transaction i2c_tx;
        
        // Initialize core
        init_sequence();
        
        for (int i = 0; i < num_transactions; i++) begin
            // Create I2C transaction
            i2c_tx = new();
            i2c_tx.slave_addr = 7'h51;
            i2c_tx.read_not_write = 1;
            i2c_tx.num_bytes = 1;
            i2c_tx.stop_after = 1;
            
            // Send to scoreboard
            gen2scb.put(i2c_tx);
            
            // START + Address + Write (set pointer)
            apb_tx = new();
            apb_tx.addr = 12'h010;
            apb_tx.data = {24'h0, (i2c_tx.slave_addr << 1)};
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            apb_tx = new();
            apb_tx.addr = 12'h014;
            apb_tx.data = 32'h90;  // STA=1, WR=1
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            // Memory address
            apb_tx = new();
            apb_tx.addr = 12'h010;
            apb_tx.data = 32'h10;  // memory location
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            apb_tx = new();
            apb_tx.addr = 12'h014;
            apb_tx.data = 32'h10;  // WR only
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            // Repeated START + Address + Read
            apb_tx = new();
            apb_tx.addr = 12'h010;
            apb_tx.data = {24'h0, (i2c_tx.slave_addr << 1) | 1};
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            apb_tx = new();
            apb_tx.addr = 12'h014;
            apb_tx.data = 32'h90;  // STA=1, WR=1
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
            
            // Read + NACK + STOP
            apb_tx = new();
            apb_tx.addr = 12'h014;
            apb_tx.data = 32'h68;  // RD=1, ACK=1, STO=1
            apb_tx.write = 1;
            gen2drv.put(apb_tx);
        end
    endtask
    
    // Generate mixed test
    task generate_mixed_test();
        for (int i = 0; i < num_transactions; i++) begin
            if ($urandom_range(0,1))
                generate_write_test();
            else
                generate_read_test();
        end
    endtask
    
    // Generate basic test
    task generate_basic_test();
        generate_write_test();
        generate_read_test();
    endtask
    
    // Initialize core sequence
    task init_sequence();
        apb_transaction apb_tx;
        
        // Prescale for 100KHz (50MHz/5*100KHz -1 = 99)
        apb_tx = new();
        apb_tx.addr = 12'h000;  // PRERlo
        apb_tx.data = 32'h63;
        apb_tx.write = 1;
        gen2drv.put(apb_tx);
        
        apb_tx = new();
        apb_tx.addr = 12'h004;  // PRERhi
        apb_tx.data = 32'h00;
        apb_tx.write = 1;
        gen2drv.put(apb_tx);
        
        // Enable core
        apb_tx = new();
        apb_tx.addr = 12'h004;  // CTR
        apb_tx.data = 32'hC0;    // EN=1, IEN=1
        apb_tx.write = 1;
        gen2drv.put(apb_tx);
    endtask
    
endclass
