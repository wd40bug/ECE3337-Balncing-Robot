module Motors (
    input clk,
    input left_encoder_1,
    input left_encoder_2,
    input right_encoder_1,
    input right_encoder_2,
    input [11:0] P,
    input [11:0] I,
    input [11:0] D,
    input [11:0] shift,
    input enabled,
    output left_enable,
    output left_in1,
    output left_in2,
    output right_enable,
    output right_in1,
    output right_in2,
    input signed [7:0] duty,
    // Debugging
    output signed [15:0] left_speed,
    output signed [15:0] right_speed,
    output signed [7:0] left_duty,
    output signed [7:0] right_duty
);

  reg left_duty;
  reg right_duty;

  always @(*) begin
    if (!enabled) begin
      left_duty  <= 0;
      right_duty <= 0;
    end else if (duty == -8'd128) begin
      left_duty  <= 127;
      right_duty <= 127;
    end else if (duty > -20 && duty < 0) begin
        left_duty <= 20;
        right_duty <= 20;
    end else if (duty < 20 && duty > 0) begin
        left_duty <= -20;
        right_duty <= -20;
    end else begin
        left_duty <= -duty;
        right_duty <= -duty;
    end
  end

  Encoder encoder_inst_left (
      .clk(clk),
      .rst(1'b0),
      .SignalFeedback1(left_encoder_1),
      .SignalFeedback2(left_encoder_2),
      .ticks(left_speed),
      .data_out(data_in_left)
  );

  Encoder encoder_inst_right (
      .clk(clk),
      .rst(1'b0),
      // Reversed for right
      .SignalFeedback2(right_encoder_1),
      .SignalFeedback1(right_encoder_2),
      .ticks(right_speed),
      .data_out(data_in_right)
  );

  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .left_duty(left_duty),  // WAS: left_duty_in 10/28/2026
      .right_duty(right_duty),  // WAS: right_duty_in 10/28/2026
      .left1(left_in1),
      .left2(left_in2),
      .right1(right_in1),
      .right2(right_in2),
      .leftpwm(left_enable),
      .rightpwm(right_enable)
  );

endmodule
