module binary_to_bcd_tb;
  reg [7:0] num;
  wire [11:0] bcd;

  binary_to_bcd uut(.binary_in(num), .bcd_out(bcd));

  initial begin
    $dumpvars(0, binary_to_bcd_tb);
    num = 254;
    #5;
    num = 94;
    #5;
    num = 0;
    #5;
    num = 27;
    #5;
    num = 255;
    #5;
    $finish;
  end
endmodule
