`timescale 1us / 1ns

module lcd_tb;

  reg clk = 0;
  wire rs, rw, e;
  wire [7:0] db;

  lcd #(
    .CLK_SPEED(100_000)
  ) uut (clk, rs, rw, e, db);

  always #5 clk = ~clk;

  initial begin
    $dumpvars(0, lcd_tb);
    #100_000
    $finish;
  end

endmodule
