`timescale 1ns / 1ps

module Encoder (
    input wire clk,
    input wire rst,
    input wire SignalFeedback1,
    input wire SignalFeedback2,
    output reg dir,
    output reg [15:0] ticks,
    // One clock pulse when data is read
    output reg data_out
);

  reg [15:0] ticksper = 0;

  localparam integer ncycles = 500_000;

  reg Signal_prev1, Signal_prev2;
  integer cyclecount = 0;

  wire Signal_current1 = SignalFeedback1;
  wire Signal_current2 = SignalFeedback2;

  wire s1_rising = (Signal_current1 == 1'b1) && (Signal_prev1 == 1'b0);
  wire s2_rising = (Signal_current2 == 1'b1) && (Signal_prev2 == 1'b0);
  wire edge_detected = s1_rising || s2_rising;

  always @(posedge clk) begin
    data_out <= 0;
    if (rst) begin
      Signal_prev1 <= 1'b0;
      Signal_prev2 <= 1'b0;
      cyclecount   <= 16'd0;
      ticksper     <= 16'd0;
      dir          <= 1;
    end else begin
      Signal_prev1 <= Signal_current1;
      Signal_prev2 <= Signal_current2;

      if (cyclecount >= ncycles - 1) begin
        cyclecount <= 16'd0;
        ticks <= ticksper + edge_detected;
        ticksper <= edge_detected;
        data_out <= 1;
      end else begin
        cyclecount <= cyclecount + 1'b1;
        if (edge_detected) begin
          ticksper <= ticksper + 1'b1;
        end
      end

      if (s1_rising) begin
        dir <= (Signal_current2 == 1'b0);
      end else if (s2_rising) begin
        dir <= (Signal_current1 == 1'b1);
      end
    end
  end
endmodule
