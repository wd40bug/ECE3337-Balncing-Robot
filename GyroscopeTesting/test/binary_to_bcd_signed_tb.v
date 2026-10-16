module binary_to_bcd_signed_tb;
  reg signed [7:0] num;
  wire [11:0] bcd;
  wire sign;

  binary_to_bcd_signed uut(.binary_in(num), .sign(sign), .bcd_out(bcd));

  initial begin
    $dumpvars(0, binary_to_bcd_signed_tb);
    num = -128;
    #5;
    num = 127;
    #5;
    num = -5;
    #5;
    $finish;
  end
endmodule
