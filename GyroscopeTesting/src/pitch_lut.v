module pitch_lut (
    input wire clk,
    input wire rst_neg,
    input wire in_valid,

    // Raw BNO055 quaternion values, signed Q14
    input wire signed [15:0] qw,
    input wire signed [15:0] qx,
    input wire signed [15:0] qy,
    input wire signed [15:0] qz,

    // Sign-magnitude pitch output
    // pitch_sign = 0: positive or zero
    // pitch_sign = 1: negative
    // pitch_magnitude = 0 to 90 degrees
    output reg pitch_sign,
    output reg [6:0] pitch_magnitude,
    output reg out_valid
);

    // Q28 representation of +1.0
    localparam signed [33:0] ONE_Q28 = 34'sd268435456;

    // Threshold ROM: sin((index + 0.5) degrees) * 2^28
    reg [28:0] threshold_rom [0:89];

    initial begin
        $readmemh("pitch_thresholds.mem", threshold_rom);
    end

    // Signed products: Q14 * Q14 = Q28
    wire signed [31:0] prod_wy;
    wire signed [31:0] prod_zx;

    assign prod_wy = qw * qy;
    assign prod_zx = qz * qx;

    // Intermediate arithmetic
    reg signed [32:0] diff;
    reg signed [33:0] s_calc;
    reg signed [33:0] s_clamped;

    reg negative;
    reg [28:0] magnitude;

    // Binary search variables
    integer i;
    integer lo;
    integer hi;
    integer mid;
    integer degree_mag;

    reg [6:0] pitch_mag_comb;
    reg pitch_sign_comb;

    // Combinational quaternion-to-pitch conversion
    always @(*) begin

        // s = 2 * (qw*qy - qz*qx)
        // Sign-extend before subtracting.
        diff = {prod_wy[31], prod_wy}
             - {prod_zx[31], prod_zx};

        // Widened arithmetic before left shift
        s_calc = {diff[32], diff} <<< 1;

        // Clamp s to [-1, +1]
        if (s_calc > ONE_Q28)
            s_clamped = ONE_Q28;
        else if (s_calc < -ONE_Q28)
            s_clamped = -ONE_Q28;
        else
            s_clamped = s_calc;

        // Extract sign and absolute value
        negative = (s_clamped < 0);

        if (negative)
            magnitude = -s_clamped;
        else
            magnitude = s_clamped[28:0];

        // Binary search for number of crossed thresholds
        lo = 0;
        hi = 90;
        mid = 0;

        for (i = 0; i < 7; i = i + 1) begin
            if (lo < hi) begin
                mid = (lo + hi) / 2;

                if (mid < 90 &&
                    magnitude >= threshold_rom[mid])
                    lo = mid + 1;
                else
                    hi = mid;
            end
        end

        degree_mag = lo;

        // Sign-magnitude result
        pitch_sign_comb = negative;
        pitch_mag_comb = degree_mag[6:0];

        // Use positive zero
        if (degree_mag == 0)
            pitch_sign_comb = 1'b0;
    end

    // Register output and valid together
    always @(posedge clk or negedge rst_neg) begin
        if (!rst_neg) begin
            pitch_sign      <= 1'b0;
            pitch_magnitude <= 7'd0;
            out_valid       <= 1'b0;
        end
        else begin
            out_valid <= in_valid;

            if (in_valid) begin
                pitch_sign      <= pitch_sign_comb;
                pitch_magnitude <= pitch_mag_comb;
            end
        end
    end
endmodule