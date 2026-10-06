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
    input [31:0] GyroReading,
    input [15:0] LeftEncoderReading,
    input [15:0] RightEncoderReading,
    output reg rs,
    output reg rw,
    output reg e = 0,
    output reg sr_data = 0,
    output reg sr_clk = 0,
    output reg sr_latch = 0
);
  wire [5 * 4 - 1:0] LeftEncoderBCD;

  binary_to_bcd #(
      .N_BITS(16),
      .DIGITS(5)
  ) binary_to_bcd_inst (
      .binary_in(LeftEncoderReading),
      .bcd_out  (LeftEncoderBCD)
  );

  wire [5 * 4 - 1:0] RightEncoderBCD;

  binary_to_bcd #(
      .N_BITS(16),
      .DIGITS(5)
  ) binary_to_bcd_inst1 (
      .binary_in(RightEncoderReading),
      .bcd_out  (RightEncoderBCD)
  );

  wire [63:0] GyroReadingLCD;
  hex_to_lcd #(
      .N(32)
  ) hex_to_lcd_inst (
      .data_in (GyroReading),
      .char_out(GyroReadingLCD)
  );

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

  // Shift Register States
  TXRX_SHIFT_LOW = 16, TXRX_SHIFT_HIGH = 17, TXRX_SHIFT_LATCH = 18,

  // Other
  TEXT = 19, RST = 20, RST_IDLE = 21;


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
        txrx_rs <= 1;
        txrx_rw <= 0;
        txrx_next_state <= TEXT;
        txrx_next_state_delay_counter <= 0;
        text_counter <= text_counter + 1;
        state <= TXRX_START;
        // EDIT ME TO ADD TEXT :D (Edit text_counter check at the end too)
        case (text_counter)
          0:  txrx_db <= 8'b01011000;
          1:  txrx_db <= 8'b00111010;
          2:  txrx_db <= {4'b0011, x_0};
          3:  txrx_db <= {4'b0011, x_1};
          4:  txrx_db <= {4'b0011, x_2};
          5:  txrx_db <= 8'b01011001;
          6:  txrx_db <= 8'b00111010;
          7:  txrx_db <= {4'b0011, y_0};
          8:  txrx_db <= {4'b0011, y_1};
          9:  txrx_db <= {4'b0011, y_2};
          10: txrx_db <= 8'b01011010;
          11: txrx_db <= 8'b00111010;
          12: txrx_db <= {4'b0011, z_0};
          13: txrx_db <= {4'b0011, z_1};
          14: txrx_db <= {4'b0011, z_2};
          15: txrx_db <= 8'b00100000;

          // --- LINE 2 JUMP COMMAND ---
          16: begin
            txrx_db <= 8'b11000000;
            txrx_rs <= 0;
          end  // 0xC0: Set DDRAM address to 0x40 (Line 2)

          //          17: txrx_db <= GyroReadingLCD[63:56];
          //          18: txrx_db <= GyroReadingLCD[55:48];
          //          19: txrx_db <= GyroReadingLCD[47:40];
          //          20: txrx_db <= GyroReadingLCD[39:32];
          //          21: txrx_db <= GyroReadingLCD[31:24];
          //          22: txrx_db <= GyroReadingLCD[23:16];
          //          23: txrx_db <= GyroReadingLCD[15:8];
          //          24: txrx_db <= GyroReadingLCD[7:0];
          //          25: txrx_db <= 8'b00100000;
          //          26: txrx_db <= 8'b00100000;
          //          27: txrx_db <= 8'b00100000;
          17: txrx_db <= 8'b01001100;
          18: txrx_db <= 8'b00111010;
          19: txrx_db <= {4'b0011, LeftEncoderBCD[19:16]};
          20: txrx_db <= {4'b0011, LeftEncoderBCD[15:12]};
          21: txrx_db <= {4'b0011, LeftEncoderBCD[11:8]};
          22: txrx_db <= {4'b0011, LeftEncoderBCD[7:4]};
          23: txrx_db <= {4'b0011, LeftEncoderBCD[3:0]};
          24: txrx_db <= 8'b00100000;
          25: txrx_db <= 8'b01010011;
          26: txrx_db <= 8'b00111010;
          27: txrx_db <= {4'b0011, LeftEncoderBCD[19:16]};
          28: txrx_db <= {4'b0011, LeftEncoderBCD[15:12]};
          29: txrx_db <= {4'b0011, LeftEncoderBCD[11:8]};
          30: txrx_db <= {4'b0011, LeftEncoderBCD[7:4]};
          31: txrx_db <= {4'b0011, LeftEncoderBCD[3:0]};
          default: begin
          end
        endcase
        if (text_counter == 32) begin
          txrx_next_state_delay_counter <= `MS_TO_CLK(1000);
          txrx_next_state <= RST;
        end
      end

      RST: begin
        if (delay_counter == 0) begin
          txrx_rs = 0;
          txrx_rw <= 0;
          txrx_next_state <= RST_IDLE;
          txrx_next_state_delay_counter <= `MS_TO_CLK(5);
          txrx_db <= 8'b00000001;
          state <= TXRX_START;
        end
      end

      RST_IDLE: begin
        if (delay_counter == 0) begin
          text_counter <= 0;
          state <= TEXT;
        end
      end

      TXRX_START: begin
        delay_counter <= 5;
        state <= TXRX_TSU;
      end

      TXRX_TSU: begin
        if (delay_counter == 0) begin
          // Setup RS/RW early so LCD sees them while shift register populates
          rw <= txrx_rw;
          rs <= txrx_rs;
          shift_count <= 7;  // Start at MSB (Bit 7)
          state <= TXRX_SHIFT_LOW;
        end
      end

      TXRX_SHIFT_LOW: begin
        sr_data <= txrx_db[shift_count];
        sr_clk  <= 0;
        state   <= TXRX_SHIFT_HIGH;
      end

      TXRX_SHIFT_HIGH: begin
        sr_clk <= 1;  // Shift the bit in on rising edge
        if (shift_count == 0) begin
          state <= TXRX_SHIFT_LATCH;
        end else begin
          shift_count <= shift_count - 1;
          state <= TXRX_SHIFT_LOW;
        end
      end

      TXRX_SHIFT_LATCH: begin
        sr_latch <= 1;  // Pulse latch to move data to parallel outputs
        sr_clk <= 0;
        delay_counter <= 2;  // Brief setup wait before pulsing E
        state <= TXRX_TE;
      end

      TXRX_TE: begin
        if (delay_counter == 0) begin
          sr_latch <= 0;
          e <= 1;  // Pulse LCD enable
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
