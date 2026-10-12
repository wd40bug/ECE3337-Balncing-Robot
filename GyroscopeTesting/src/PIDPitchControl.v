module PIDPitchControl #(
    parameter [5:0] CENTER = 0
) (
    input clk,
    input data_in,
    // Negative is 1
    input pitch_sign,
    input [6:0] pitch_magnitude,
    output signed [15:0] speed
);
  wire signed [7:0] pitch;

  assign pitch = pitch_sign ? -{1'b0, pitch_magnitude} : {1'b0, pitch_magnitude};

  PID #(
    .IN_WIDTH(8),
    .OUT_WIDTH(16),
    .SHIFT(4),
    .Kp(120),
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
