module demo_driver (
    input clk,
    up,
    down,
    left,
    right,
    output reg [2:0] left_state,
    output reg [7:0] left_pwm,
    output reg [2:0] right_state,
    output reg [7:0] right_pwm
);

    parameter reg [7:0] MAX = 32;

    always @(posedge clk) begin
        if ((up && down) || (!up && !down && left == right)) begin 
            // Brake
            left_state <= 2;
            right_state <= 2;
            left_pwm <= 0;
            right_pwm <= 0;
        end else if (up && !down && !left && !right) begin
            // Forward
            left_state <= 0;
            left_pwm <= 0.5 * MAX;
            right_state <= 0;
            right_pwm <= 0.5 * MAX;
        end else if (!up && down && !left && !right) begin
            // Backward
            left_state <= 1;
            left_pwm <= 0.5 * MAX;
            right_state <= 1;
            right_pwm <= 0.5 * MAX;
        end else if (!up && !down && left && !right) begin
            // Pivot left
            left_state <= 1;
            left_pwm <= 0.5 * MAX;
            right_state <= 0;
            right_pwm <= 0.5 * MAX;
        end else if (!up && !down && !left && right) begin
            // Pivot right
            left_state <= 0;
            left_pwm <= 0.5 * MAX;
            right_state <= 1;
            right_pwm <= 0.5 * MAX;
        end else if ((up || down) && left && !right) begin
            // Slide left
            left_pwm <= 0.25 * MAX;
            right_pwm <= 0.75 * MAX;
            left_state <= up ? 1 : 0;
            right_state <= up ? 1 : 0;
        end else if ((up || down) && left && !right) begin
            // Slide right
            left_pwm <= 0.75 * MAX;
            right_pwm <= 0.25 * MAX;
            left_state <= up ? 1 : 0;
            right_state <= up ? 1 : 0;
        end
    end

endmodule
