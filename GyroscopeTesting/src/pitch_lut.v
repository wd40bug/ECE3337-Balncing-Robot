module pitch_lut (
    input wire clk,
    input wire rst_neg,
    input wire in_valid,

    // Raw BNO055 quaternion values, signed Q14
    input wire signed [15:0] qw,
    input wire signed [15:0] qx,
    input wire signed [15:0] qy,
    input wire signed [15:0] qz,

    // 2s complement pitch output (Q8.4 format)
    // Range: -90.0 to +90.0 degrees
    output reg signed [11:0] pitch_out,
    output reg out_valid
);

  // Q28 representation of +1.0
  localparam signed [33:0] ONE_Q28 = 34'sd268435456;

  // Threshold ROM: 1440 entries for 1/16 degree precision
  reg [28:0] threshold_rom [0:1439];
  reg [28:0] rom_data;

  initial begin
    $readmemh("pitch_thresholds.mem", threshold_rom);
  end

  // Synchronous ROM read (Infers Gowin BSRAM automatically)
  reg [10:0] rom_addr;
  always @(posedge clk) begin
    rom_data <= threshold_rom[rom_addr];
  end

  // Signed products: Q14 * Q14 = Q28
  wire signed [31:0] prod_wy = qw * qy;
  wire signed [31:0] prod_zx = qz * qx;

  // State machine states
  localparam [1:0] S_IDLE   = 2'b00,
                   S_SEARCH = 2'b01,
                   S_DONE   = 2'b10;

  reg [1:0] state;
  reg [3:0] iter;
  reg [10:0] lo, hi, mid;
  reg negative_val;
  reg [28:0] magnitude_val;

  // Module-level wire/reg declarations to satisfy Verilog-2005 rules
  reg signed [32:0] diff;
  reg signed [33:0] s_calc;
  reg signed [33:0] s_clamped;
  reg [10:0] next_lo, next_hi;

  always @(posedge clk or negedge rst_neg) begin
    if (!rst_neg) begin
      state         <= S_IDLE;
      pitch_out     <= 12'sd0;
      out_valid     <= 1'b0;
      iter          <= 4'd0;
      lo            <= 11'd0;
      hi            <= 11'd1440;
      mid           <= 11'd0;
      rom_addr      <= 11'd0;
      negative_val  <= 1'b0;
      magnitude_val <= 29'd0;
      diff          <= 33'sd0;
      s_calc        <= 34'sd0;
      s_clamped     <= 34'sd0;
      next_lo       <= 11'd0;
      next_hi       <= 11'd0;
    end else begin
      case (state)
        S_IDLE: begin
          out_valid <= 1'b0;
          if (in_valid) begin
            // s = 2 * (qw*qy - qz*qx)
            diff   = {prod_wy[31], prod_wy} - {prod_zx[31], prod_zx};
            s_calc = {diff[32], diff} <<< 1;

            // Clamp s to [-1, +1]
            if (s_calc > ONE_Q28) s_clamped = ONE_Q28;
            else if (s_calc < -ONE_Q28) s_clamped = -ONE_Q28;
            else s_clamped = s_calc;

            negative_val <= (s_clamped < 0);
            if (s_clamped < 0) magnitude_val <= -s_clamped;
            else magnitude_val <= s_clamped[28:0];

            // Initialize binary search bounds
            lo       <= 11'd0;
            hi       <= 11'd1440;
            iter     <= 4'd0;
            mid      <= 11'd720; // Initial midpoint (0 + 1440) / 2
            rom_addr <= 11'd720;
            state    <= S_SEARCH;
          end
        end

        S_SEARCH: begin
          // Evaluate comparison from previous cycle's synchronous ROM read
          if (lo < hi) begin
            if (mid < 1440 && magnitude_val >= rom_data) begin
              next_lo = mid + 1;
              next_hi = hi;
            end else begin
              next_lo = lo;
              next_hi = mid;
            end
          end else begin
            next_lo = lo;
            next_hi = hi;
          end

          if (iter == 4'd10) begin
            // 11 total iterations completed (0 to 10)
            state <= S_DONE;
          end else begin
            lo       <= next_lo;
            hi       <= next_hi;
            mid      <= (next_lo + next_hi) / 2;
            rom_addr <= (next_lo + next_hi) / 2;
            iter     <= iter + 1;
          end
        end

        S_DONE: begin
          // Format 2's complement Q8.4 output
          if (negative_val) pitch_out <= -lo;
          else pitch_out <= lo;
          
          out_valid <= 1'b1;
          state     <= S_IDLE;
        end
      endcase
    end
  end
endmodule