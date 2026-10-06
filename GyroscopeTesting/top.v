`include "inc/constants.vh"

module top (
    input clk,
    page_back,
    page_forward,
    up,
    down,
    left,
    right,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
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

  assign led = ~{up, down, left, right, 0, 0};

  reg pitch_sign = 1;
  reg [6:0] pitch_value = 7'd64;

  reg yaw_sign = 1;
  reg [6:0] yaw_value = 7'd75;

  reg [31:0] gyro_reading_lcd = 32'hDEAF0123;
  reg encoder_reading_left_dir = 1;
  reg [15:0] encoder_reading_lcd_left = 16'd15_925;
  reg encoder_reading_right_dir = 0;
  reg [15:0] encoder_reading_lcd_right = 16'd6_123;

  wire [7:0] lcd_driver_out;
  wire [4:0] lcd_rqst;

  lcd_driver lcd_driver_inst (
    .clk(clk),
    .page_backward(page_back),
    .page_forward(page_forward),
    .lcd_rqst(lcd_rqst),
    .pitch_sign(pitch_sign),
    .pitch_value(pitch_value),
    .yaw_sign(yaw_sign),
    .yaw_value(yaw_value),
    .RawGyroReading(gyro_reading_lcd),
    .LeftEncoderReading(encoder_reading_lcd_left),
    .left_dir(encoder_reading_left_dir),
    .RightEncoderReading(encoder_reading_lcd_right),
    .right_dir(encoder_reading_right_dir),
    .lcd_char(lcd_driver_out)
  );

  lcd lcd_inst (
    .clk(clk),
    .char(lcd_driver_out),
    .lcd_rqst(lcd_rqst),
    .rs (lcd_rs),
    .rw (lcd_rw),
    .e  (lcd_e),
    .sr_data(shift_ser),
    .sr_clk(shift_srclk),
    .sr_latch(shift_rclk)
  );

  reg [7:0] left_duty;
  reg [7:0] right_duty;
  reg [2:0] left_state;
  reg [2:0] right_state;
  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .duty1(left_duty),
      .duty2(right_duty),
      .state1(left_state),
      .state2(right_state),
      .left1(in1),
      .left2(in2),
      .right1(in4),
      .right2(in3),
      .leftpwm(ena),
      .rightpwm(enb)
  );

  demo_driver demo_driver_inst (
      .clk(clk),
      .up(up),
      .down(down),
      .left(left),
      .right(right),
      .left_state(left_state),
      .left_pwm(left_duty),
      .right_state(right_state),
      .right_pwm(right_duty)
  );
endmodule
