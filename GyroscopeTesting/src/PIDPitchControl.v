module PIDPitchControl #(
    parameter [5:0] CENTER = 0
) (
    input clk,
    input data_in,
    input signed [7:0] pitch,
    output signed [15:0] speed
);
  PID #(
    .IN_WIDTH(8),
    .OUT_WIDTH(16),
    .SHIFT(4),
    .Kp(82),
    .Ki(0),
    .Kd(15)
  ) pid_pitch (
    .clk(clk),
    .rst(1'b1),
    .setPos(CENTER),
    .processvar(pitch),
    .sample_tick(data_in),
    .correction(speed)
  ); 

endmodule
