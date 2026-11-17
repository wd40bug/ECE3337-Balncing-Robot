module PID #(
    parameter IN_WIDTH  = 16,  // Width of setPos and processvar
    parameter OUT_WIDTH = 8,   // Width of the correction output
    parameter SHIFT     = 4
) (
    input  wire                        clk,
    input  wire                        rst,
    input  wire signed [ IN_WIDTH-1:0] setPos,
    input  wire signed [ IN_WIDTH-1:0] processvar,
    input  wire                        sample_tick,
    input  wire [11:0]                 P,
    input  wire [11:0]                 I,
    input  wire [11:0]                 D,
    input  wire [11:0]                 shift,
    output reg  signed [OUT_WIDTH-1:0] correction
);

  wire signed [12:0] P_signed = {1'b0, P};
  wire signed [12:0] I_signed = {1'b0, I};
  wire signed [12:0] D_signed = {1'b0, D};

  // Dynamic output limits
  localparam signed [2*IN_WIDTH-1:0] OUT_MAX = (1 << (OUT_WIDTH - 1)) - 1;
  localparam signed [2*IN_WIDTH-1:0] OUT_MIN = -(1 << (OUT_WIDTH - 1));

  reg signed [IN_WIDTH:0]     preverr;
  reg signed [2*IN_WIDTH-1:0] integral;

  // Combinational calculations
  wire signed [IN_WIDTH:0]     err_comb;
  wire signed [IN_WIDTH+1:0]   derivative_comb;

  assign err_comb        = setPos - processvar;
  assign derivative_comb = err_comb - preverr;

  wire signed [13+IN_WIDTH+1:0]   propterm;
  wire signed [13+2*IN_WIDTH-1:0] integralterm;
  wire signed [13+IN_WIDTH+1:0]   derivativeterm;

  assign propterm       = P_signed * err_comb;
  assign integralterm   = I_signed * integral;
  assign derivativeterm = D_signed * derivative_comb;

  // Fully combinational sum wire (no local/automatic block variable declarations)
  wire signed [13+2*IN_WIDTH:0] full_sum;
  assign full_sum = (propterm >>> shift) + (integralterm >>> shift) + (derivativeterm >>> shift);

  // Anti-Windup Limits for the integral
  localparam signed [2*IN_WIDTH-1:0] INT_MAX = 32'sd10000;
  localparam signed [2*IN_WIDTH-1:0] INT_MIN = -32'sd10000;

  // State updates on sample_tick (preserved exactly as you had it)
  always @(posedge sample_tick or negedge rst) begin
    if (!rst) begin
      preverr  <= 0;
      integral <= 0;
    end else if (sample_tick) begin
      preverr <= err_comb;

      if ((integral + err_comb) <= INT_MAX && (integral + err_comb) >= INT_MIN) begin
        integral <= integral + err_comb;
      end
    end
  end

  // Synchronous registration of the correction output on the fast system clock.
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      correction <= 0;
    end else begin
      if (full_sum > OUT_MAX)
        correction <= OUT_MAX[OUT_WIDTH-1:0];
      else if (full_sum < OUT_MIN)
        correction <= OUT_MIN[OUT_WIDTH-1:0];
      else
        correction <= full_sum[OUT_WIDTH-1:0];
    end
  end

endmodule