module binary_to_bcd #(
    parameter N_BITS = 8,
    parameter DIGITS = 3
)(
    input  wire [N_BITS-1:0]           binary_in,
    output reg  [(DIGITS*4)-1:0]       bcd_out
);

    integer i, j;
    always @(*) begin
        // Initialize entire BCD structure to zero
        for (i = 0; i < DIGITS; i = i + 1) begin
            bcd_out[i*4 +: 4] = 4'd0;
        end
        
        // Load MSB first and shift through all bits
        for (i = N_BITS - 1; i >= 0; i = i - 1) begin
            // Check and add 3 to each 4-bit nibble if >= 5
            for (j = 0; j < DIGITS; j = j + 1) begin
                if (bcd_out[j*4 +: 4] >= 5) begin
                    bcd_out[j*4 +: 4] = bcd_out[j*4 +: 4] + 4'd3;
                end
            end
            
            // Shift left entire structure including incoming binary bit
            bcd_out = {bcd_out[(DIGITS*4)-2:0], binary_in[i]};
        end
    end
endmodule
