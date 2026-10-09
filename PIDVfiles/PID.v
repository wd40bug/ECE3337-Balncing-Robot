`timescale 1ns / 1ps

module PID #(
    parameter DATALENGTH = 64,
    parameter SHIFT      = 4,
    parameter Kp         = 2,
    parameter Ki         = 0,
    parameter Kd         = 0
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [DATALENGTH-1:0] setPos,
    input  wire signed [DATALENGTH-1:0] processvar,
    input  wire                  sample_tick,
    output wire signed [DATALENGTH-1:0] correction
);

    // Explicit 16-bit signed limits
    localparam signed [DATALENGTH-1:0] MAX_VAL = 16'sd32767;
    localparam signed [DATALENGTH-1:0] MIN_VAL = -16'sd32768;

    reg signed [DATALENGTH-1:0]   preverr;
    reg signed [2*DATALENGTH-1:0] integral;

    // Combinational calculations
    wire signed [DATALENGTH-1:0] err_comb;
    wire signed [DATALENGTH-1:0] derivative_comb;
    
    assign err_comb        = setPos - processvar;
    assign derivative_comb = err_comb - preverr;

    // Intermediate terms sign-extended to 32 bits
    wire signed [2*DATALENGTH-1:0] propterm;
    wire signed [2*DATALENGTH-1:0] integralterm;
    wire signed [2*DATALENGTH-1:0] derivativeterm;
    wire signed [2*DATALENGTH-1:0] full_sum;

    assign propterm       = ($signed(Kp) * $signed(err_comb)) >>> SHIFT;
    // Scaled full 32-bit integral accumulator
    assign integralterm   = ($signed(Ki) * integral) >>> SHIFT;
    assign derivativeterm = ($signed(Kd) * $signed(derivative_comb)) >>> SHIFT;

    assign full_sum       = propterm + integralterm + derivativeterm;

    // Output Saturation (Clamping) to prevent bit-wrap overflow
    assign correction = (full_sum > $signed({{16{MAX_VAL[15]}}, MAX_VAL})) ? MAX_VAL :
                        (full_sum < $signed({{16{MIN_VAL[15]}}, MIN_VAL})) ? MIN_VAL :
                        full_sum[DATALENGTH-1:0];

    // Sequential Tracking with Anti-Windup Limits
    localparam signed [2*DATALENGTH-1:0] INT_MAX = 32'sd500000;
    localparam signed [2*DATALENGTH-1:0] INT_MIN = -32'sd500000;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            preverr  <= 0;
            integral <= 0;
        end else if (sample_tick) begin
            preverr <= err_comb;

            // Simple Integral accumulation with clamping anti-windup
            if ((integral + err_comb) <= INT_MAX && (integral + err_comb) >= INT_MIN) begin
                integral <= integral + err_comb;
            end
        end
    end

endmodule