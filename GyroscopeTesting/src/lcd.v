module lcd #(
    parameter integer CLK_SPEED = 27_000_000
) (
    input clk,
    input [3:0] x_0,
    input [3:0] x_1,
    input [3:0] x_2,
    input [3:0] y_0,
    input [3:0] y_1,
    input [3:0] y_2,
    input [3:0] z_0,
    input [3:0] z_1,
    input [3:0] z_2,
    output reg rs,
    output reg rw,
    output reg e = 0,
    inout [7:0] db
);
  reg [7:0] dbout = 8'b00000000;
  assign db = rw ? 8'bzzzzzzzz : dbout;

  `define MS_TO_CLK(s) (s * CLK_SPEED / 1000)

  localparam reg [4:0]
  // Init
  INIT_WAIT_1 = 0,
    INIT_FUNC_1 = 1,
    INIT_WAIT_2 = 2,
    INIT_FUNC_2 = 3,
    INIT_WAIT_3 = 4,
    INIT_FUNC_3 = 5,
    INIT_FUNC_REAL = 6,
    INIT_DISPLAY_OFF = 7,
    INIT_DISPLAY_CLEAR = 8,
    INIT_WAIT_CLEAR = 9,
    INIT_ENTRY_MODE_SET = 10,
    INIT_DISPLAY_ON = 11,

  // Common Write, Read
  TXRX_START = 12, TXRX_TSU = 13, TXRX_TE = 14, TXRX_TW = 15,

  // Other
  TEXT = 16, DONE = 17;

  reg [4:0] state = INIT_WAIT_1;

  integer delay_counter = `MS_TO_CLK(15);

  reg txrx_rs;
  reg txrx_rw;
  reg [7:0] txrx_db;
  reg [4:0] txrx_next_state;
  integer txrx_next_state_delay_counter;

  integer text_counter = 0;

  always @(posedge clk) begin
    if (delay_counter > 0) begin
      delay_counter <= delay_counter - 1;
    end
    case (state)
      INIT_WAIT_1: begin
        if (delay_counter == 0) begin
          state = INIT_FUNC_1;
        end
      end
      INIT_FUNC_1: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00110000;
        txrx_next_state <= INIT_WAIT_2;
        txrx_next_state_delay_counter <= `MS_TO_CLK(4.1);
        state <= TXRX_START;
      end

      INIT_WAIT_2: begin
        if (delay_counter == 0) begin
          state <= INIT_FUNC_2;
        end
      end

      INIT_FUNC_2: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00110000;
        txrx_next_state <= INIT_WAIT_3;
        txrx_next_state_delay_counter <= `MS_TO_CLK(0.1);
        state <= TXRX_START;
      end

      INIT_WAIT_3: begin
        if (delay_counter == 0) begin
          state <= INIT_FUNC_3;
        end
      end

      INIT_FUNC_3: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00110000;
        txrx_next_state <= INIT_FUNC_REAL;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
      end

      INIT_FUNC_REAL: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00111000;
        txrx_next_state <= INIT_DISPLAY_OFF;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
      end

      INIT_DISPLAY_OFF: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00001000;
        txrx_next_state <= INIT_DISPLAY_CLEAR;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
      end

      INIT_DISPLAY_CLEAR: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00000001;
        txrx_next_state <= INIT_WAIT_CLEAR;
        txrx_next_state_delay_counter <= `MS_TO_CLK(1.53);
        state <= TXRX_START;
      end

      INIT_WAIT_CLEAR: begin
        if (delay_counter == 0) begin
          state <= INIT_ENTRY_MODE_SET;
        end
      end

      INIT_ENTRY_MODE_SET: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00000110;
        txrx_next_state <= INIT_DISPLAY_ON;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
      end

      INIT_DISPLAY_ON: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_db <= 8'b00001100;
        txrx_next_state <= TEXT;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
      end

      TEXT: begin
        txrx_rs = 1;
        txrx_rw = 0;
        txrx_next_state <= TEXT;
        txrx_next_state_delay_counter <= 0;
        text_counter <= text_counter + 1;
        state <= TXRX_START;
        case (text_counter)
          0:  txrx_db = 8'b01011000;
          1:  txrx_db = 8'b00111010;
          2:  txrx_db = {4'b0011, x_0};
          3:  txrx_db = {4'b0011, x_1};
          4:  txrx_db = {4'b0011, x_2};
          5:  txrx_db = 8'b01011001;
          6:  txrx_db = 8'b00111010;
          7:  txrx_db = {4'b0011, y_0};
          8:  txrx_db = {4'b0011, y_1};
          9:  txrx_db = {4'b0011, y_2};
          10: txrx_db = 8'b01011010;
          11: txrx_db = 8'b00111010;
          12: txrx_db = {4'b0011, z_0};
          13: txrx_db = {4'b0011, z_1};
          14: begin
            txrx_db = {4'b0011, z_2};
            txrx_next_state <= DONE;
          end
          default: begin
          end
        endcase
      end

      TXRX_START: begin
        delay_counter <= 5;
        state <= TXRX_TSU;
      end
      TXRX_TSU: begin
        if (delay_counter == 0) begin
          dbout <= txrx_db;
          rw <= txrx_rw;
          rs <= txrx_rs;
          delay_counter <= 2;
          state <= TXRX_TE;
        end
      end
      TXRX_TE: begin
        if (delay_counter == 0) begin
          e <= 1;
          delay_counter <= `MS_TO_CLK(0.3);
          state <= TXRX_TW;
        end
      end
      TXRX_TW: begin
        if (delay_counter == 0) begin
          e <= 0;
          state <= txrx_next_state;
          delay_counter <= txrx_next_state_delay_counter;
        end
      end

      default: begin
      end
    endcase
  end
endmodule
