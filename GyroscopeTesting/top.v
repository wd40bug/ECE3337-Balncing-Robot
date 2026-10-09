`include "inc/constants.vh"

module top (
    input clk,
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

  reg pitch_sign = 1;
  reg [6:0] pitch_value = 7'd64;

  reg yaw_sign = 1;
  reg [6:0] yaw_value = 7'd75;

  reg [31:0] gyro_reading_lcd = 32'hDEAF0123;

  wire encoder_reading_left_dir;
  wire [15:0] encoder_reading_left;
  wire encoder_reading_right_dir;
  wire [15:0] encoder_reading_right;

  wire data_out_left;
  wire data_out_right;

  Encoder encoder_inst_left (
      .clk(clk),
      .rst(1'b0),
      .SignalFeedback1(enc_left_1),
      .SignalFeedback2(enc_left_2),
      .dir(encoder_reading_left_dir),
      .ticks(encoder_reading_left),
      .data_out(data_out_left)
  );

  Encoder encoder_inst_right (
      .clk(clk),
      .rst(1'b0),
      // Reversed for right
      .SignalFeedback1(enc_right_2),
      .SignalFeedback2(enc_right_1),
      .dir(encoder_reading_right_dir),
      .ticks(encoder_reading_right),
      .data_out(data_out_right)
  );

  wire [7:0] lcd_driver_out;
  wire [4:0] lcd_rqst;
  // wire [2:0] demo_state;

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
      .LeftEncoderReading(encoder_reading_left),
      .left_dir(encoder_reading_left_dir),
      .RightEncoderReading(encoder_reading_right),
      .right_dir(encoder_reading_right_dir),
      .pwm_left(left_duty),
      .pwm_left_dir(pwm_left_dir),
      .pwm_right(right_duty),
      .pwm_right_dir(pwm_right_dir),
      .demo_state(2'd0),
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

  reg [7:0] left_duty;
  reg [7:0] right_duty;
  reg [2:0] left_state;
  reg [2:0] right_state;
  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .duty1(left_duty),
      .duty2(right_duty),
      .state1({2'b0, ~pwm_left_dir}),
      .state2({2'b0, ~pwm_right_dir}),
      .left1(in1),
      .left2(in2),
      .right1(in4),
      .right2(in3),
      .leftpwm(ena),
      .rightpwm(enb)
  );

  wire signed [8:0] pwm_left_signed;
  wire pwm_left_dir; 
  wire signed [8:0] pwm_right_signed;
  wire pwm_right_dir;

  PIDMotorControl pid_motor_control_inst(
      .clk(clk),
      .data_in_left(data_out_left),
      .data_in_right(data_out_right),
      .read_speed_left(encoder_reading_left),
      .read_speed_right(encoder_reading_right),
      .speed_left(16'd20),
      .speed_right(16'd20),
      .PWM_left(pwm_left_signed),
      .PWM_right(pwm_right_signed)
  );

  signed_conversion #(.BITS(8)) signed_conversion_left_pwm(
      .in(pwm_left_signed),
      .out(left_duty),
      .sign(pwm_left_dir)
  );

  signed_conversion #(.BITS(8)) signed_conversion_right_pwm(
      .in(pwm_right_signed),
      .out(right_duty),
      .sign(pwm_right_dir)
  );

  //   demo_driver demo_driver_inst (
  //       .clk(clk),
  //       .up(up),
  //       .down(down),
  //       .left(left),
  //       .right(right),
  //       .left_state(left_state),
  //       .left_pwm(left_duty),
  //       .right_state(right_state),
  //       .right_pwm(right_duty),
  //       .demo_state(demo_state)
  //   );
endmodule
