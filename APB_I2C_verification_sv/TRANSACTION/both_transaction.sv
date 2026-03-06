// APB Transaction
class apb_transaction;
    
    // Properties
    rand bit [11:0] addr;
    rand bit [31:0] data;
    rand bit        write;
    
    bit [31:0]      rdata;
    
    // Address constraints
    constraint valid_addr_c {
        addr inside {12'h000, 12'h004, 12'h008, 12'h00C, 12'h010, 12'h014};
    }
    
    // Display function
    function void display(string prefix = "");
        if (write)
            $display("%sAPB WRITE: addr=0x%03h data=0x%08h", 
                     prefix, addr, data);
        else
            $display("%sAPB READ:  addr=0x%03h rdata=0x%08h", 
                     prefix, addr, rdata);
    endfunction
    
    // Copy function
    function apb_transaction copy();
        apb_transaction t = new();
        t.addr = this.addr;
        t.data = this.data;
        t.write = this.write;
        t.rdata = this.rdata;
        return t;
    endfunction
    
endclass

// I2C Transaction
class i2c_transaction;
    
    // Properties
    rand bit [6:0]  slave_addr;
    rand bit        read_not_write;  // 1=read, 0=write
    rand bit [7:0]  write_data[];
    rand int        num_bytes;
    rand bit        stop_after;
    
    // Observed data
    bit [7:0]       read_data[];
    bit             ack_received[];
    bit             start_detected;
    bit             stop_detected;
    
    // Constraints
    constraint num_bytes_c {
        num_bytes inside {[1:8]};
        write_data.size() == num_bytes;
    }
    
    // Display function
    function void display(string prefix = "");
        $write("%sI2C %s to addr 0x%02h, %0d bytes", 
               prefix, read_not_write ? "READ" : "WRITE", 
               slave_addr, num_bytes);
        if (!read_not_write) begin
            $write(", data: ");
            foreach (write_data[i])
                $write("0x%02h ", write_data[i]);
        end
        $display("");
    endfunction
    
    // Copy function
    function i2c_transaction copy();
        i2c_transaction t = new();
        t.slave_addr = this.slave_addr;
        t.read_not_write = this.read_not_write;
        t.write_data = this.write_data;
        t.num_bytes = this.num_bytes;
        t.stop_after = this.stop_after;
        return t;
    endfunction
    
endclass
