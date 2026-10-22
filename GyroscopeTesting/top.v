module top (
    input clk,
    input gyro_rx,
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
    output gyro_tx,
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

  assign led = 6'b101010;

  // --- Sensor Readings ---
  // Angles
  wire signed [7:0] pitch;
  reg signed [7:0] yaw = -7'd75;
  // Speeds
  wire signed [15:0] left_speed;
  wire signed [15:0] right_speed;
  // Data in
  wire pitch_data_in;

  // --- System Variables ---
  // Drive state
  reg [2:0] drive_state = 3'd0;
  // --- Other ---
  // Debugging
  wire [63:0] raw_gyro;
  wire signed [7:0] duty_reversed;
  wire signed [7:0] duty = -duty_reversed;

  Gyro gyro_inst (
      .clk(clk),
      .rx(gyro_rx),
      .tx(gyro_tx),
      .pitch(pitch),
      .data_in(pitch_data_in),
      .raw_gyro(raw_gyro)
  );

  PIDPitchControl pitch_control (
      .clk(clk),
      .data_in(pitch_data_in),
      .pitch(pitch),
      .speed(duty_reversed)
  );

  Motors motors_inst (
      .clk(clk),
      .left_encoder_1(enc_left_1),
      .left_encoder_2(enc_left_2),
      .right_encoder_1(enc_right_1),
      .right_encoder_2(enc_right_2),
      .left_enable(ena),
      .left_in1(in1),
      .left_in2(in2),
      .right_enable(enb),
      .right_in1(in3),
      .right_in2(in4),
      .set_duty(duty),
      // Debugging
      .left_speed(left_speed),
      .right_speed(right_speed)
  );

  LCD #(
      .DEFAULT_PAGE(0)
  ) lcd_inst (
      .clk(clk),
      .forward(page_forward),
      .backward(page_back),
      .pitch(pitch),
      .yaw(yaw),
      .gyro_raw(raw_gyro),
      .left_speed(left_speed),
      .right_speed(right_speed),
      .left_duty(duty),
      .right_duty(duty),
      .drive_state(drive_state),
      .set_speed(16'd0),
      .rs(lcd_rs),
      .rw(lcd_rw),
      .e(lcd_e),
      .sr_data(shift_ser),
      .sr_clk(shift_srclk),
      .sr_latch(shift_rclk)
  );

endmodule
