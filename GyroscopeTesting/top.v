`include "inc/constants.vh"

module top (
    input clk,
    input btn,
    input up,
    down,
    left,
    right,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output [7:0] lcd_db,
    output wire ena,
    enb,
    in1,
    in2,
    in3,
    in4
);

  assign led = ~{up, down, left, right, 0, 0};

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

  reg [7:0] left_duty;
  reg [7:0] right_duty;
  reg [2:0] left_state;
  reg [2:0] right_state;
  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .duty1(left_duty),
      .duty2(right_duty),
      .state1(left_state),
      .state2(right_state),
      .left1(in1),
      .left2(in2),
      .right1(in4),
      .right2(in3),
      .leftpwm(ena),
      .rightpwm(enb)
  );

  demo_driver demo_driver_inst (
      .clk(clk),
      .up(up),
      .down(down),
      .left(left),
      .right(right),
      .left_state(left_state),
      .left_pwm(left_duty),
      .right_state(right_state),
      .right_pwm(right_duty)
  );

  always @(posedge clk) begin
    if (btn) begin
      y_0 <= 4'd3;
      y_1 = 4'd6;
      y_2 = 4'd0;
    end
  end
endmodule
