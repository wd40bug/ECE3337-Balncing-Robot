module fixed_point_to_bcd #(
    parameter integer N_BITS = 12,
    parameter integer N_FRAC_BITS = 4,
    parameter integer INT_DIGITS = 3,
    parameter integer FRAC_DIGITS = 4
) (
    input [N_BITS-1:0] binary_in,
    output sign,
    output reg [INT_DIGITS * 4-1:0] int_bcd,
    output reg [FRAC_DIGITS * 4 - 1:0] frac_bcd
);
  localparam FRAC_DEPTH = 1 << N_FRAC_BITS;
  localparam FRAC_SCALE = 10 ** FRAC_DIGITS;

  assign sign = ~binary_in[N_BITS-1];

  wire [N_BITS-1:0] abs = sign ? binary_in : -binary_in;

  localparam integer N_INT_BITS = N_BITS - N_FRAC_BITS;

  binary_to_bcd #(
    .N_BITS(N_INT_BITS),
    .DIGITS(INT_DIGITS)
  ) binary_to_bcd_int (
    .binary_in(abs[N_BITS-1-:N_INT_BITS]),
    .bcd_out(int_bcd)
  );

  wire frac_bin = abs[N_FRAC_BITS-1:0];
  wire [N_FRAC_BITS + 31:0] frac_prod = frac_bin * FRAC_SCALE;
  wire [31:0] frac_shift = frac_prod >> N_FRAC_BITS;

  binary_to_bcd #(
    .N_BITS(32),
    .DIGITS(FRAC_DIGITS)
  ) binary_to_bcd_frac (
    .binary_in(frac_shift),
    .bcd_out(frac_bcd)
  );

endmodule
