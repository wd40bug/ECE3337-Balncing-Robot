module pwm #(
  parameter integer DUTY = 50,
  parameter integer PERIOD = 100
)(
  input clk,
  output out
);

  localparam integer ON_COUNT = ( DUTY * PERIOD ) / 100;
  localparam integer OFF_COUNT = PERIOD - ON_COUNT;

  square #(ON_COUNT, OFF_COUNT) square_inst(clk, out);

endmodule
