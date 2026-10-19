module Motors (
    input clk,
    input left_encoder_1,
    input left_encoder_2,
    input right_encoder_1,
    input right_encoder_2,
    output left_enable,
    output left_in1,
    output left_in2,
    output right_enable,
    output right_in1,
    output right_in2,
    input signed [7:0] set_duty,
    // Debugging
    output signed [15:0] left_speed,
    output signed [15:0] right_speed
);

  Encoder encoder_inst_left (
      .clk(clk),
      .rst(1'b0),
      .SignalFeedback1(left_encoder_1),
      .SignalFeedback2(left_encoder_2),
      .ticks(left_speed)
  );

  Encoder encoder_inst_right (
      .clk(clk),
      .rst(1'b0),
      // Reversed for right
      .SignalFeedback2(right_encoder_1),
      .SignalFeedback1(right_encoder_2),
      .ticks(right_speed)
  );

  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .left_duty(set_duty),
      .right_duty(set_duty),
      .left1(left_in1),
      .left2(left_in2),
      .right1(right_in1),
      .right2(right_in2),
      .leftpwm(left_enable),
      .rightpwm(right_enable)
  );

endmodule
