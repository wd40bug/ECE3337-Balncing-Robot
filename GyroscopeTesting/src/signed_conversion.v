module signed_conversion #(
  parameter integer BITS = 8
) (
  input signed [BITS:0] in,
  output [BITS-1:0] out,
  output sign
);

  assign sign = ~in[BITS];
  assign out = sign ? in[BITS-1:0] : -in[BITS-1:0];
  
endmodule
