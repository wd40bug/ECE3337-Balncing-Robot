module lcd_driver #(
    parameter integer DEFAULT_PAGE = 0
) (
    input clk,
    input page_forward,
    input page_backward,
    input [4:0] lcd_rqst,
    input signed [7:0] pitch,
    input signed [7:0] yaw,
    input [63:0] RawGyroReading,
    input signed [15:0] LeftEncoderReading,
    input signed [15:0] RightEncoderReading,
    input signed [7:0] pwm_left,
    input signed [7:0] pwm_right,
    input [2:0] demo_state,
    input signed [15:0] set_speed,
    input [103:0] esp_uart_in,
    output reg [7:0] lcd_char
);

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
    end else if (forward_pulse) begin
      page_num <= page_num + 1;
    end else if (backward_pulse && page_num > 0) begin
      page_num <= page_num - 1;
    end
  end

  wire [2 * 4 - 1:0] pitch_bcd;
  wire pitch_sign;
  wire [2 * 4 - 1:0] yaw_bcd;
  wire yaw_sign;

  binary_to_bcd_signed #(
      .N_BITS(8),
      .DIGITS(2)
  ) binary_to_bcd_inst2 (
      .binary_in(pitch),
      .bcd_out(pitch_bcd),
      .sign(pitch_sign)
  );
  binary_to_bcd_signed #(
      .N_BITS(8),
      .DIGITS(2)
  ) binary_to_bcd_inst3 (
      .binary_in(yaw),
      .bcd_out(yaw_bcd),
      .sign(yaw_sign)
  );

  wire [5 * 4 - 1:0] LeftEncoderBCD;
  wire left_encoder_sign;

  binary_to_bcd_signed #(
      .N_BITS(16),
      .DIGITS(5)
  ) binary_to_bcd_inst (
      .binary_in(LeftEncoderReading),
      .bcd_out(LeftEncoderBCD),
      .sign(left_encoder_sign)
  );

  wire [5 * 4 - 1:0] RightEncoderBCD;
  wire right_encoder_sign;

  binary_to_bcd_signed #(
      .N_BITS(16),
      .DIGITS(5)
  ) binary_to_bcd_inst1 (
      .binary_in(RightEncoderReading),
      .bcd_out(RightEncoderBCD),
      .sign(right_encoder_sign)
  );

  wire [127:0] GyroReadingASCII;
  binary_to_hex #(
      .N(64)
  ) binary_to_hex_inst (
      .data_in (RawGyroReading),
      .char_out(GyroReadingASCII)
  );

  wire [3 * 4 - 1:0] pwm_left_bcd;
  wire pwm_left_sign;
  binary_to_bcd_signed #(
      .N_BITS(8),
      .DIGITS(3)
  ) binary_to_bcd_inst4 (
      .binary_in(pwm_left),
      .bcd_out(pwm_left_bcd),
      .sign(pwm_left_sign)
  );

  wire [3 * 4 - 1:0] pwm_right_bcd;
  wire pwm_right_sign;
  binary_to_bcd_signed #(
      .N_BITS(8),
      .DIGITS(3)
  ) binary_to_bcd_inst5 (
      .binary_in(pwm_right),
      .bcd_out(pwm_right_bcd),
      .sign(pwm_right_sign)
  );

  wire [5 * 4 - 1 : 0] set_speed_bcd;
  wire set_speed_sign;
  binary_to_bcd_signed #(
      .N_BITS(16),
      .DIGITS(5)
  ) binary_to_bcd_inst6 (
      .binary_in(set_speed),
      .bcd_out(set_speed_bcd),
      .sign(set_speed_sign)
  );

  wire [26 * 8 - 1:0] esp_uart_ascii;
  binary_to_hex #(
      .N(104)
  ) binary_to_hex_inst_1 (
      .data_in (esp_uart_in),
      .char_out(esp_uart_ascii)
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
          6: lcd_char <= pitch_sign ? "+" : "-";
          7: lcd_char <= {4'b0011, pitch_bcd[7:4]};
          8: lcd_char <= {4'b0011, pitch_bcd[3:0]};

          16: lcd_char <= "Y";  // Y
          17: lcd_char <= "a";
          18: lcd_char <= "w";
          19: lcd_char <= ":";  // :
          22: lcd_char <= yaw_sign ? "+" : "-";
          23: lcd_char <= {4'b0011, yaw_bcd[7:4]};
          24: lcd_char <= {4'b0011, yaw_bcd[3:0]};
          default: lcd_char <= " ";  // Space
        endcase
      end  // Page 0
      1: begin
        case (lcd_rqst)
          0:  lcd_char <= "L";
          1:  lcd_char <= ":";
          2:  lcd_char <= left_encoder_sign ? "+" : "-";
          3:  lcd_char <= {4'b0011, LeftEncoderBCD[19:16]};
          4:  lcd_char <= {4'b0011, LeftEncoderBCD[15:12]};
          5:  lcd_char <= {4'b0011, LeftEncoderBCD[11:8]};
          6:  lcd_char <= {4'b0011, LeftEncoderBCD[7:4]};
          7:  lcd_char <= {4'b0011, LeftEncoderBCD[3:0]};
          9:  lcd_char <= "D";
          10: lcd_char <= "Y";
          11: lcd_char <= ":";
          12: lcd_char <= pwm_left_sign ? "+" : "-";
          13: lcd_char <= {4'b0011, pwm_left_bcd[11:8]};
          14: lcd_char <= {4'b0011, pwm_left_bcd[7:4]};
          15: lcd_char <= {4'b0011, pwm_left_bcd[3:0]};

          16: lcd_char <= "R";
          17: lcd_char <= ":";
          18: lcd_char <= right_encoder_sign ? "+" : "-";
          19: lcd_char <= {4'b0011, RightEncoderBCD[19:16]};
          20: lcd_char <= {4'b0011, RightEncoderBCD[15:12]};
          21: lcd_char <= {4'b0011, RightEncoderBCD[11:8]};
          22: lcd_char <= {4'b0011, RightEncoderBCD[7:4]};
          23: lcd_char <= {4'b0011, RightEncoderBCD[3:0]};
          25: lcd_char <= "D";
          26: lcd_char <= "Y";
          27: lcd_char <= ":";
          28: lcd_char <= pwm_right_sign ? "+" : "-";
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
          16: lcd_char <= GyroReadingASCII[127:120];
          17: lcd_char <= GyroReadingASCII[119:112];
          18: lcd_char <= GyroReadingASCII[111:104];
          19: lcd_char <= GyroReadingASCII[103:96];
          20: lcd_char <= GyroReadingASCII[95:88];
          21: lcd_char <= GyroReadingASCII[87:80];
          22: lcd_char <= GyroReadingASCII[79:72];
          23: lcd_char <= GyroReadingASCII[71:64];
          24: lcd_char <= GyroReadingASCII[63:56];
          25: lcd_char <= GyroReadingASCII[55:48];
          26: lcd_char <= GyroReadingASCII[47:40];
          27: lcd_char <= GyroReadingASCII[39:32];
          28: lcd_char <= GyroReadingASCII[31:24];
          29: lcd_char <= GyroReadingASCII[23:16];
          30: lcd_char <= GyroReadingASCII[15:8];
          31: lcd_char <= GyroReadingASCII[7:0];
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
      4: begin
        case (lcd_rqst)
          0: lcd_char <= "P";
          1: lcd_char <= "i";
          2: lcd_char <= "t";
          3: lcd_char <= "c";
          4: lcd_char <= "h";
          5: lcd_char <= ":";
          6: lcd_char <= pitch_sign ? "+" : "-";
          7: lcd_char <= {4'b0011, pitch_bcd[7:4]};
          8: lcd_char <= {4'b0011, pitch_bcd[3:0]};

          16: lcd_char <= "S";
          17: lcd_char <= "p";
          18: lcd_char <= "e";
          19: lcd_char <= "e";
          20: lcd_char <= "d";
          21: lcd_char <= ":";
          22: lcd_char <= set_speed_sign ? "+" : "-";
          23: lcd_char <= {4'b0011, set_speed_bcd[19:16]};
          24: lcd_char <= {4'b0011, set_speed_bcd[15:12]};
          25: lcd_char <= {4'b0011, set_speed_bcd[11:8]};
          26: lcd_char <= {4'b0011, set_speed_bcd[7:4]};
          27: lcd_char <= {4'b0011, set_speed_bcd[3:0]};
          default: lcd_char <= " ";
        endcase
      end
      5: begin
        case (lcd_rqst)
          0: lcd_char <= "E";
          1: lcd_char <= "S";
          2: lcd_char <= "P";
          3: lcd_char <= ":";
          4, 5, 6, 7: lcd_char <= " ";
          default: lcd_char <= esp_uart_ascii[(26-lcd_rqst+8)*8-1 : (26-lcd_rqst+8-1)*8];
        endcase
      end

      default: begin
        page_num <= DEFAULT_PAGE;
        case (lcd_rqst)
          0: lcd_char <= "T";
          1: lcd_char <= "O";
          2: lcd_char <= "O";

          4: lcd_char <= "F";
          5: lcd_char <= "A";
          6: lcd_char <= "R";
          7: lcd_char <= "!";
          default: lcd_char <= " ";
        endcase
      end  // Page error

    endcase
  end
endmodule
