module quaternion_offset (
    input clk,
    input signed [15:0] qw_in,
    input signed [15:0] qx_in,
    input signed [15:0] qy_in,
    input signed [15:0] qz_in,
    input calc_ready,

    output signed [15:0] qw_out,
    output signed [15:0] qx_out,
    output signed [15:0] qy_out,
    output signed [15:0] qz_out,
    output ready
);

reg ready_reg = 1'd0;
assign ready = ready_reg;

// 1.5 degree offset (half angle is +0.75 degrees)
localparam signed [31:0] W_OFF = 16'sh3FFF;
localparam signed [31:0] Y_OFF = 16'sh00D6;

// combinational multiplication
wire signed [31:0] p1 = qw_in * W_OFF;
wire signed [31:0] p2 = qy_in * Y_OFF;
wire signed [31:0] p3 = qx_in * W_OFF;
wire signed [31:0] p4 = qz_in * Y_OFF;
wire signed [31:0] p5 = qw_in * Y_OFF;
wire signed [31:0] p6 = qy_in * W_OFF;
wire signed [31:0] p7 = qx_in * Y_OFF;
wire signed [31:0] p8 = qz_in * W_OFF;

assign qw_out = (p1 - p2) >>> 14;
assign qx_out = (p3 - p4) >>> 14;
assign qy_out = (p5 + p6) >>> 14;
assign qz_out = (p7 + p8) >>> 14;

assign ready = calc_ready;

endmodule