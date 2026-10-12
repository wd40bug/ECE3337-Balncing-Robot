`timescale 1ns / 1ps

module Encoder_tb;

    reg clk;
    reg rst;
    reg SignalFeedback1;
    reg SignalFeedback2;

    wire [1:0] dir;
    wire [15:0] ticksper;

    Encoder dut (
        .clk(clk),
        .rst(rst),
        .SignalFeedback1(SignalFeedback1),
        .SignalFeedback2(SignalFeedback2),
        .dir(dir),
        .ticksper(ticksper)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        SignalFeedback1 = 0;
        SignalFeedback2 = 0;

        #20;
        rst = 0;
        #20;

        SignalFeedback1 = 1;
        #15;
        SignalFeedback2 = 1;
        #15;
        SignalFeedback1 = 0;
        #15;
        SignalFeedback2 = 0;
        #30;

        SignalFeedback2 = 1;
        #15;
        SignalFeedback1 = 1;
        #15;
        SignalFeedback2 = 0;
        #15;
        SignalFeedback1 = 0;
        #50;

        $finish;
    end

endmodule