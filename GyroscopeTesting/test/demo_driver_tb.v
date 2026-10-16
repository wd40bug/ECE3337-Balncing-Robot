module demo_driver_tb;
  reg clk = 0;
  reg up, down, left, right;
  wire [2:0] demo_state;

  demo_driver uut (
      .clk(clk),
      .up(up),
      .down(down),
      .left(left),
      .right(right),
      .demo_state(demo_state)
  );

  initial begin
    forever begin
      #5; clk = ~clk;
    end
  end

  integer i;
  initial begin
    $dumpvars(0, demo_driver_tb);
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge clk);
      {up, down, left, right} = i[3:0];
    end
    $finish;
  end
endmodule
