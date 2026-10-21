`timescale 1ns / 1ps

module MotorControl (
input clk,
input rst,
input signed [7:0] left_duty,
input signed [7:0] right_duty,
output reg left1, 
output reg left2, 
output reg right1, 
output reg right2, 
output leftpwm, 
output rightpwm);

reg [7:0] pwm_duty_left;
reg [7:0] pwm_duty_right;

PWMgenerator pwmgen1(.clk(clk), .rst(rst), .duty(pwm_duty_left), .pwm_out(leftpwm));
PWMgenerator pwmgen2(.clk(clk), .rst(rst), .duty(pwm_duty_right), .pwm_out(rightpwm));

always @(*) begin
    // Left motor
    if(left_duty == 0) begin
        left1 <= 1;
        left2 <= 1;
        pwm_duty_left <= 0;
    end
    else if(left_duty > 0) begin
        left1 <= 1;
        left2 <= 0;
        pwm_duty_left <= left_duty << 1;
    end
    else if(left_duty < 0) begin
        left1 <= 0;
        left2 <= 1;
        //TODO: Fix stupid hack
        pwm_duty_left <= left_duty > -128 ? -left_duty << 1 : 255;
    end

    // Right motor (Reversed)
    if(right_duty == 0) begin
        right1 <= 1;
        right2 <= 1;
        pwm_duty_right <= 0;
    end
    else if(right_duty > 0) begin
        right1 <= 1;
        right2 <= 0;
        pwm_duty_right <= right_duty << 1;
    end
    else if(right_duty < 0) begin
        right1 <= 0;
        right2 <= 1;
        pwm_duty_right <= right_duty > -128 ? -right_duty << 1 : 255;
    end
    
end
    
endmodule
