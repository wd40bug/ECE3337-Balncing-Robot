module square_tb;
  reg  clk = 0;
  wire out_10_10, out_5_15, out_9_1;
  square #(10, 10) uut1 (
      clk,
      out_50_50
  );

  square #(5, 15) uut2 (
    clk,
    out_5_15
  );

  square #(9, 1) uut3 (
    clk,
    out_9_1
  );

  initial begin
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    $dumpvars(0, square_tb);
    repeat (200) @(posedge clk);
    $finish;
  end
endmodule
