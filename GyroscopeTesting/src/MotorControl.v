`timescale 1ns / 1ps

module MotorControl(
input clk,
input rst,
input [7:0] duty1,
input [7:0] duty2,
input [2:0] state1, 
input [2:0] state2, 
output left1, 
output left2, 
output right1, 
output right2, 
output leftpwm, 
output rightpwm);

PWMgenerator pwmgen1(.clk(clk), .rst(rst), .duty(duty1), .pwm_out(leftpwm));
PWMgenerator pwmgen2(.clk(clk), .rst(rst), .duty(duty2), .pwm_out(rightpwm));

reg left1, left2, right1, right2;
/*
0 - forward
1 - backward
2 - brake
*/
always @(*) begin
    // Motor 1
    if(state1 == 0) begin
        left1 <= 1;
        left2 <= 0;
    end
    else if(state1 == 1) begin
        left1 <= 0;
        left2 <= 1;
    end
    else if(state1 == 2) begin
        left1 <= 0;
        left2 <= 0;
    end
    // Motor 2
    if(state2 == 0) begin
        right1 <= 1;
        right2 <= 0;
    end
    else if(state2 == 1) begin
        right1 <= 0;
        right2 <= 1;
    end
    else if(state2 == 2) begin
        right1 <= 0;
        right2 <= 0;
    end
    
end
    
endmodule
