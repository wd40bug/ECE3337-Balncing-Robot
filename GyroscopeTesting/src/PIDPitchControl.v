module PIDPitchControl #(
    parameter [5:0] CENTER = 0
) (
    input clk,
    input data_in,
    input signed [7:0] pitch,
    input [11:0] P,
    input [11:0] I,
    input [11:0] D,
    input [11:0] shift,
    output signed [15:0] speed
);
  PID #(
    .IN_WIDTH(8),
    .OUT_WIDTH(16)
  ) pid_pitch (
    .clk(clk),
    .rst(1'b1),
    .setPos(CENTER),
    .processvar(pitch),
    .sample_tick(data_in),
    .P(P),
    .I(I),
    .D(D),
    .shift(shift),
    .correction(speed)
  ); 

endmodule
