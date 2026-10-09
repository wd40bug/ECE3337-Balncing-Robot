`timescale 1ns / 1ps

module mock_plant #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  sample_tick,
    input  wire signed [WIDTH-1:0] control_out,
    output wire signed [WIDTH-1:0] feedback
);
    
    reg signed [WIDTH-1:0] y_prev1, y_prev2;
    reg signed [WIDTH-1:0] u_prev;

    wire signed [31:0] y_next;
    
    // Discrete transfer function calculation
    assign y_next = (($signed(32'd448) * y_prev1) - ($signed(32'd200) * y_prev2) + ($signed(32'd64) * u_prev)) >>> 8;
    assign feedback = y_prev1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_prev1 <= 0;
            y_prev2 <= 0;
            u_prev  <= 0;
        end else if (sample_tick) begin
            u_prev  <= control_out;
            y_prev2 <= y_prev1;
            y_prev1 <= y_next[15:0];
        end
    end

endmodule