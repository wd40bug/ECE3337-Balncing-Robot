`timescale 1ns / 1ps

module PID_tb;

    parameter WIDTH = 16;

    reg                   clk;
    reg                   rst_n;
    reg  signed [WIDTH-1:0] setpoint;
    wire signed [WIDTH-1:0] feedback;
    wire signed [WIDTH-1:0] control_out;

    reg        sample_tick;
    integer    tick_counter;

    // 100 MHz clock -> 1 us sample_tick period (100 clock cycles)
    localparam TICK_PERIOD = 100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_counter <= 0;
            sample_tick  <= 1'b0;
        end else begin
            if (tick_counter >= TICK_PERIOD - 1) begin
                tick_counter <= 0;
                sample_tick  <= 1'b1;
            end else begin
                tick_counter <= tick_counter + 1;
                sample_tick  <= 1'b0;
            end
        end
    end

    PID #(
        .DATALENGTH(WIDTH),
        .SHIFT(4),
        .Kp(8),
        .Ki(1),
        .Kd(2)
    ) dut_PID (
        .clk(clk),
        .rst(rst_n),
        .sample_tick(sample_tick),
        .setPos(setpoint),
        .processvar(feedback),
        .correction(control_out)
    );

    // --- Instantiate Mock Plant ---
    mock_plant #(
        .WIDTH(WIDTH)
    ) plant (
        .clk(clk),
        .rst_n(rst_n),
        .sample_tick(sample_tick),
        .control_out(control_out),
        .feedback(feedback)
    );

    // --- Clock Generation (100 MHz -> 10ns period) ---
    always #5 clk = ~clk;

    // --- Test Stimulus ---
    initial begin
        clk      = 0;
        rst_n    = 0;
        setpoint = 'sd0;

        // Hold Reset for 100 ns
        #100;
        rst_n = 1;

        // Apply Step Setpoint
        #100;
        setpoint = 'sd900;

        // Run simulation for 2 ms (2000 sample ticks)
        #2000000;
        $finish;
    end

endmodule