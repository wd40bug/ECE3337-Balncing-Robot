module PIDMotorControl (
    input clk,
    input data_in_left,
    input data_in_right,
    input signed [15:0] read_speed_left,
    input signed [15:0] read_speed_right,
    input signed [15:0] speed_left,
    input signed [15:0] speed_right,
    output signed [7:0] PWM_left,
    output signed [7:0] PWM_right
);

  PID #(
      .IN_WIDTH(16),
      .OUT_WIDTH(8),
      .SHIFT(4),
      .Kp(20),
      .Ki(0),
      .Kd(0)
  ) pid_left (
      .clk(clk),
      .rst(1'b1),
      .setPos(speed_left),
      .processvar(read_speed_left),
      .sample_tick(data_in_left),
      .correction(PWM_left)
  );

  PID #(
      .IN_WIDTH(16),
      .OUT_WIDTH(8),
      .SHIFT(4),
      .Kp(20),
      .Ki(0),
      .Kd(0)
  ) pid_right (
      .clk(clk),
      .rst(1'b1),
      .setPos(speed_right),
      .processvar(read_speed_right),
      .sample_tick(data_in_right),
      .correction(PWM_right)
  );

endmodule
