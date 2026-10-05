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
            left_pwm <= 128;
            right_state <= 0;
            right_pwm <= 128;
        end else if (!up && down && !left && !right) begin
            // Backward
            left_state <= 1;
            left_pwm <= 128;
            right_state <= 1;
            right_pwm <= 128;
        end else if (!up && !down && left && !right) begin
            // Pivot left
            left_state <= 1;
            left_pwm <= 128;
            right_state <= 0;
            right_pwm <= 128;
        end else if (!up && !down && !left && right) begin
            // Pivot right
            left_state <= 0;
            left_pwm <= 128;
            right_state <= 1;
            right_pwm <= 128;
        end else if ((up || down) && left && !right) begin
            // Slide left
            left_pwm <= 64;
            right_pwm <= 192;
            left_state <= up ? 1 : 0;
            right_state <= up ? 0 : 1;
        end else if ((up || down) && left && !right) begin
            // Slide right
            left_pwm <= 192;
            right_pwm <= 64;
            left_state <= up ? 1 : 0;
            right_state <= up ? 0 : 1;
        end
    end

endmodule
