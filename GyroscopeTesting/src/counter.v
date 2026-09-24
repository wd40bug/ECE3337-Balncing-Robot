module counter #(
  parameter COUNT = 1
) (
    input  clk,
    input  rst,
    output reg timeout
);
  localparam COUNT_WIDTH = $clog2(COUNT);
  reg [COUNT_WIDTH-1:0] counter = 0;

  always @(posedge clk) begin
    if (rst) begin
      counter <= 0;
      timeout <= 0;
    end else if (counter == COUNT) begin
      timeout <= 1;
    end else begin
      counter <= counter + 1;
    end
  end

endmodule
