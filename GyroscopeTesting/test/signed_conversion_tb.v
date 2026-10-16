module signed_conversion_tb;
  reg signed [7:0] num;
  wire [7:0] mag;
  wire sign;

  signed_conversion uut (
    .in(num),
    .out(mag),
    .sign(sign)
  );

  initial begin
    $dumpvars(0, signed_conversion_tb);
    num = -128;
    #5;
    num = 127;
    #5;
    num = -5;
    #5;
    $finish;
  end
endmodule
