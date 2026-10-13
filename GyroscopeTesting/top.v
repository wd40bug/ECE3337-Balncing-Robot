module top (
    input clk,
    input gyro_rx_pin,
    input page_back,
    page_forward,
    up,
    down,
    left,
    right,
    enc_left_1,
    enc_left_2,
    enc_right_1,
    enc_right_2,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output gyro_tx_pin,
    output shift_ser,
    output shift_srclk,
    output shift_rclk,
    output wire ena,
    enb,
    in1,
    in2,
    in3,
    in4
);

  assign led = {enc_left_1, enc_left_2, enc_right_1, enc_right_2, 0, 0};

  // --- Sensor Readings ---
  // Angles
  wire signed [7:0] pitch;
  reg signed [7:0] yaw = -7'd75;
  // Speeds
  wire signed [15:0] left_encoder;
  wire signed [15:0] right_encoder;

  // --- System Variables ---
  // --- Other ---
  // Debugging
  wire [31:0] raw_gyro;
  
  PIDPitchControl pitch_control (
      .clk(clk),
      .data_in(pitch_data_in),
      .pitch_sign(pitch_sign),
      .pitch_magnitude(pitch_value),
      .speed(set_speed)
  );

  lcd_driver #(
      .DEFAULT_PAGE(4)
  ) lcd_driver_inst (
      .clk(clk),
      .page_backward(page_back),
      .page_forward(page_forward),
      .lcd_rqst(lcd_rqst),
      .pitch_sign(pitch_sign),
      .pitch_value(pitch_value),
      .yaw_sign(yaw_sign),
      .yaw_value(yaw_value),
      .RawGyroReading(gyro_reading_lcd),
      .LeftEncoderReading(encoder_reading_left),
      .left_dir(encoder_reading_left_dir),
      .RightEncoderReading(encoder_reading_right),
      .right_dir(encoder_reading_right_dir),
      .pwm_left(left_duty),
      .pwm_left_dir(pwm_left_dir),
      .pwm_right(right_duty),
      .pwm_right_dir(pwm_right_dir),
      .demo_state(2'd0),
      .set_speed(set_speed),
      .lcd_char(lcd_driver_out)
  );

  lcd lcd_inst (
      .clk(clk),
      .char(lcd_driver_out),
      .lcd_rqst(lcd_rqst),
      .rs(lcd_rs),
      .rw(lcd_rw),
      .e(lcd_e),
      .sr_data(shift_ser),
      .sr_clk(shift_srclk),
      .sr_latch(shift_rclk)
  );

endmodule
