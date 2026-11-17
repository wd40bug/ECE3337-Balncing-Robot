module fractional_to_bcd #(
  parameter integer FRAC_BITS = 4,
  parameter integer FRAC_DIGITS = 4
)(
  input [FRAC_BITS-1:0] bits,
  output reg [FRAC_DIGITS * 4 - 1:0] bcd
);
  localparam DEPTH = 1 << FRAC_BITS;
  localparam SCALE = 10 ** FRAC_DIGITS;

  reg [DEPTH - 1:0] lut;

  integer i;
  initial begin
    for (i = 0; i < DEPTH; i++) begin
      lut[i] = (i * SCALE) >> FRAC_BITS;
    end
  end

  always @(*) begin
    bcd = lut[bits];
  end

endmodule
