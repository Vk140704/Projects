module i2c_master #(
  parameter CLK_DIV = 50
)(
  input clk,
  input rst,
  input start,
  input [6:0] addr,
  input rw,
  input [7:0] data_wr,
  output reg busy,
  output reg ack_err,
  inout sda,
  output reg scl
);

  // open-drain SDA
  reg sda_out;
  assign sda = sda_out ? 1'b0 : 1'bz;

  // SCL generator
  reg [15:0] cnt;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      cnt <= 0;
      scl <= 1;
    end else if (cnt == CLK_DIV) begin
      cnt <= 0;
      scl <= ~scl;
    end else cnt <= cnt + 1;
  end

  // FSM
  localparam IDLE=0, START=1, ADDR=2, ACK1=3,
             DATA=4, ACK2=5, STOP=6;

  reg [2:0] state;
  reg [3:0] bit_cnt;
  reg [7:0] shift;

  always @(negedge scl or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      sda_out <= 0;
      busy <= 0;
      ack_err <= 0;
    end else begin
      case (state)

        IDLE: begin
          busy <= 0;
          sda_out <= 0;
          if (start) begin
            busy <= 1;
            sda_out <= 1; // START
            state <= START;
          end
        end

        START: begin
          shift <= {addr, rw};
          bit_cnt <= 7;
          state <= ADDR;
        end

        ADDR: begin
          sda_out <= ~shift[bit_cnt];
          if (bit_cnt == 0)
            state <= ACK1;
          else
            bit_cnt <= bit_cnt - 1;
        end

        ACK1: begin
          sda_out <= 0;
          if (sda) ack_err <= 1;
          shift <= data_wr;
          bit_cnt <= 7;
          state <= DATA;
        end

        DATA: begin
          sda_out <= ~shift[bit_cnt];
          if (bit_cnt == 0)
            state <= ACK2;
          else
            bit_cnt <= bit_cnt - 1;
        end

        ACK2: begin
          sda_out <= 0;
          if (sda) ack_err <= 1;
          state <= STOP;
        end

        STOP: begin
          sda_out <= 0; // STOP
          busy <= 0;
          state <= IDLE;
        end

      endcase
    end
  end

endmodule
