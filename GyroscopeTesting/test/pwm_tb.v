module pwm_tb;

  reg  clk = 0;
  wire out_50_20, out_25_20, out_50_10, out_90_10;

  pwm #(50, 20) uut0 (
      clk,
      out_50_20
  );

  pwm #(25, 20) uut1 (
    clk,
    out_25_20
  );

  pwm #(50, 10) uut2 (
    clk,
    out_50_10
  );

  pwm #(90, 10) uut3 (
    clk,
    out_90_10
  );

  always #5 clk = ~clk;

  initial begin
    $dumpvars(0, pwm_tb);
    repeat (200) @(posedge clk);
    $finish;
  end
endmodule
