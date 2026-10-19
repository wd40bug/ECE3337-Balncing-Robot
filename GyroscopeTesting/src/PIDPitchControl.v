module PIDPitchControl #(
    parameter [5:0] CENTER = 0
) (
    input clk,
    input data_in,
    input signed [7:0] pitch,
    output signed [7:0] speed
);
  PID #(
    .IN_WIDTH(8),
    .OUT_WIDTH(8),
    .SHIFT(4),
    .Kp(800),
    .Ki(0),
    .Kd(0)
  ) pid_pitch (
    .clk(clk),
    .rst(1'b1),
    .setPos(CENTER),
    .processvar(pitch),
    .sample_tick(data_in),
    .correction(speed)
  ); 

endmodule
