module PID #(
    parameter IN_WIDTH  = 16,  // Width of setPos and processvar
    parameter OUT_WIDTH = 8,   // Width of the correction output
    parameter SHIFT     = 4,
    parameter Kp        = 8,
    parameter Ki        = 1,
    parameter Kd        = 2
) (
    input  wire                        clk,
    input  wire                        rst,
    input  wire signed [ IN_WIDTH-1:0] setPos,
    input  wire signed [ IN_WIDTH-1:0] processvar,
    input  wire                        sample_tick,
    output wire signed [OUT_WIDTH-1:0] correction
);

  // Dynamic output limits based on OUT_WIDTH (e.g., 8-bit -> Max: 127, Min: -128)
  localparam signed [2*IN_WIDTH-1:0] OUT_MAX = (1 << (OUT_WIDTH - 1)) - 1;
  localparam signed [2*IN_WIDTH-1:0] OUT_MIN = -(1 << (OUT_WIDTH - 1));

  reg signed  [  IN_WIDTH-1:0] preverr;
  reg signed  [2*IN_WIDTH-1:0] integral;

  // Combinational calculations stay at IN_WIDTH precision
  wire signed [  IN_WIDTH-1:0] err_comb;
  wire signed [  IN_WIDTH-1:0] derivative_comb;

  assign err_comb        = setPos - processvar;
  assign derivative_comb = err_comb - preverr;

  // Intermediate terms use 2*IN_WIDTH to prevent overflow during multiplication
  wire signed [2*IN_WIDTH-1:0] propterm;
  wire signed [2*IN_WIDTH-1:0] integralterm;
  wire signed [2*IN_WIDTH-1:0] derivativeterm;
  wire signed [2*IN_WIDTH-1:0] full_sum;

  assign propterm = ($signed(Kp) * $signed(err_comb)) >>> SHIFT;
  assign integralterm = ($signed(Ki) * integral) >>> SHIFT;
  assign derivativeterm = ($signed(Kd) * $signed(derivative_comb)) >>> SHIFT;

  assign full_sum = propterm + integralterm + derivativeterm;

  // Clamp full_sum to the OUT_WIDTH limits before truncating the bits
  assign correction = (full_sum > OUT_MAX) ? OUT_MAX[OUT_WIDTH-1:0] :
                        (full_sum < OUT_MIN) ? OUT_MIN[OUT_WIDTH-1:0] :
                        full_sum[OUT_WIDTH-1:0];

  // Anti-Windup Limits for the integral (Adjust these to fit your system!)
  localparam signed [2*IN_WIDTH-1:0] INT_MAX = 32'sd50000;
  localparam signed [2*IN_WIDTH-1:0] INT_MIN = -32'sd50000;

  always @(posedge clk or negedge rst) begin
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

endmodule

