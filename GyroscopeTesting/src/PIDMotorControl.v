module PIDMotorControl (
    input clk,
    input data_in_left,
    input data_in_right,
    input signed [15:0] read_speed_left,
    input signed [15:0] read_speed_right,
    input signed [15:0] speed_left,
    input signed [15:0] speed_right,
    input [11:0] P,
    input [11:0] I,
    input [11:0] D,
    input [11:0] shift,
    output signed [7:0] PWM_left,
    output signed [7:0] PWM_right
);

  PID #(
      .IN_WIDTH(16),
      .OUT_WIDTH(8),
      .SHIFT(4),
  ) pid_left (
      .clk(clk),
      .rst(1'b1),
      .setPos(speed_left),
      .processvar(read_speed_left),
      .sample_tick(data_in_left),
        .P(P),
        .I(I),
        .D(D),
        .shift(shift),
      .correction(PWM_left)
  );

  PID #(
      .IN_WIDTH(16),
      .OUT_WIDTH(8),
      .SHIFT(4),
  ) pid_right (
      .clk(clk),
      .rst(1'b1),
      .setPos(speed_right),
      .processvar(read_speed_right),
      .sample_tick(data_in_right),
        .P(P),
        .I(I),
        .D(D),
        .shift(shift),
      .correction(PWM_right)
  );

endmodule
