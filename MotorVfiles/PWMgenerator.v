`timescale 1ns / 1ps

module PWMgenerator(
input wire clk,
input wire rst,
input wire [7:0] duty,
output reg pwm_out
);

reg [7:0] counter;

always @(posedge clk) begin
    if (rst == 1) begin
        counter <= 0;
        pwm_out <= 0;
    end
    else begin 
        counter <= counter + 1;
        if (counter < duty) begin
            pwm_out <= 1;
        end
        else begin
            pwm_out <= 0;
        end
    end
end

endmodule
