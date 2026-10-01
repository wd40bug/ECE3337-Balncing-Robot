`timescale 1ns / 1ps

module MotorControl(
input clk,
input rst,
input [7:0] duty1,
input [7:0] duty2,
input [2:0] state1, 
input [2:0] state2, 
output out1, 
output out2, 
output out3, 
output out4, 
output pwm1, 
output pwm2);

PWMgenerator pwmgen1(.clk(clk), .rst(rst), .duty(duty1), .pwm_out(pwm1));
PWMgenerator pwmgen2(.clk(clk), .rst(rst), .duty(duty2), .pwm_out(pwm2));

reg out1, out2, out3, out4;
/*
0 - forward
1 - backward
2 - brake
*/
always @(*) begin
    // Motor 1
    if(state1 == 0) begin
        out1 <= 1;
        out2 <= 0;
    end
    else if(state1 == 1) begin
        out1 <= 0;
        out2 <= 1;
    end
    else if(state1 == 2) begin
        out1 <= 0;
        out2 <= 0;
    end
    // Motor 2
    if(state2 == 0) begin
        out3 <= 1;
        out4 <= 0;
    end
    else if(state2 == 1) begin
        out3 <= 0;
        out4 <= 1;
    end
    else if(state2 == 2) begin
        out3 <= 0;
        out4 <= 0;
    end
    
end
    
endmodule
