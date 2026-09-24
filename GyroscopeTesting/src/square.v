module square #(
  parameter integer ON_COUNT = 1,
  parameter integer OFF_COUNT = 1
) (
  input clk,
  output reg out = 1
);

localparam integer PERIOD = ON_COUNT + OFF_COUNT;
localparam integer PERIOD_WIDTH = $clog2(PERIOD);

reg [PERIOD_WIDTH - 1:0] counter = 0;

always @(posedge clk) begin
  counter <= counter + 1;
  if (counter == ON_COUNT) begin
    out <= 0;
  end else if (counter == PERIOD) begin
    out <= 1;
    counter <= 0;
  end
end

endmodule
