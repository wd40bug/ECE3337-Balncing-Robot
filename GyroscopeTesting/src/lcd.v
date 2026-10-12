module lcd #(
    parameter integer CLK_SPEED = 27_000_000
) (
    input clk,
    input [7:0] char,
    output reg [4:0] lcd_rqst = 0,
    output reg rs,
    output reg rw,
    output reg e = 0,
    output reg sr_data = 0,
    output reg sr_clk = 0,
    output reg sr_latch = 0
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
  TEXT = 19, NEWLINE=20, RST = 21, RST_IDLE = 22;


  reg [4:0] state = INIT_WAIT_1;

  reg [63:0] delay_counter = `MS_TO_CLK(15);

  reg txrx_rs;
  reg txrx_rw;
  reg [7:0] txrx_db;
  reg [4:0] txrx_next_state;
  reg [63:0] txrx_next_state_delay_counter;
  reg [3:0] shift_count = 0;

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
        lcd_rqst <= lcd_rqst + 1;
        state <= TXRX_START;
        txrx_db <= char;

        if (lcd_rqst == 15) begin
          txrx_next_state <= NEWLINE;
        end else if (lcd_rqst == 31) begin
          txrx_next_state <= RST;
          txrx_next_state_delay_counter <= `MS_TO_CLK(1000);
        end
      end

      NEWLINE: begin
        txrx_rs <= 0;
        txrx_rw <= 0;
        txrx_next_state <= TEXT;
        txrx_next_state_delay_counter <= 0;
        state <= TXRX_START;
        txrx_db <= 8'b11000000;
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
          lcd_rqst <= 0;
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
