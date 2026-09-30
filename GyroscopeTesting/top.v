`include "inc/constants.vh"

module top (
    input clk,
    input btn,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output [7:0] lcd_db
);
  wire pwm_out;
  pwm #(
      .DUTY  (1),
      .PERIOD(100)
  ) pwm_inst (
      .clk(clk),
      .out(pwm_out)
  );

  assign led = btn ? 6'b111111 : pwm_out ? 6'd0 : 6'b111111;

  reg [3:0] x_0 = 4'd1;
  reg [3:0] x_1 = 4'd8;
  reg [3:0] x_2 = 4'd0;

  reg [3:0] y_0 = 4'd0;
  reg [3:0] y_1 = 4'd9;
  reg [3:0] y_2 = 4'd0;

  reg [3:0] z_0 = 4'd2;
  reg [3:0] z_1 = 4'd7;
  reg [3:0] z_2 = 4'd0;

  lcd lcd_inst (
      .clk(clk),
      .x_0(x_0),
      .x_1(x_1),
      .x_2(x_2),
      .y_0(y_0),
      .y_1(y_1),
      .y_2(y_2),
      .z_0(z_0),
      .z_1(z_1),
      .z_2(z_2),
      .rs (lcd_rs),
      .rw (lcd_rw),
      .e  (lcd_e),
      .db (lcd_db)
  );

  always @(posedge clk) begin
    if (btn) begin
        y_0 <= 4'd3;
        y_1 = 4'd6;
        y_2 = 4'd0;
    end
  end
endmodule
