module PIDMotorControl (
    input clk,
    input data_in_left,
    input data_in_right,
    input [15:0] read_speed_left,
    input [15:0] read_speed_right,
    input [15:0] speed_left,
    input [15:0] speed_right,
    output signed [8:0] PWM_left,
    output signed [8:0] PWM_right
);

  PID #(
      .IN_WIDTH(16),
      .OUT_WIDTH(9),
      .SHIFT(4),
      .Kp(5),
      .Ki(1),
      .Kd(10)
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
      .OUT_WIDTH(9),
      .SHIFT(4),
      .Kp(5),
      .Ki(1),
      .Kd(10)
  ) pid_right (
      .clk(clk),
      .rst(1'b1),
      .setPos(speed_right),
      .processvar(read_speed_right),
      .sample_tick(data_in_right),
      .correction(PWM_right)
  );

endmodule
