`timescale 1ns / 1ps

module Motor_control_tb();
reg clk;
reg rst;
reg [7:0] duty1;
reg [7:0] duty2;
reg [2:0] state1; 
reg [2:0] state2;
wire out1; 
wire out2; 
wire out3; 
wire out4; 
wire pwm1; 
wire pwm2;

MotorControl UUT (.clk(clk), .rst(rst), .duty1(duty1), .duty2(duty2), .state1(state1), .state2(state2), .out1(out1), .out2(out2), .out3(out3), .out4(out4), .pwm1(pwm1), .pwm2(pwm2));



initial begin
    clk <= 0;
    #5;
    rst <= 1;
    #10;
    rst <= 0;
    #5;
    duty1 <= 128;
    #5;
    duty2 <= 128;
    #5;
    
    state1 <= 0;
    #5;
    state2 <= 0;
    #20;
    
    state1 <= 0;
    #5;
    state2 <= 0;
    #20;
    
    state1 <= 1;
    #5;
    state2 <= 1;
    #20;
    
    state1 <= 2;
    #5;
    state2 <= 2;
    #20000;
    
    $finish;
    
end

always begin
    #5;
    clk = ~clk;
end
endmodule
