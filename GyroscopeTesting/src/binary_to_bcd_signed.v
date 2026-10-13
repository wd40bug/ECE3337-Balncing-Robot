module binary_to_bcd_signed #(
    parameter integer N_BITS,
    parameter integer DIGITS
) (
    input signed [N_BITS-1:0] binary_in,
    output sign,
    output [DIGITS * 4 - 1:0] bcd_out
);

  wire [N_BITS-1:0] in_mag;

  signed_conversion#(
      .BITS(N_BITS)
  ) (
      .in(binary_in), .out(in_mag), .sign(sign)
  );

  binary_to_bcd #(
      .N_BITS(N_BITS),
      .DIGITS(DIGITS)
  ) binary_to_bcd_inst (
      .binary_in(binary_int),
      .bcd_out  (bcd_out)
  );

endmodule
