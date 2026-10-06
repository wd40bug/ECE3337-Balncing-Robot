module delay_ms
#(parameter CYCLES_PER_MS = 27000,
  parameter BITS_FOR_NUM = 15
)
(
input clk,
input [9:0] ms_to_delay,
input reset,
output time_elapsed
);

reg [9:0]ms_elapsed;
reg [BITS_FOR_NUM - 1: 0] cycles;
reg time_elapsed_reg;

assign time_elapsed = time_elapsed_reg;

always@(posedge clk) begin
    if(reset == 1'd1) begin
        ms_elapsed <= 10'd0;
        time_elapsed_reg <= 1'd0;
        cycles <= 0;
    end
    else if(ms_to_delay == ms_elapsed) begin
        time_elapsed_reg <= 1'd1;
    end
    else if(cycles == CYCLES_PER_MS) begin
        ms_elapsed <= ms_elapsed + 1;
        cycles <= 0;
    end
    else begin
        cycles <= cycles + 1;
    end
    
end

endmodule