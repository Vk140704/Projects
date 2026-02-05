module i2c_slave #(
  parameter SLAVE_ADDR = 7'h42
)(
  input scl,
  inout sda,
  input rst
);

  reg sda_out;
  assign sda = sda_out ? 1'b0 : 1'bz;

  reg [3:0] bit_cnt;
  reg [7:0] shift;
  reg [2:0] state;

  localparam IDLE=0, ADDR=1, ACK1=2,
             DATA=3, ACK2=4;

  // detect START
  always @(negedge sda) begin
    if (scl) begin
      state <= ADDR;
      bit_cnt <= 7;
    end
  end

  // sample data
  always @(posedge scl or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      sda_out <= 0;
    end else begin
      case (state)

        ADDR: begin
          shift[bit_cnt] <= sda;
          if (bit_cnt == 0)
            state <= ACK1;
          else
            bit_cnt <= bit_cnt - 1;
        end

        DATA: begin
          shift[bit_cnt] <= sda;
          if (bit_cnt == 0)
            state <= ACK2;
          else
            bit_cnt <= bit_cnt - 1;
        end

      endcase
    end
  end

  // drive ACK
  always @(negedge scl) begin
    case (state)
      ACK1: begin
        if (shift[7:1] == SLAVE_ADDR)
          sda_out <= 1;
        state <= DATA;
        bit_cnt <= 7;
      end

      ACK2: begin
        sda_out <= 1;
        state <= IDLE;
      end

      default: sda_out <= 0;
    endcase
  end

endmodule
