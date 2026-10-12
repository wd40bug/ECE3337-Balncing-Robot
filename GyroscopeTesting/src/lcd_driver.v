module lcd_driver #(
    parameter integer DEFAULT_PAGE = 0
) (
    input clk,
    input page_forward,
    input page_backward,
    input [4:0] lcd_rqst,
    input pitch_sign,
    input [6:0] pitch_value,
    input yaw_sign,
    input [6:0] yaw_value,
    input [31:0] RawGyroReading,
    input left_dir,
    input [15:0] LeftEncoderReading,
    input right_dir,
    input [15:0] RightEncoderReading,
    input pwm_left_dir,
    input [7:0] pwm_left,
    input pwm_right_dir,
    input [7:0] pwm_right,
    input [2:0] demo_state,
    output reg [7:0] lcd_char
);

  localparam [2:0] MAX_PAGE = 3;
  reg [2:0] page_num = DEFAULT_PAGE;

  wire forward_pulse;
  wire forward_held;
  wire backward_pulse;
  wire backward_held;

  button_conditioner #(
      .DEBOUNCE_MAX(20'd1_000_000)
  ) forward_cond (
      .clk(clk),
      .async_btn(page_forward),
      .btn_pulse(forward_pulse),
      .btn_held(forward_held)
  );

  button_conditioner #(
      .DEBOUNCE_MAX(20'd1_000_000)
  ) backward_cond (
      .clk(clk),
      .async_btn(page_backward),
      .btn_pulse(backward_pulse),
      .btn_held(backward_held)
  );

  // Paging logic
  always @(posedge clk) begin
    if (forward_held && backward_held) begin
      page_num <= DEFAULT_PAGE;
    end else if (forward_pulse && page_num < MAX_PAGE) begin
      page_num <= page_num + 1;
    end else if (backward_pulse && page_num > 0) begin
      page_num <= page_num - 1;
    end
  end

  wire [2 * 4 - 1:0] pitch_bcd;
  wire [2 * 4 - 1:0] yaw_bcd;

  binary_to_bcd #(
      .N_BITS(7),
      .DIGITS(2)
  ) binary_to_bcd_inst2 (
      .binary_in(pitch_value),
      .bcd_out  (pitch_bcd)
  );
  binary_to_bcd #(
      .N_BITS(7),
      .DIGITS(2)
  ) binary_to_bcd_inst3 (
      .binary_in(yaw_value),
      .bcd_out  (yaw_bcd)
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
      .data_in (RawGyroReading),
      .char_out(GyroReadingLCD)
  );

  wire [3 * 4 - 1:0] pwm_left_bcd;
  binary_to_bcd #(
      .N_BITS(8),
      .DIGITS(3)
  ) binary_to_bcd_inst4 (
    .binary_in(pwm_left),
    .bcd_out(pwm_left_bcd)
  );

  wire [3 * 4 - 1:0] pwm_right_bcd;
  binary_to_bcd #(
      .N_BITS(8),
      .DIGITS(3)
  ) binary_to_bcd_inst5 (
    .binary_in(pwm_right),
    .bcd_out(pwm_right_bcd)
  );



  always @(*) begin
    case (page_num)
      0: begin
        case (lcd_rqst)
          0: lcd_char <= "P";  // P
          1: lcd_char <= "i";
          2: lcd_char <= "t";
          3: lcd_char <= "c";
          4: lcd_char <= "h";
          5: lcd_char <= ":";  // :
          6: lcd_char <= {4'b0010, pitch_sign ? 4'b1011 : 4'b1101};
          7: lcd_char <= {4'b0011, pitch_bcd[7:4]};
          8: lcd_char <= {4'b0011, pitch_bcd[3:0]};

          16: lcd_char <= "Y";  // Y
          17: lcd_char <= "a";
          18: lcd_char <= "w";
          19: lcd_char <= ":";  // :
          22: lcd_char <= {4'b0010, yaw_sign ? 4'b1011 : 4'b1101};
          23: lcd_char <= {4'b0011, yaw_bcd[7:4]};
          24: lcd_char <= {4'b0011, yaw_bcd[3:0]};
          default: lcd_char <= " ";  // Space
        endcase
      end  // Page 0
      1: begin
        case (lcd_rqst)
          0: lcd_char <= "L";
          1: lcd_char <= ":";
          2: lcd_char <= {4'b0010, left_dir ? 4'b1011 : 4'b1101};
          3: lcd_char <= {4'b0011, LeftEncoderBCD[19:16]};
          4: lcd_char <= {4'b0011, LeftEncoderBCD[15:12]};
          5: lcd_char <= {4'b0011, LeftEncoderBCD[11:8]};
          6: lcd_char <= {4'b0011, LeftEncoderBCD[7:4]};
          7: lcd_char <= {4'b0011, LeftEncoderBCD[3:0]};
          9: lcd_char <= "D";
          10: lcd_char <= "Y";
          11: lcd_char <= ":";
          12: lcd_char <= pwm_left_dir ? "+" : "-";
          13: lcd_char <= {4'b0011, pwm_left_bcd[11:8]};
          14: lcd_char <= {4'b0011, pwm_left_bcd[7:4]};
          15: lcd_char <= {4'b0011, pwm_left_bcd[3:0]};

          16: lcd_char <= "R";
          17: lcd_char <= ":";
          18: lcd_char <= {4'b0010, right_dir ? 4'b1011 : 4'b1101};
          19: lcd_char <= {4'b0011, RightEncoderBCD[19:16]};
          20: lcd_char <= {4'b0011, RightEncoderBCD[15:12]};
          21: lcd_char <= {4'b0011, RightEncoderBCD[11:8]};
          22: lcd_char <= {4'b0011, RightEncoderBCD[7:4]};
          23: lcd_char <= {4'b0011, RightEncoderBCD[3:0]};
          25: lcd_char <= "D";
          26: lcd_char <= "Y";
          27: lcd_char <= ":";
          28: lcd_char <= pwm_left_dir ? "+" : "-";
          29: lcd_char <= {4'b0011, pwm_right_bcd[11:8]};
          30: lcd_char <= {4'b0011, pwm_right_bcd[7:4]};
          31: lcd_char <= {4'b0011, pwm_right_bcd[3:0]};
          default: lcd_char <= " ";  // Space
        endcase
      end  // Page 1
      2: begin
        case (lcd_rqst)
          0: lcd_char <= "G";
          1: lcd_char <= "y";
          2: lcd_char <= "r";
          3: lcd_char <= "o";
          4: lcd_char <= ":";
          16: lcd_char <= GyroReadingLCD[63:56];
          17: lcd_char <= GyroReadingLCD[55:48];
          18: lcd_char <= GyroReadingLCD[47:40];
          19: lcd_char <= GyroReadingLCD[39:32];
          20: lcd_char <= GyroReadingLCD[31:24];
          21: lcd_char <= GyroReadingLCD[23:16];
          22: lcd_char <= GyroReadingLCD[15:8];
          23: lcd_char <= GyroReadingLCD[7:0];
          default: lcd_char <= " ";  // Space
        endcase
      end  // Page 2
      3: begin
        // 0: NO
        // 1: BR
        // 2: FO
        // 3: BW
        // 4: PL
        // 5: PR
        // 6: SL
        // 7: SR
        case (lcd_rqst)
          0: lcd_char <= "D";
          1: lcd_char <= "e";
          2: lcd_char <= "m";
          3: lcd_char <= "o";
          5: lcd_char <= "S";
          6: lcd_char <= "t";
          7: lcd_char <= "a";
          8: lcd_char <= "t";
          9: lcd_char <= "e";
          10: lcd_char <= ":";
          16: begin
            case (demo_state)
              0: lcd_char <= "N";
              1, 3: lcd_char <= "B";
              2: lcd_char <= "F";
              4, 5: lcd_char <= "P";
              6, 7: lcd_char <= "S";
              default: lcd_char <= "?";
            endcase
          end
          17: begin
            case (demo_state)
              0, 2: lcd_char <= "O";
              1, 5, 7: lcd_char <= "R";
              3: lcd_char <= "W";
              4, 6: lcd_char <= "L";
              default: lcd_char <= "?";
            endcase
          end
          default: lcd_char <= " ";
        endcase
      end  // Page 3

      default: lcd_char <= 8'b00100000;  // Page error

    endcase
  end
endmodule
